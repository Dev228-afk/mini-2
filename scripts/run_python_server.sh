#!/bin/bash

# Script to run Python server as part of the mini2 network
# Usage: ./scripts/run_python_server.sh [--isA] [--bind localhost:60000] [--node-id PY]

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT/src"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Python Mini2 Server Launcher${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if Python proto files exist
if [ ! -f "python/common/minitwo_pb2.py" ]; then
    echo -e "${YELLOW}⚠️  Proto files not found. Generating...${NC}"
    cd "$PROJECT_ROOT"
    ./scripts/gen_proto.sh
    cd "$PROJECT_ROOT/src"
fi

# Check for grpcio
if ! python3 -c "import grpc" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  grpcio not installed. Installing...${NC}"
    pip3 install grpcio grpcio-tools
fi

echo ""
echo -e "${GREEN}🚀 Starting Python server...${NC}"
echo -e "${GREEN}   Arguments: $@${NC}"
echo ""

# Run the Python server from src directory
python3 python/server/server.py "$@"
