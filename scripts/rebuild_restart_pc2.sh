#!/bin/bash
# ============================================================
# Rebuild and Restart Script for PC-2
# Run this on dev@Dev after git pull
# ============================================================

set -e

echo "============================================================"
echo "PC-2 Rebuild & Restart"
echo "============================================================"
echo ""

cd /mnt/c/Users/devan/mini-2

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main
echo ""

# Rebuild
echo "🔨 Building..."
cmake --build build --target mini2_server -j4
echo ""

# Kill old servers
echo "🔪 Killing old servers..."
ps aux | grep mini2_server | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
sleep 2
echo ""

# Start servers
echo "🚀 Starting servers C, E, F..."
./build/src/cpp/mini2_server C > /tmp/server_C.log 2>&1 &
./build/src/cpp/mini2_server E > /tmp/server_E.log 2>&1 &
./build/src/cpp/mini2_server F > /tmp/server_F.log 2>&1 &
echo ""

# Wait and verify
echo "⏳ Waiting 15 seconds for startup..."
sleep 15
echo ""

echo "✅ Servers started. Verifying..."
ps aux | grep mini2_server | grep -v grep
echo ""

echo "📊 Health check status:"
tail -5 /tmp/server_C.log | grep "Health check" || echo "  C: Initializing..."
tail -5 /tmp/server_E.log | grep "Health check" || echo "  E: Initializing..."
tail -5 /tmp/server_F.log | grep "Health check" || echo "  F: Initializing..."
echo ""

echo "============================================================"
echo "✅ PC-2 Ready!"
echo "============================================================"
echo ""
echo "Run quick monitor:"
echo "  ./scripts/quick_test_pc2.sh"
echo ""
