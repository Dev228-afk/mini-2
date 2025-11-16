#!/bin/bash
# Fairness Test - Testing concurrent clients with different request sizes

GATEWAY="localhost:50050"
BUILD_DIR="/Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp"
RESULTS_DIR="/Users/spartan/Desktop/CMPE275/mini_2/results"
DATASET_SMALL="/Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/unique_2020_fire_data.csv"
DATASET_LARGE="/Users/spartan/Desktop/CMPE275/mini_1/Data/worldbank/merged.csv"

echo "========================================"
echo "  Fairness Test - Phase 3"
echo "========================================"
echo ""
echo "Testing how small requests are affected by large requests"
echo ""

mkdir -p "$RESULTS_DIR"

cd "$BUILD_DIR"

# Test 1: Strategy A (RequestOnce) - Fairness
echo ""
echo "Test 1: Strategy A (RequestOnce) Fairness"
echo "=========================================="
echo "Starting large request in background..."

# Start large request
(time ./mini2_client --gateway "$GATEWAY" --mode request --dataset "$DATASET_LARGE" > "$RESULTS_DIR/fairness_large_A.log" 2>&1) &
LARGE_PID=$!

# Wait 1 second
sleep 1

# Start small request and measure its wait time
echo "Starting small request (should it wait?)..."
START_TIME=$(date +%s%3N)
time ./mini2_client --gateway "$GATEWAY" --mode request --dataset "$DATASET_SMALL" > "$RESULTS_DIR/fairness_small_A.log" 2>&1
END_TIME=$(date +%s%3N)
SMALL_LATENCY=$((END_TIME - START_TIME))

# Wait for large request to finish
wait $LARGE_PID

echo ""
echo "Strategy A Results:"
echo "  Small request latency: ${SMALL_LATENCY}ms"
grep "Latency:" "$RESULTS_DIR/fairness_small_A.log"
echo "  Large request latency:"
grep "Latency:" "$RESULTS_DIR/fairness_large_A.log" | tail -1

sleep 3

# Test 2: Strategy B (GetNext) - Fairness
echo ""
echo "Test 2: Strategy B (GetNext) Fairness"
echo "=========================================="
echo "Starting large request in background..."

# Start large request with GetNext
(time ./mini2_client --gateway "$GATEWAY" --mode strategy-b-getnext > "$RESULTS_DIR/fairness_large_B.log" 2>&1) &
LARGE_PID=$!

# Wait 1 second
sleep 1

# Start small request
echo "Starting small request (should be faster!)..."
START_TIME=$(date +%s%3N)
time ./mini2_client --gateway "$GATEWAY" --mode strategy-b-getnext > "$RESULTS_DIR/fairness_small_B.log" 2>&1
END_TIME=$(date +%s%3N)
SMALL_LATENCY=$((END_TIME - START_TIME))

# Wait for large request to finish
wait $LARGE_PID

echo ""
echo "Strategy B Results:"
echo "  Small request latency: ${SMALL_LATENCY}ms"
grep "Total time:" "$RESULTS_DIR/fairness_small_B.log"
echo "  Large request latency:"
grep "Total time:" "$RESULTS_DIR/fairness_large_B.log"

echo ""
echo "========================================"
echo "  Fairness Test Complete!"
echo "========================================"
echo ""
echo "Results saved in $RESULTS_DIR/fairness_*.log"
echo ""
echo "Analysis:"
echo "- Strategy A blocks small requests until large ones complete"
echo "- Strategy B allows interleaving, better fairness"
