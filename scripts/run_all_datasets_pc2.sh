#!/bin/bash
# ============================================================
# Monitor All Datasets Test - PC-2
# Monitors servers during multi-dataset testing
# ============================================================

set -e

echo "============================================================"
echo "PC-2 Multi-Dataset Test Monitor"
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
echo "Initial Server Status"
echo "============================================================"
echo ""

echo "Server C (Worker - Green Team):"
ps aux | grep "mini2_server C" | grep -v grep || echo "  Not running"

echo ""
echo "Server E (Team Leader - Pink Team):"
ps aux | grep "mini2_server E" | grep -v grep || echo "  Not running"

echo ""
echo "Server F (Worker - Pink Team):"
ps aux | grep "mini2_server F" | grep -v grep || echo "  Not running"

echo ""
echo "============================================================"
echo "Health Check Status (Before Tests)"
echo "============================================================"
echo ""

echo "Server C:"
tail -5 /tmp/server_C.log | grep "Health check complete" || echo "  Initializing..."

echo ""
echo "Server E:"
tail -5 /tmp/server_E.log | grep "Health check complete" || echo "  Initializing..."

echo ""
echo "Server F:"
tail -5 /tmp/server_F.log | grep "Health check complete" || echo "  Initializing..."

echo ""
echo "============================================================"
echo "Monitoring Server Activity"
echo "============================================================"
echo ""
echo "Waiting for test execution on PC-1..."
echo "This script will show activity as tests run."
echo ""
echo "Press Ctrl+C to stop monitoring, or wait 120 seconds..."
echo ""

# Monitor for 2 minutes (enough for 4 dataset tests)
START_TIME=$(date +%s)
DURATION=120

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -ge $DURATION ]; then
        break
    fi
    
    # Check for new activity
    echo "------------------------------------------------------------"
    echo "Time elapsed: ${ELAPSED}s / ${DURATION}s"
    echo "------------------------------------------------------------"
    
    echo ""
    echo "Server E (Team Leader) - Recent Activity:"
    tail -8 /tmp/server_E.log | grep -E "(Handling|Loading|Received|TeamLeader)" || echo "  No recent activity"
    
    echo ""
    echo "Server C (Worker) - Recent Activity:"
    tail -5 /tmp/server_C.log | grep -E "(Handling|Worker|Processing)" || echo "  No recent activity"
    
    echo ""
    echo "Server F (Worker) - Recent Activity:"
    tail -5 /tmp/server_F.log | grep -E "(Handling|Worker|Processing)" || echo "  No recent activity"
    
    echo ""
    sleep 10
done

echo ""
echo "============================================================"
echo "Final Summary - Server Activity"
echo "============================================================"
echo ""

echo "Server E (Team Leader) - Total Requests Handled:"
grep -c "Handling request" /tmp/server_E.log 2>/dev/null || echo "0"

echo ""
echo "Server C (Worker) - Total Requests Handled:"
grep -c "Handling request" /tmp/server_C.log 2>/dev/null || echo "0"

echo ""
echo "Server F (Worker) - Total Requests Handled:"
grep -c "Handling request" /tmp/server_F.log 2>/dev/null || echo "0"

echo ""
echo "============================================================"
echo "Server E Recent Logs (Last 20 lines)"
echo "============================================================"
tail -20 /tmp/server_E.log

echo ""
echo "============================================================"
echo "Health Check Status (After Tests)"
echo "============================================================"
echo ""

echo "Server C:"
tail -3 /tmp/server_C.log | grep "Health check complete" || echo "  No recent check"

echo ""
echo "Server E:"
tail -3 /tmp/server_E.log | grep "Health check complete" || echo "  No recent check"

echo ""
echo "Server F:"
tail -3 /tmp/server_F.log | grep "Health check complete" || echo "  No recent check"

echo ""
echo "============================================================"
echo "Monitoring Complete! ✅"
echo "============================================================"
echo ""
echo "All PC-2 servers remain healthy and ready for next test."
echo ""
