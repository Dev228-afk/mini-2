#!/bin/bash
# Weak Scaling Test - Increasing data size with same number of processes

GATEWAY="localhost:50050"
BUILD_DIR="/Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp"
RESULTS_DIR="/Users/spartan/Desktop/CMPE275/mini_2/results"

echo "========================================"
echo "  Weak Scaling Test - Phase 3"
echo "========================================"
echo ""
echo "Testing how the system handles increasing data volume"
echo "with fixed 6 processes (A, B, C, D, E, F)"
echo ""

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Datasets to test (adjust paths as needed)
declare -a datasets=(
    "1000,/Users/spartan/Desktop/CMPE275/mini_2/test_data/data_1k.csv"
    "10000,/Users/spartan/Desktop/CMPE275/mini_2/test_data/data_10k.csv"
    "100000,/Users/spartan/Desktop/CMPE275/mini_2/test_data/data_100k.csv"
    "1000000,/Users/spartan/Desktop/CMPE275/mini_2/test_data/data_1m.csv"
    "10000000,/Users/spartan/Desktop/CMPE275/mini_2/test_data/data_10m.csv"
)

# CSV header
echo "dataset_size,strategy,first_chunk_ms,total_time_ms,total_bytes,rpc_calls,client_memory_mb,distributed_memory_mb" > "$RESULTS_DIR/weak_scaling.csv"

for dataset_info in "${datasets[@]}"; do
    IFS=',' read -r size path <<< "$dataset_info"
    
    # Check if dataset exists
    if [ ! -f "$path" ]; then
        echo "Warning: Dataset not found: $path"
        echo "Skipping test for $size rows"
        continue
    fi
    
    echo ""
    echo "========================================"
    echo "Testing with ~$size rows: $path"
    echo "========================================"
    
    # Test Strategy A: RequestOnce
    echo ""
    echo "Strategy A: RequestOnce"
    cd "$BUILD_DIR"
    
    # Run client in background and monitor memory
    ./mini2_client --gateway "$GATEWAY" --mode request --dataset "$path" > "$RESULTS_DIR/weak_${size}_strategyA.log" 2>&1 &
    client_pid=$!
    
    # Monitor peak memory usage (in KB on macOS)
    peak_mem=0
    while kill -0 $client_pid 2>/dev/null; do
        current_mem=$(ps -o rss= -p $client_pid 2>/dev/null || echo "0")
        if [ "$current_mem" -gt "$peak_mem" ]; then
            peak_mem=$current_mem
        fi
        sleep 0.1
    done
    wait $client_pid
    mem_used=$((peak_mem / 1024))  # Convert KB to MB
    
    # Get total distributed memory from all server nodes
    distributed_mem=$("$BUILD_DIR/get_distributed_memory" 2>/dev/null || echo "0")
    
    # Show log output
    cat "$RESULTS_DIR/weak_${size}_strategyA.log"
    
    # Extract metrics from log - get the last successful test (Test 3: Both Teams)
    # If Test 3 failed, try Test 2, then Test 1
    total_time=$(grep "Latency:" "$RESULTS_DIR/weak_${size}_strategyA.log" | grep -v "FAILED" | tail -1 | awk '{print $(NF-1)}')
    total_bytes=$(grep "Total Bytes:" "$RESULTS_DIR/weak_${size}_strategyA.log" | grep -v "FAILED" | tail -1 | awk '{print $NF}')
    
    echo "$size,RequestOnce,N/A,$total_time,$total_bytes,1,$mem_used,$distributed_mem" >> "$RESULTS_DIR/weak_scaling.csv"
    
    echo "Completed Strategy A: ${total_time}ms, ${total_bytes} bytes, Client: ${mem_used}MB, Distributed: ${distributed_mem}MB"
    
    # Wait a bit between tests
    sleep 2
    
    # Test Strategy B: GetNext
    echo ""
    echo "Strategy B: GetNext"
    
    # Run client in background and monitor memory
    ./mini2_client --gateway "$GATEWAY" --mode strategy-b-getnext --dataset "$path" > "$RESULTS_DIR/weak_${size}_strategyB.log" 2>&1 &
    client_pid=$!
    
    # Monitor peak memory usage (in KB on macOS)
    peak_mem=0
    while kill -0 $client_pid 2>/dev/null; do
        current_mem=$(ps -o rss= -p $client_pid 2>/dev/null || echo "0")
        if [ "$current_mem" -gt "$peak_mem" ]; then
            peak_mem=$current_mem
        fi
        sleep 0.1
    done
    wait $client_pid
    mem_used=$((peak_mem / 1024))  # Convert KB to MB
    
    # Get total distributed memory from all server nodes
    distributed_mem=$("$BUILD_DIR/get_distributed_memory" 2>/dev/null || echo "0")
    
    # Show log output
    cat "$RESULTS_DIR/weak_${size}_strategyB.log"
    
    # Extract metrics from log
    first_chunk=$(grep "Time to first chunk:" "$RESULTS_DIR/weak_${size}_strategyB.log" | awk '{print $5}')
    total_time=$(grep "Total time:" "$RESULTS_DIR/weak_${size}_strategyB.log" | awk '{print $3}')
    total_bytes=$(grep "Total bytes:" "$RESULTS_DIR/weak_${size}_strategyB.log" | awk '{print $3}')
    rpc_calls=$(grep "RPC calls made:" "$RESULTS_DIR/weak_${size}_strategyB.log" | awk '{print $4}')
    
    echo "$size,GetNext,$first_chunk,$total_time,$total_bytes,$rpc_calls,$mem_used,$distributed_mem" >> "$RESULTS_DIR/weak_scaling.csv"
    
    echo "Completed Strategy B: First chunk ${first_chunk}ms, Total ${total_time}ms, ${rpc_calls} RPCs, Client: ${mem_used}MB, Distributed: ${distributed_mem}MB"
    
    sleep 2
done

echo ""
echo "========================================"
echo "  Weak Scaling Test Complete!"
echo "========================================"
echo ""
echo "Results saved to: $RESULTS_DIR/weak_scaling.csv"
echo ""
echo "Summary:"
cat "$RESULTS_DIR/weak_scaling.csv"
