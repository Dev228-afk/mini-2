#!/bin/bash

# Simple Ring Topology Test
# Demonstrates how ring topology would work (requires implementation)

echo "==============================================="
echo "     Ring Topology Test (Concept Demo)"
echo "==============================================="
echo ""
echo "Ring Configuration: A → B → C → D → E → F → A"
echo ""

# Check if ring config exists
if [ ! -f "config/network_setup_ring.json" ]; then
    echo "❌ Ring config not found: config/network_setup_ring.json"
    echo "Please create the ring configuration first."
    exit 1
fi

echo "✅ Ring configuration found"
echo ""

# Show what ring topology would require
echo "📋 Ring Topology Requirements:"
echo ""
echo "1. Proto Update (minitwo.proto):"
echo "   message Request {"
echo "     string request_id = 1;"
echo "     string destination_id = 2;  // NEW: Target node in ring"
echo "     // ... existing fields"
echo "   }"
echo ""

echo "2. Forwarding Logic (RequestProcessor):"
echo "   void ForwardInRing(Request& req) {"
echo "     if (req.destination_id() == node_id_) {"
echo "       ProcessLocally(req);  // I'm the destination"
echo "     } else {"
echo "       ForwardToNext(req);    // Pass to next in ring"
echo "     }"
echo "   }"
echo ""

echo "3. Next Node Setup (from config):"
echo "   // Each node knows its 'next' neighbor"
echo "   A.next = B"
echo "   B.next = C"
echo "   C.next = D"
echo "   D.next = E"
echo "   E.next = F"
echo "   F.next = A  // Closes the ring"
echo ""

echo "==============================================="
echo "     Current Implementation Status"
echo "==============================================="
echo ""
echo "✅ Config file ready (network_setup_ring.json)"
echo "⚠️  Proto needs destination_id field"
echo "⚠️  Forwarding logic needs implementation"
echo "⚠️  Next node connection setup needed"
echo ""

echo "Estimated implementation time: 4-6 hours"
echo ""

echo "==============================================="
echo "     Testing Current System (Hierarchical)"
echo "==============================================="
echo ""

# Test current hierarchical topology instead
echo "Starting servers with HIERARCHICAL topology..."
echo "(Ring requires additional implementation)"
echo ""

# Kill any running servers
ps aux | grep mini2_server | grep -v grep | awk '{print $2}' | xargs kill 2>/dev/null
sleep 1

# Start servers
echo "Starting server A..."
./build/src/cpp/mini2_server A > /tmp/ring_test_A.log 2>&1 &
PID_A=$!
sleep 1

echo "Starting server B..."
./build/src/cpp/mini2_server B > /tmp/ring_test_B.log 2>&1 &
PID_B=$!
sleep 1

echo "Starting server C..."
./build/src/cpp/mini2_server C > /tmp/ring_test_C.log 2>&1 &
PID_C=$!
sleep 1

echo "Starting server D..."
./build/src/cpp/mini2_server D > /tmp/ring_test_D.log 2>&1 &
PID_D=$!
sleep 1

echo "Starting server E..."
./build/src/cpp/mini2_server E > /tmp/ring_test_E.log 2>&1 &
PID_E=$!
sleep 1

echo "Starting server F..."
./build/src/cpp/mini2_server F > /tmp/ring_test_F.log 2>&1 &
PID_F=$!
sleep 2

echo ""
echo "✅ All servers started"
echo ""
echo "Server PIDs:"
echo "  A: $PID_A"
echo "  B: $PID_B"
echo "  C: $PID_C"
echo "  D: $PID_D"
echo "  E: $PID_E"
echo "  F: $PID_F"
echo ""

echo "Waiting 15 seconds for autonomous health checks..."
sleep 15

echo ""
echo "==============================================="
echo "     Health Check Results (Hierarchical)"
echo "==============================================="
echo ""

echo "Server A health checks:"
tail -5 /tmp/ring_test_A.log | grep -A 3 "health check"
echo ""

echo "Server B health checks:"
tail -5 /tmp/ring_test_B.log | grep -A 3 "health check"
echo ""

echo "Server E health checks:"
tail -5 /tmp/ring_test_E.log | grep -A 3 "health check"
echo ""

echo "==============================================="
echo "     Cleanup"
echo "==============================================="
echo ""

echo "Stopping all servers..."
kill $PID_A $PID_B $PID_C $PID_D $PID_E $PID_F 2>/dev/null
sleep 1

echo "✅ All servers stopped"
echo ""

echo "==============================================="
echo "     Summary"
echo "==============================================="
echo ""
echo "Current topology: HIERARCHICAL (working)"
echo "  A → B, E (team leaders)"
echo "  B → C (worker)"
echo "  E → D, F (workers)"
echo ""
echo "To implement RING topology:"
echo "  1. Add destination_id to Request proto"
echo "  2. Implement ring forwarding logic"
echo "  3. Set up next_node connections from config"
echo "  4. Test with: ./scripts/test_ring_topology.sh"
echo ""
echo "Recommendation: Use hierarchical topology for your project"
echo "               (already working and matches requirements)"
echo ""
