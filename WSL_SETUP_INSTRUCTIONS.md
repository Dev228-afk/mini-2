# WSL Setup Guide for Mini-2 Project

## Quick Setup (Recommended)

### On Both Computers (in WSL):

```bash
# Clone the repository
git clone https://github.com/Dev228-afk/mini-2.git
cd mini-2

# Run automated setup script (takes 10-15 minutes)
chmod +x scripts/wsl_setup.sh
./scripts/wsl_setup.sh
```

This script will:
- ✅ Install all build tools (cmake, gcc, g++, etc.)
- ✅ Install gRPC and all dependencies
- ✅ Generate protobuf files
- ✅ Generate test data
- ✅ Build the entire project
- ✅ Verify all installations

---

## Alternative: Install Only gRPC (If you have build tools)

If you already have cmake, gcc, etc., and only need gRPC:

```bash
chmod +x scripts/install_grpc_only.sh
./scripts/install_grpc_only.sh
```

Then build normally:
```bash
mkdir -p build && cd build
cmake -DCMAKE_PREFIX_PATH=/usr/local ..
make -j$(nproc)
```

---

## Manual Installation (If scripts fail)

### 1. Install Build Tools
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake git pkg-config
```

### 2. Install gRPC Dependencies
```bash
sudo apt-get install -y \
    autoconf \
    libtool \
    libssl-dev \
    zlib1g-dev \
    libprotobuf-dev \
    protobuf-compiler
```

### 3. Install gRPC from Source
```bash
# Clone gRPC
git clone --recurse-submodules -b v1.54.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc
cd grpc

# Build and install
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
```

### 4. Build Mini-2 Project
```bash
cd ~/mini-2
mkdir -p build && cd build
cmake -DCMAKE_PREFIX_PATH=/usr/local ..
make -j$(nproc)
```

---

## Troubleshooting

### Error: "Could not find a package configuration file provided by gRPC"

**Solution:**
```bash
# Set CMAKE_PREFIX_PATH explicitly
cd build
rm -rf *
cmake -DCMAKE_PREFIX_PATH=/usr/local ..
make -j$(nproc)
```

### Error: "permission denied" during installation

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Error: gRPC build fails due to memory

**Solution:**
```bash
# Use fewer parallel jobs
make -j2  # Instead of -j$(nproc)
```

### Error: "Address already in use" when starting servers

**Solution:**
```bash
# Kill old processes
pkill -9 mini2_server
sleep 2
# Then restart servers
```

---

## Verification

After installation, verify everything is working:

```bash
# Check gRPC
ls /usr/local/lib/libgrpc++.so
ls /usr/local/lib/cmake/grpc

# Check binaries
ls build/src/cpp/mini2_server
ls build/src/cpp/mini2_client
ls build/src/cpp/inspect_shm

# Quick test
./build/src/cpp/mini2_server A &
sleep 2
./build/src/cpp/mini2_client --server localhost:50050 --query "test"
pkill mini2_server
```

If all commands succeed, you're ready to go!

---

## Time Estimates

- **Automated script** (`wsl_setup.sh`): 10-15 minutes
- **gRPC only** (`install_grpc_only.sh`): 8-12 minutes
- **Manual installation**: 15-20 minutes

---

## Network Configuration

After installation, update IP addresses:

```bash
# Find your WSL IP
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1

# Edit config with actual IPs
nano config/network_setup.json
# Or use the Windows template:
cp config/network_setup_windows.json config/network_setup.json
nano config/network_setup.json
```

---

## Starting Servers

**Computer 1:**
```bash
./scripts/start_computer1.sh
```

**Computer 2:**
```bash
./scripts/start_computer2.sh
```

Done! 🎉
