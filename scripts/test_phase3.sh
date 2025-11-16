#!/bin/bash
# Quick Phase 3 Test - Run this after all 6 servers are started

echo "🚀 Phase 3 Chunking Strategy Test"
echo ""

cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp

echo "=========================================="
echo "Testing all chunking strategies..."
echo "=========================================="
./mini2_client --mode phase3

echo ""
echo "✅ Phase 3 test complete!"
echo ""
echo "📊 Compare the results:"
echo "  - Strategy A (RequestOnce): All chunks at once, lowest latency"
echo "  - Strategy B GetNext: Progressive chunking, faster time to first chunk"
echo "  - Strategy B PollNext: Polling pattern, similar to GetNext"
