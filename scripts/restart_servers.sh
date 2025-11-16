#!/bin/bash
# Restart all servers - use this after rebuilding

echo "🔄 Restarting all mini2 servers..."
echo ""

# Kill all existing servers
echo "Stopping old servers..."
pkill -f mini2_server
sleep 1

# Check if any still running
if pgrep -f mini2_server > /dev/null; then
    echo "⚠️  Some servers still running, force killing..."
    pkill -9 -f mini2_server
    sleep 1
fi

echo "✅ All servers stopped"
echo ""
echo "📋 Now you need to start all 6 servers in separate terminals:"
echo ""
echo "Terminal 1: ./scripts/start_node.sh A"
echo "Terminal 2: ./scripts/start_node.sh B"
echo "Terminal 3: ./scripts/start_node.sh C"
echo "Terminal 4: ./scripts/start_node.sh D"
echo "Terminal 5: ./scripts/start_node.sh E"
echo "Terminal 6: ./scripts/start_node.sh F"
echo ""
echo "After all servers are started, run:"
echo "  ./scripts/quick_test.sh"
echo ""
