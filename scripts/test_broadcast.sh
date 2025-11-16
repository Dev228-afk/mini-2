#!/bin/bash
# Broadcast Test - Testing broadcast and control features

GATEWAY="localhost:50050"
BUILD_DIR="/Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp"

echo "========================================"
echo "  Broadcast & Control Test"
echo "========================================"
echo ""

cd "$BUILD_DIR"

# Test 1: Ping all nodes
echo "Test 1: Pinging all nodes..."
for port in 50050 50051 50052 50053 50054 50055; do
    echo "  Pinging localhost:$port..."
    ./mini2_client --gateway "localhost:$port" --mode ping
done

echo ""
echo "Test 2: Get status from all nodes..."
# Note: You'll need to add a --mode status to client
# For now, this is a placeholder

echo ""
echo "Test 3: Send broadcast shutdown to all nodes..."
echo "WARNING: This will shutdown all servers!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

# Send shutdown to all nodes
for port in 50050 50051 50052 50053 50054 50055; do
    echo "  Sending shutdown to localhost:$port..."
    # You'll need to add shutdown client command
done

echo ""
echo "========================================"
echo "  Broadcast Test Complete!"
echo "========================================"
