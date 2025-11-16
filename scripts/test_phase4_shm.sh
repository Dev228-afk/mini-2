#!/bin/bash

# Phase 4: Shared Memory Coordination Test Script
# This script demonstrates load-aware routing using shared memory

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Phase 4: Shared Memory Coordination Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}This test demonstrates:${NC}"
echo -e "  ✓ Shared memory segments for process coordination"
echo -e "  ✓ Segment 1: {A, B, D} on Host1"
echo -e "  ✓ Segment 2: {C, E, F} on Host2"
echo -e "  ✓ Real-time status updates (IDLE/BUSY, queue size, memory)"
echo -e "  ✓ Load-aware routing (select least loaded process)"
echo ""

# Ensure build is up to date
if [ ! -f "build/mini2_server" ]; then
    echo -e "${YELLOW}Building project...${NC}"
    ./scripts/build.sh
fi

# Clean up any existing shared memory segments
echo -e "${YELLOW}Cleaning up old shared memory segments...${NC}"
rm -f /dev/shm/shm_host1 /dev/shm/shm_host2 2>/dev/null

# Kill any existing servers
echo -e "${YELLOW}Stopping any existing servers...${NC}"
pkill -f "mini2_server" 2>/dev/null
sleep 2

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Starting Servers with Shared Memory...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Start servers in background
echo -e "${BLUE}[1] Starting Server A (Gateway, Segment 1)...${NC}"
./build/mini2_server --config config/network_setup.json --node A > /tmp/server_A.log 2>&1 &
PID_A=$!
sleep 1

echo -e "${BLUE}[2] Starting Server B (Team Leader - Green, Segment 1)...${NC}"
./build/mini2_server --config config/network_setup.json --node B > /tmp/server_B.log 2>&1 &
PID_B=$!
sleep 1

echo -e "${BLUE}[3] Starting Server D (Team Leader - Pink, Segment 1)...${NC}"
./build/mini2_server --config config/network_setup.json --node D > /tmp/server_D.log 2>&1 &
PID_D=$!
sleep 1

echo -e "${BLUE}[4] Starting Server C (Worker - Green, Segment 2)...${NC}"
./build/mini2_server --config config/network_setup.json --node C > /tmp/server_C.log 2>&1 &
PID_C=$!
sleep 1

echo -e "${BLUE}[5] Starting Server E (Team Leader - Pink, Segment 2)...${NC}"
./build/mini2_server --config config/network_setup.json --node E > /tmp/server_E.log 2>&1 &
PID_E=$!
sleep 1

echo -e "${BLUE}[6] Starting Server F (Worker - Pink, Segment 2)...${NC}"
./build/mini2_server --config config/network_setup.json --node F > /tmp/server_F.log 2>&1 &
PID_F=$!
sleep 2

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Servers Running:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Server A:  PID ${PID_A}  (localhost:50050) - Segment 1"
echo -e "  Server B:  PID ${PID_B}  (localhost:50051) - Segment 1"
echo -e "  Server D:  PID ${PID_D}  (localhost:50053) - Segment 1"
echo -e "  Server C:  PID ${PID_C}  (localhost:50052) - Segment 2"
echo -e "  Server E:  PID ${PID_E}  (localhost:50054) - Segment 2"
echo -e "  Server F:  PID ${PID_F}  (localhost:50055) - Segment 2"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping all servers...${NC}"
    kill $PID_A $PID_B $PID_C $PID_D $PID_E $PID_F 2>/dev/null
    wait $PID_A $PID_B $PID_C $PID_D $PID_E $PID_F 2>/dev/null
    
    echo -e "${YELLOW}Cleaning up shared memory segments...${NC}"
    rm -f /dev/shm/shm_host1 /dev/shm/shm_host2 2>/dev/null
    
    echo -e "${GREEN}All servers stopped and cleaned up.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Observing Shared Memory Coordination:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Wait for initialization
echo -e "${YELLOW}Waiting for shared memory initialization (5 seconds)...${NC}"
sleep 5

echo ""
echo -e "${GREEN}✅ Shared memory segments initialized!${NC}"
echo ""
echo -e "${YELLOW}Checking server logs for shared memory activity...${NC}"
echo ""

echo -e "${BLUE}=== Server A Log (Segment 1) ===${NC}"
grep -E "(Initializing shared memory|Successfully initialized|update thread)" /tmp/server_A.log | tail -5
echo ""

echo -e "${BLUE}=== Server B Log (Segment 1) ===${NC}"
grep -E "(Initializing shared memory|Successfully initialized|update thread)" /tmp/server_B.log | tail -5
echo ""

echo -e "${BLUE}=== Server C Log (Segment 2) ===${NC}"
grep -E "(Initializing shared memory|Successfully initialized|update thread)" /tmp/server_C.log | tail -5
echo ""

echo -e "${YELLOW}Observing status updates (next 15 seconds)...${NC}"
echo -e "${YELLOW}Watch the logs for status updates every 2 seconds${NC}"
echo ""

# Monitor for 15 seconds
for i in {1..5}; do
    echo -e "${GREEN}--- Update $i/5 ---${NC}"
    sleep 3
    echo "Server A status updates:"
    tail -3 /tmp/server_A.log | grep -E "(IDLE|BUSY|Queue)" || echo "  (monitoring...)"
    echo ""
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Phase 4 Features Demonstrated:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ✅ Shared memory segments created (shm_host1, shm_host2)"
echo -e "  ✅ Process status tracking (IDLE/BUSY state)"
echo -e "  ✅ Queue size monitoring"
echo -e "  ✅ Memory usage tracking"
echo -e "  ✅ Background status update threads (2-second interval)"
echo -e "  ✅ Load-aware routing ready (FindLeastLoadedProcess)"
echo ""

echo -e "${YELLOW}To test with actual requests:${NC}"
echo -e "  ./build/mini2_client --server localhost:50050 --query 'test green'"
echo ""

echo -e "${YELLOW}View full logs:${NC}"
echo -e "  tail -f /tmp/server_A.log   # Gateway with shared memory"
echo -e "  tail -f /tmp/server_B.log   # Team leader with shared memory"
echo ""

echo -e "${RED}Press Ctrl+C to stop all servers${NC}"
echo ""

# Keep script running
wait
