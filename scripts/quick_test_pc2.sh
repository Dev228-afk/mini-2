#!/bin/bash
# ============================================================
# Quick Monitor Script for PC-2
# Run this on dev@Dev
# ============================================================

set -e

echo "============================================================"
echo "PC-2 Quick Monitor Script"
echo "============================================================"
echo ""

# Change to project directory
cd /mnt/c/Users/devan/mini-2

# Check if servers are running
SERVER_COUNT=$(ps aux | grep mini2_server | grep -v grep | wc -l)
if [ "$SERVER_COUNT" -lt 3 ]; then
    echo "⚠️  Servers not running. Starting servers C, E, F..."
    ./build/src/cpp/mini2_server C > /tmp/server_C.log 2>&1 &
    ./build/src/cpp/mini2_server E > /tmp/server_E.log 2>&1 &
    ./build/src/cpp/mini2_server F > /tmp/server_F.log 2>&1 &
    echo "✓ Servers started. Waiting 15 seconds for health checks..."
    sleep 15
else
    echo "✓ Servers already running (count: $SERVER_COUNT)"
    echo ""
fi

echo "============================================================"
echo "Server E Logs (Team Leader Pink)"
echo "============================================================"
tail -15 /tmp/server_E.log | grep -E "(Handling|Loading|Received|Connected|Health)" || tail -15 /tmp/server_E.log

echo ""
echo "============================================================"
echo "Server C Logs (Worker - Green Team)"
echo "============================================================"
tail -10 /tmp/server_C.log | grep -E "(Handling|Processing|Worker|Connected|Health)" || tail -10 /tmp/server_C.log

echo ""
echo "============================================================"
echo "Server F Logs (Worker - Pink Team)"
echo "============================================================"
tail -10 /tmp/server_F.log | grep -E "(Handling|Processing|Worker|Connected|Health)" || tail -10 /tmp/server_F.log

echo ""
echo "============================================================"
echo "Health Check Status"
echo "============================================================"
echo "Server C:"
tail -5 /tmp/server_C.log | grep "Health check complete" || echo "  (no recent health check)"
echo ""
echo "Server E:"
tail -5 /tmp/server_E.log | grep "Health check complete" || echo "  (no recent health check)"
echo ""
echo "Server F:"
tail -5 /tmp/server_F.log | grep "Health check complete" || echo "  (no recent health check)"

echo ""
echo "============================================================"
echo "Recent Activity (last 30 seconds)"
echo "============================================================"
echo "Server E recent logs:"
tail -20 /tmp/server_E.log

echo ""
echo "============================================================"
echo "Monitoring Complete!"
echo "============================================================"
echo ""
echo "To continuously monitor, run:"
echo "  tail -f /tmp/server_C.log /tmp/server_E.log /tmp/server_F.log"
echo ""
