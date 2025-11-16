#!/bin/bash
# Quick Phase 2 Test - Run this after all 6 servers are started

echo "🚀 Quick Phase 2 Test"
echo ""

cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp

echo "Testing request processing..."
./mini2_client --mode request

echo ""
echo "✅ Test complete! Check the output above for results."
