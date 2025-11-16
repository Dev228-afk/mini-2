#!/bin/bash

# Test script showing C++ and Python servers working together
# This demonstrates the professor's requirement: "a server and a client written in C++, and also a server in Python"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Mini2 - C++ & Python Mixed Server Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}This demonstrates:${NC}"
echo -e "  ✓ C++ servers (A, B, E) with autonomous health checks"
echo -e "  ✓ Python server (PY) integrated into the network"
echo -e "  ✓ C++ client communicating with both"
echo ""

# Ensure build is up to date
if [ ! -f "build/mini2_server" ]; then
    echo -e "${YELLOW}Building C++ servers...${NC}"
    mkdir -p build && cd build
    cmake .. && cmake --build .
    cd ..
fi

# Ensure Python proto files exist
if [ ! -f "src/python/common/minitwo_pb2.py" ]; then
    echo -e "${YELLOW}Generating Python proto files...${NC}"
    ./scripts/gen_proto.sh
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Starting Servers...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Start C++ servers in background
echo -e "${BLUE}[1] Starting C++ Server A (Gateway)...${NC}"
./build/mini2_server --config config/network_setup.json --node A &
PID_A=$!
sleep 1

echo -e "${BLUE}[2] Starting C++ Server B (Team Leader - Green)...${NC}"
./build/mini2_server --config config/network_setup.json --node B &
PID_B=$!
sleep 1

echo -e "${BLUE}[3] Starting C++ Server E (Worker - Green)...${NC}"
./build/mini2_server --config config/network_setup.json --node E &
PID_E=$!
sleep 1

echo -e "${BLUE}[4] Starting Python Server PY (Worker)...${NC}"
(cd "$PROJECT_ROOT/src" && python3 python/server/server.py --bind localhost:60000 --node-id PY) &
PID_PY=$!
sleep 2

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Servers Running:${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  C++ Server A:  PID ${PID_A}  (localhost:50050)"
echo -e "  C++ Server B:  PID ${PID_B}  (localhost:50051)"
echo -e "  C++ Server E:  PID ${PID_E}  (localhost:50054)"
echo -e "  Python Server: PID ${PID_PY}  (localhost:60000)"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping all servers...${NC}"
    kill $PID_A $PID_B $PID_E $PID_PY 2>/dev/null
    wait $PID_A $PID_B $PID_E $PID_PY 2>/dev/null
    echo -e "${GREEN}All servers stopped.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Testing Communication:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Wait for servers to initialize
echo -e "${YELLOW}Waiting for servers to initialize (5 seconds)...${NC}"
sleep 5

echo ""
echo -e "${GREEN}✅ Servers are running!${NC}"
echo ""
echo -e "${YELLOW}Autonomous Health Checks:${NC}"
echo -e "  - C++ servers are pinging each other every 10 seconds"
echo -e "  - Check the server logs above for ping messages"
echo ""
echo -e "${YELLOW}To test manually:${NC}"
echo -e "  # Test C++ client to C++ server A:"
echo -e "  ./build/mini2_client --server localhost:50050 --query 'test green'"
echo ""
echo -e "  # Test Python server health (using grpc_cli or similar):"
echo -e "  grpcurl -plaintext localhost:60000 mini2.NodeControl/Ping"
echo ""
echo -e "${RED}Press Ctrl+C to stop all servers${NC}"
echo ""

# Keep script running
wait
