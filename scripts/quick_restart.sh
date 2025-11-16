#!/bin/bash
# Quick restart script - stops and gives instructions to restart

echo "🛑 Stopping all servers..."
pkill -f "mini2_server"
sleep 1
echo ""
echo "✅ All servers stopped"
echo ""
echo "================================================================"
echo "NOW RESTART ALL 6 SERVERS with the new code:"
echo "================================================================"
echo ""
echo "Make sure to restart them in order (A, B, C, D, E, F)"
echo "The new code has 100MB message size limits for large datasets!"
echo ""
echo "After restarting, test with:"
echo "  ./scripts/test_real_data.sh"
echo ""
