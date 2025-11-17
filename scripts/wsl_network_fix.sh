#!/bin/bash
# WSL Networking Fix - Run on BOTH computers
# Fixes the "tcp handshaker shutdown" error

echo "=== WSL NETWORKING FIX ==="
echo ""

# Get IPs
WSL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -z "$WSL_IP" ]; then
    WSL_IP=$(hostname -I | awk '{print $1}')
fi

echo "WSL IP: $WSL_IP"
echo ""

# Test if server is actually listening
echo "Checking if servers are listening on ports..."
netstat -tuln 2>/dev/null | grep -E ':(5005[0-5])' || ss -tuln | grep -E ':(5005[0-5])'
echo ""

# The problem: gRPC servers bind to 0.0.0.0 but WSL networking needs Windows firewall config

echo "=========================================="
echo "WINDOWS FIREWALL CONFIGURATION NEEDED"
echo "=========================================="
echo ""
echo "Open PowerShell AS ADMINISTRATOR on Windows and run:"
echo ""
echo "# Get WSL IP"
echo "wsl hostname -I"
echo ""
echo "# Allow firewall"
echo "New-NetFirewallRule -DisplayName \"Mini2 WSL\" -Direction Inbound -LocalPort 50050-50055 -Protocol TCP -Action Allow"
echo ""
echo "# Port forwarding (replace WSL_IP with actual IP from first command)"
echo "\$wslip = \"$WSL_IP\""
echo "netsh interface portproxy delete v4tov4 listenport=50050 listenaddress=0.0.0.0"
echo "netsh interface portproxy delete v4tov4 listenport=50051 listenaddress=0.0.0.0"
echo "netsh interface portproxy delete v4tov4 listenport=50052 listenaddress=0.0.0.0"
echo "netsh interface portproxy delete v4tov4 listenport=50053 listenaddress=0.0.0.0"
echo "netsh interface portproxy delete v4tov4 listenport=50054 listenaddress=0.0.0.0"
echo "netsh interface portproxy delete v4tov4 listenport=50055 listenaddress=0.0.0.0"
echo ""
echo "netsh interface portproxy add v4tov4 listenport=50050 listenaddress=0.0.0.0 connectport=50050 connectaddress=\$wslip"
echo "netsh interface portproxy add v4tov4 listenport=50051 listenaddress=0.0.0.0 connectport=50051 connectaddress=\$wslip"
echo "netsh interface portproxy add v4tov4 listenport=50052 listenaddress=0.0.0.0 connectport=50052 connectaddress=\$wslip"
echo "netsh interface portproxy add v4tov4 listenport=50053 listenaddress=0.0.0.0 connectport=50053 connectaddress=\$wslip"
echo "netsh interface portproxy add v4tov4 listenport=50054 listenaddress=0.0.0.0 connectport=50054 connectaddress=\$wslip"
echo "netsh interface portproxy add v4tov4 listenport=50055 listenaddress=0.0.0.0 connectport=50055 connectaddress=\$wslip"
echo ""
echo "# Verify"
echo "netsh interface portproxy show all"
echo ""
echo "=========================================="
echo ""

echo "OR use Windows IP directly instead of WSL IP:"
echo ""
echo "Find Windows IP:"
WIN_IP=$(ip route show | grep -i default | awk '{ print $3}')
echo "  Windows IP (gateway): $WIN_IP"
echo ""
echo "Update config to use Windows IPs instead of WSL IPs if this doesn't work."
echo ""

echo "Quick test from WSL:"
echo "  telnet $WSL_IP 50050"
echo "  (Ctrl+C to exit if it connects)"
