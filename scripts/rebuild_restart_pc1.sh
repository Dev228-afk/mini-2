#!/bin/bash
# ============================================================
# Rebuild and Restart Script for PC-1
# Run this on root@DESKTOP-F0TMIC2 after git pull
# ============================================================

set -e

echo "============================================================"
echo "PC-1 Rebuild & Restart"
echo "============================================================"
echo ""

cd /home/meghpatel/dev/mini-2

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main
echo ""

# Rebuild
echo "🔨 Building..."
cmake --build build --target mini2_server mini2_client -j4
echo ""

# Kill old servers
echo "🔪 Killing old servers..."
ps aux | grep mini2_server | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
sleep 2
echo ""

# Start servers
echo "🚀 Starting servers A, B, D..."
./build/src/cpp/mini2_server A > /tmp/server_A.log 2>&1 &
./build/src/cpp/mini2_server B > /tmp/server_B.log 2>&1 &
./build/src/cpp/mini2_server D > /tmp/server_D.log 2>&1 &
echo ""

# Wait and verify
echo "⏳ Waiting 15 seconds for startup..."
sleep 15
echo ""

echo "✅ Servers started. Verifying..."
ps aux | grep mini2_server | grep -v grep
echo ""

echo "📊 Health check status:"
tail -5 /tmp/server_A.log | grep "Health check" || echo "  A: Initializing..."
tail -5 /tmp/server_B.log | grep "Health check" || echo "  B: Initializing..."
tail -5 /tmp/server_D.log | grep "Health check" || echo "  D: Initializing..."
echo ""

echo "============================================================"
echo "✅ PC-1 Ready!"
echo "============================================================"
echo ""
echo "Run quick test:"
echo "  ./scripts/quick_test_pc1.sh"
echo ""
