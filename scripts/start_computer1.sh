#!/bin/bash
# Startup script for Computer 1 (Host1)
# Runs servers: A, B, D

echo "=========================================="
echo "  Computer 1 (Host1) - Servers A, B, D"
echo "=========================================="
echo ""

# Check if config file is updated
echo "Checking configuration..."
GATEWAY_IP=$(grep -A 1 '"id": "A"' config/network_setup_windows.json | grep "host" | cut -d'"' -f4)
echo "Gateway IP: $GATEWAY_IP"
echo ""

if [ "$GATEWAY_IP" = "localhost" ] || [ "$GATEWAY_IP" = "127.0.0.1" ]; then
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

# Start Server A (Gateway)
echo "[1/3] Starting Server A (Gateway) on port 50050..."
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node A > logs/server_A.log 2>&1 &
PID_A=$!
echo "  PID: $PID_A"
sleep 2

# Start Server B (Team Leader - Green)
echo "[2/3] Starting Server B (Team Leader - Green) on port 50051..."
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node B > logs/server_B.log 2>&1 &
PID_B=$!
echo "  PID: $PID_B"
sleep 2

# Start Server D (Team Leader - Pink)
echo "[3/3] Starting Server D (Team Leader - Pink) on port 50053..."
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node D > logs/server_D.log 2>&1 &
PID_D=$!
echo "  PID: $PID_D"
sleep 2

echo ""
echo "=========================================="
echo "  ✅ All servers started on Computer 1"
echo "=========================================="
echo ""
echo "Server A (Gateway):        PID $PID_A  - Port 50050"
echo "Server B (Team Leader):    PID $PID_B  - Port 50051"
echo "Server D (Team Leader):    PID $PID_D  - Port 50053"
echo ""
echo "Logs available in logs/ directory:"
echo "  - logs/server_A.log"
echo "  - logs/server_B.log"
echo "  - logs/server_D.log"
echo ""
echo "To view logs:"
echo "  tail -f logs/server_A.log"
echo ""
echo "To stop all servers:"
echo "  pkill -f mini2_server"
echo ""
echo "Waiting for servers to initialize..."
sleep 5

echo ""
echo "Checking server status..."
if ps -p $PID_A > /dev/null; then
    echo "✅ Server A is running"
else
    echo "❌ Server A failed to start (check logs/server_A.log)"
fi

if ps -p $PID_B > /dev/null; then
    echo "✅ Server B is running"
else
    echo "❌ Server B failed to start (check logs/server_B.log)"
fi

if ps -p $PID_D > /dev/null; then
    echo "✅ Server D is running"
else
    echo "❌ Server D failed to start (check logs/server_D.log)"
fi

echo ""
echo "Ready to receive requests from Computer 2!"
echo "Press Ctrl+C to stop all servers"
echo ""

# Wait for Ctrl+C
trap "echo ''; echo 'Stopping all servers...'; kill $PID_A $PID_B $PID_D 2>/dev/null; echo 'Servers stopped.'; exit 0" INT TERM

# Keep script running
wait
