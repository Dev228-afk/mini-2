#!/bin/bash
# Quick gRPC Installation Script for WSL
# Use this if you already have basic build tools installed

set -e

echo "Quick gRPC Installation for WSL"
echo "================================"

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential autoconf libtool pkg-config cmake git libssl-dev zlib1g-dev libprotobuf-dev protobuf-compiler

# Check if gRPC already installed
if [ -f "/usr/local/lib/libgrpc++.so" ]; then
    echo "gRPC already installed!"
    exit 0
fi

# Install gRPC
echo "Downloading gRPC v1.54.0..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

git clone --recurse-submodules -b v1.54.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc
cd grpc

echo "Building gRPC (10-15 minutes)..."
mkdir -p cmake/build
cd cmake/build

cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_BUILD_TYPE=Release \
      ../..

make -j$(nproc)
sudo make install
sudo ldconfig

# Cleanup
cd ~
rm -rf "$TEMP_DIR"

echo "✓ gRPC installed successfully!"
echo "Location: /usr/local/lib"
