#!/bin/bash
# Quick test to verify the fix works

echo "=========================================="
echo "  Quick Verification Test"
echo "=========================================="
echo ""

GATEWAY="localhost:50050"
BUILD_DIR="/Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp"
TEST_DATASET="/Users/spartan/Desktop/CMPE275/mini_2/test_data/data_100k.csv"

cd "$BUILD_DIR"

echo "Testing Strategy B with 1K dataset..."
echo ""

./mini2_client --gateway "$GATEWAY" --mode strategy-b-getnext --dataset "$TEST_DATASET" 2>&1 | grep -E "Total bytes:|Total chunks:|Time to first chunk:"

echo ""
echo "=========================================="
echo "Expected: Total bytes should be ~1.2MB (1237513 bytes)"
echo "          NOT 1056 bytes!"
echo "=========================================="
