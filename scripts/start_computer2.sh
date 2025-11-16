#!/bin/bash
# Startup script for Computer 2 (Host2)
# Runs servers: C, E, F

echo "=========================================="
echo "  Computer 2 (Host2) - Servers C, E, F"
echo "=========================================="
echo ""

# Check if config file is updated
echo "Checking configuration..."
WORKER_C_IP=$(grep -A 5 '"id": "C"' config/network_setup_windows.json | grep "host" | cut -d'"' -f4)
echo "Worker C IP: $WORKER_C_IP"
echo ""

if [ "$WORKER_C_IP" = "localhost" ] || [ "$WORKER_C_IP" = "127.0.0.1" ]; then
    echo "⚠️  WARNING: Configuration still uses localhost!"
    echo "    Please update config/network_setup_windows.json with your actual IP addresses"
    echo "    Run 'ipconfig' to find your IPv4 address"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build if needed
if [ ! -f "build/src/cpp/mini2_server" ]; then
    echo "Building project..."
    ./scripts/build.sh
fi

# Kill any existing servers
echo "Stopping existing servers..."
pkill -f mini2_server 2>/dev/null
sleep 2

# Create logs directory
mkdir -p logs

echo ""
echo "Starting servers..."
echo ""

# Start Server C (Worker - Green)
echo "[1/3] Starting Server C (Worker - Green) on port 50052..."
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node C > logs/server_C.log 2>&1 &
PID_C=$!
echo "  PID: $PID_C"
sleep 2

# Start Server E (Team Leader - Pink)
echo "[2/3] Starting Server E (Team Leader - Pink) on port 50054..."
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node E > logs/server_E.log 2>&1 &
PID_E=$!
echo "  PID: $PID_E"
sleep 2

# Start Server F (Worker - Pink)
echo "[3/3] Starting Server F (Worker - Pink) on port 50055..."
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node F > logs/server_F.log 2>&1 &
PID_F=$!
echo "  PID: $PID_F"
sleep 2

echo ""
echo "=========================================="
echo "  ✅ All servers started on Computer 2"
echo "=========================================="
echo ""
echo "Server C (Worker):         PID $PID_C  - Port 50052"
echo "Server E (Team Leader):    PID $PID_E  - Port 50054"
echo "Server F (Worker):         PID $PID_F  - Port 50055"
echo ""
echo "Logs available in logs/ directory:"
echo "  - logs/server_C.log"
echo "  - logs/server_E.log"
echo "  - logs/server_F.log"
echo ""
echo "To view logs:"
echo "  tail -f logs/server_E.log"
echo ""
echo "To stop all servers:"
echo "  pkill -f mini2_server"
echo ""
echo "Waiting for servers to initialize..."
sleep 5

echo ""
echo "Checking server status..."
if ps -p $PID_C > /dev/null; then
    echo "✅ Server C is running"
else
    echo "❌ Server C failed to start (check logs/server_C.log)"
fi

if ps -p $PID_E > /dev/null; then
    echo "✅ Server E is running"
else
    echo "❌ Server E failed to start (check logs/server_E.log)"
fi

if ps -p $PID_F > /dev/null; then
    echo "✅ Server F is running"
else
    echo "❌ Server F failed to start (check logs/server_F.log)"
fi

echo ""
echo "Ready to process requests from Computer 1!"
echo "Press Ctrl+C to stop all servers"
echo ""

# Wait for Ctrl+C
trap "echo ''; echo 'Stopping all servers...'; kill $PID_C $PID_E $PID_F 2>/dev/null; echo 'Servers stopped.'; exit 0" INT TERM

# Keep script running
wait
