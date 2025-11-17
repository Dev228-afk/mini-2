#!/bin/bash

echo "=========================================="
echo "FORCE CONFIG UPDATE & RESTART SERVERS"
echo "=========================================="
echo ""

# Navigate to project root
cd ~/mini-2 || cd /home/*/dev/mini-2 || cd /mnt/c/Users/*/mini-2 || {
    echo "❌ Cannot find mini-2 directory"
    exit 1
}

echo "Working directory: $(pwd)"
echo ""

echo "Step 1: Stop all servers..."
pkill -9 mini2_server 2>/dev/null
sleep 2
echo "✓ Servers stopped"
echo ""

echo "Step 2: Fetch latest config from GitHub..."
git fetch origin
echo ""

echo "Step 3: Check for config changes..."
git diff HEAD origin/main config/network_setup.json
echo ""

echo "Step 4: Force update config file..."
git checkout origin/main -- config/network_setup.json
echo "✓ Config updated from GitHub"
echo ""

echo "Step 5: Verify config content..."
echo "Current hosts in config:"
grep -A1 '"host"' config/network_setup.json | grep -v "^--$"
echo ""

# Check if still using localhost
if grep -q '"host": "localhost"' config/network_setup.json; then
    echo "❌ ERROR: Config still contains 'localhost'!"
    echo ""
    echo "Manual fix required. Run these commands:"
    echo "  git pull origin main"
    echo "  git reset --hard origin/main"
    echo "  cat config/network_setup.json | grep host"
    exit 1
fi

echo "✓ Config looks correct (no localhost found)"
echo ""

echo "Step 6: Rebuild servers with new config..."
cd build
cmake .. > /dev/null 2>&1
make -j$(nproc)
if [ $? -eq 0 ]; then
    echo "✓ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi
echo ""

cd ..
echo "Step 7: Starting servers..."
./scripts/start_servers.sh
