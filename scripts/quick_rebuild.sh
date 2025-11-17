#!/bin/bash

################################################################################
# QUICK REBUILD AND DEPLOY
# Rebuild only changed files and prepare for testing
################################################################################

set -e

echo "=========================================="
echo "Quick Rebuild and Deploy"
echo "=========================================="
echo ""

# Navigate to build directory
cd "$(dirname "$0")/../build"

echo "Step 1: Rebuilding (incremental)..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "Step 2: Verifying binaries..."
ls -lh src/cpp/mini2_server src/cpp/mini2_client 2>/dev/null || echo "Note: Some binaries not built"

echo ""
echo "=========================================="
echo "✓ Rebuild Complete"
echo "=========================================="
echo ""
echo "To deploy to Computer 1 (Linux):"
echo "  rsync -avz src/cpp/mini2_server USER@192.168.137.169:/path/to/mini_2/build/src/cpp/"
echo ""
echo "To run tests locally:"
echo "  cd .. && ./scripts/comprehensive_test_with_metrics.sh"
echo ""
