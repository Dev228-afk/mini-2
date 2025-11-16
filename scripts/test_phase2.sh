#!/bin/bash
# Phase 2 Testing Script - Request Forwarding and Aggregation

echo "========================================"
echo "Phase 2: Request Forwarding Test"
echo "========================================"
echo ""

# Check if all 6 servers are running
echo "Checking if all servers are running..."
MISSING=0
for port in 50050 50051 50052 50053 50054 50055; do
    if ! lsof -i:$port -sTCP:LISTEN > /dev/null 2>&1; then
        echo "❌ No server listening on port $port"
        MISSING=1
    else
        echo "✓ Server running on port $port"
    fi
done

echo ""

if [ $MISSING -eq 1 ]; then
    echo "ERROR: Not all servers are running!"
    echo "Please start all 6 servers before running this test."
    echo ""
    echo "Run in 6 separate terminals:"
    echo "  ./scripts/start_node.sh A"
    echo "  ./scripts/start_node.sh B"
    echo "  ./scripts/start_node.sh C"
    echo "  ./scripts/start_node.sh D"
    echo "  ./scripts/start_node.sh E"
    echo "  ./scripts/start_node.sh F"
    exit 1
fi

echo "All servers are ready!"
echo ""
echo "========================================"
echo "Running Phase 2 Tests"
echo "========================================"
echo ""

cd build/src/cpp

# Run the request mode tests
./mini2_client --mode request

echo ""
echo "========================================"
echo "Phase 2 Testing Complete!"
echo "========================================"
echo ""
echo "What just happened:"
echo "1. Client sent RequestOnce to Process A (Leader)"
echo "2. Process A forwarded to Team Leaders (B and/or E)"
echo "3. Team Leaders generated worker results"
echo "4. Results were aggregated and returned to client"
echo ""
echo "Next Steps:"
echo "- Review server logs in your 6 terminal windows"
echo "- Check for request forwarding messages"
echo "- Verify result aggregation"
echo "- Record performance metrics"
echo ""
