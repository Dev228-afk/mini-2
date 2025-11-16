# Quick Start Guide

## Prerequisites

### Required Software
```bash
# gRPC and Protocol Buffers
brew install grpc protobuf  # macOS
# or
sudo apt-get install -y libgrpc++-dev protobuf-compiler-grpc  # Linux

# CMake
brew install cmake  # macOS
# or
sudo apt-get install cmake  # Linux

# Python dependencies
pip3 install grpcio grpcio-tools
```

### nlohmann/json Library (for C++ config parsing)
```bash
brew install nlohmann-json  # macOS
# or
sudo apt-get install nlohmann-json3-dev  # Linux

# Or download header-only version:
wget https://github.com/nlohmann/json/releases/download/v3.11.2/json.hpp
mkdir -p src/cpp/common/nlohmann
mv json.hpp src/cpp/common/nlohmann/
```

---

## Build and Run (5 Minutes to First Test)

### Step 1: Generate Protocol Buffer Code
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
chmod +x scripts/*.sh
./scripts/gen_proto.sh
```

**Expected Output:**
```
Generated stubs for C++ and Python.
```

**Files Created:**
- `src/cpp/common/minitwo.pb.h`
- `src/cpp/common/minitwo.pb.cc`
- `src/cpp/common/minitwo.grpc.pb.h`
- `src/cpp/common/minitwo.grpc.pb.cc`
- `src/python/common/minitwo_pb2.py`
- `src/python/common/minitwo_pb2_grpc.py`

### Step 2: Build C++ Code
```bash
./scripts/build.sh
```

**Expected Output:**
```
-- Configuring done
-- Generating done
-- Build files have been written to: .../build
[100%] Built target mini2_server
[100%] Built target mini2_client
```

**Files Created:**
- `build/mini2_server` (executable)
- `build/mini2_client` (executable)

### Step 3: Test Single Server (Smoke Test)
```bash
# Terminal 1: Start Process A
./build/mini2_server --config config/network_setup.json --node A
```

**Expected Output:**
```
Node A listening at host1:50050
```

### Step 4: Test Client Connection
```bash
# Terminal 2: Run client test
./build/mini2_client --gateway localhost:50050 --mode baseline
```

**Expected Output:**
```
OpenSession ok=1
```

✅ **SUCCESS!** If you see this, your basic setup is working.

---

## Run All 6 Servers (Full System Test)

### Option 1: Using the Cluster Script
```bash
# Start all servers (will run in background)
./scripts/run_cluster.sh local
```

**Note**: This starts all servers on localhost with different ports.

### Option 2: Manual Start (Recommended for Development)

Open 6 terminal windows and run each command:

```bash
# Terminal 1 - Process A (Leader)
./build/mini2_server --config config/network_setup.json --node A

# Terminal 2 - Process B (Team Leader Green)
./build/mini2_server --config config/network_setup.json --node B

# Terminal 3 - Process C (Worker Green)
./build/mini2_server --config config/network_setup.json --node C

# Terminal 4 - Process D (Team Leader Pink)
./build/mini2_server --config config/network_setup.json --node D

# Terminal 5 - Process E (Team Leader Pink)
./build/mini2_server --config config/network_setup.json --node E

# Terminal 6 - Process F (Worker Pink)
./build/mini2_server --config config/network_setup.json --node F
```

### Option 3: Using tmux (Advanced)
```bash
# Create a tmux session with 6 panes
tmux new-session -s mini2 \; \
  split-window -h \; \
  split-window -v \; \
  split-window -v \; \
  select-pane -t 0 \; \
  split-window -v \; \
  split-window -v

# In each pane, run one server
# tmux keybindings: Ctrl-b then arrow keys to navigate
```

---

## Testing the System

### Test 1: Basic Connectivity (Ping Test)
```bash
# Modify ClientMain.cpp to test Ping RPC
# Or use Python client:
python3 - <<EOF
import grpc
from src.python.common import minitwo_pb2 as pb
from src.python.common import minitwo_pb2_grpc as rpc

channel = grpc.insecure_channel('localhost:50050')
stub = rpc.NodeControlStub(channel)
response = stub.Ping(pb.Heartbeat(from_id="test", ts_unix_ms=1234567890))
print(f"Ping response: {response.ok}")
EOF
```

### Test 2: Request Forwarding (Phase 2)
```cpp
// In ClientMain.cpp, add:
mini2::Request req;
req.set_request_id("test-001");
req.set_query("SELECT * FROM fire_data WHERE year=2020");
req.set_need_green(true);
req.set_need_pink(false);

mini2::AggregatedResult result;
grpc::ClientContext ctx;
auto status = stub->RequestOnce(&ctx, req, &result);

if (status.ok()) {
    std::cout << "Got result: " << result.total_rows() << " rows, "
              << result.total_bytes() << " bytes\n";
}
```

### Test 3: Chunked Responses (Phase 3)
```cpp
// Strategy A: Client-controlled paging
mini2::Request req;
req.set_request_id("chunk-test");
req.set_query("SELECT * FROM large_dataset");
req.set_need_green(true);
req.set_need_pink(true);

// First, get session
mini2::AggregatedResult full_result;
grpc::ClientContext ctx1;
stub->RequestOnce(&ctx1, req, &full_result);

// Then request chunks
for (uint32_t i = 0; i < full_result.chunks_size(); i++) {
    mini2::NextChunkReq chunk_req;
    chunk_req.set_request_id("chunk-test");
    chunk_req.set_next_index(i);
    
    mini2::NextChunkResp chunk_resp;
    grpc::ClientContext ctx2;
    stub->GetNext(&ctx2, chunk_req, &chunk_resp);
    
    std::cout << "Chunk " << i << ": " << chunk_resp.chunk().size() 
              << " bytes, has_more=" << chunk_resp.has_more() << "\n";
}
```

---

## Multi-Host Deployment

### Configuration for Two Hosts

Edit `config/network_setup.json`:

```json
{
  "nodes": [
    {"id": "A", "role": "LEADER", "host": "host1.local", "port": 50050, "team": "GREEN"},
    {"id": "B", "role": "TEAM_LEADER", "host": "host1.local", "port": 50051, "team": "GREEN"},
    {"id": "D", "role": "TEAM_LEADER", "host": "host1.local", "port": 50053, "team": "PINK"},
    {"id": "C", "role": "WORKER", "host": "host2.local", "port": 50052, "team": "GREEN"},
    {"id": "E", "role": "TEAM_LEADER", "host": "host2.local", "port": 50054, "team": "PINK"},
    {"id": "F", "role": "WORKER", "host": "host2.local", "port": 50055, "team": "PINK"}
  ],
  ...
}
```

### Deploy to Host1
```bash
# On host1.local
cd /path/to/mini_2
./build/mini2_server --config config/network_setup.json --node A &
./build/mini2_server --config config/network_setup.json --node B &
./build/mini2_server --config config/network_setup.json --node D &
```

### Deploy to Host2
```bash
# On host2.local
cd /path/to/mini_2
./build/mini2_server --config config/network_setup.json --node C &
./build/mini2_server --config config/network_setup.json --node E &
./build/mini2_server --config config/network_setup.json --node F &
```

### Test Cross-Host Communication
```bash
# From any machine
./build/mini2_client --gateway host1.local:50050 --mode baseline
```

---

## Performance Measurement

### Measure RTT (Round-Trip Time)
```cpp
// Add to ClientMain.cpp
#include <chrono>

auto start = std::chrono::high_resolution_clock::now();

// Make RPC call
mini2::Heartbeat hb;
hb.set_from_id("client");
hb.set_ts_unix_ms(std::chrono::system_clock::now().time_since_epoch().count());

mini2::HeartbeatAck ack;
grpc::ClientContext ctx;
auto status = stub->Ping(&ctx, hb, &ack);

auto end = std::chrono::high_resolution_clock::now();
auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);

std::cout << "RTT: " << duration.count() / 1000.0 << " ms\n";
```

### Measure CPU and Memory
```bash
# Monitor specific process
ps aux | grep mini2_server

# Continuous monitoring
watch -n 1 "ps aux | grep mini2_server | grep -v grep"

# Or use top
top -p $(pgrep -f "mini2_server.*node A")
```

### Automated Performance Test Script
```bash
#!/bin/bash
# perf_test.sh

echo "Running performance tests..."

# RTT Test
for conn in A-B B-C B-D A-E E-F E-D; do
    echo "Testing connection: $conn"
    # Run client and measure RTT
    ./build/mini2_client --test-rtt --connection $conn
done

# Load Test
echo "Running load test with 10 concurrent clients..."
for i in {1..10}; do
    ./build/mini2_client --mode load-test &
done
wait

echo "Performance test complete. Check results/ directory."
```

---

## Troubleshooting

### Problem: "cannot find -lgrpc++"
**Solution**: Install gRPC development libraries
```bash
brew install grpc  # macOS
sudo apt-get install libgrpc++-dev  # Linux
```

### Problem: "nlohmann/json.hpp: No such file or directory"
**Solution**: Install nlohmann-json library (see Prerequisites above)

### Problem: "Address already in use"
**Solution**: Kill existing server process
```bash
lsof -ti:50050 | xargs kill -9
# Or kill all mini2 servers
pkill -f mini2_server
```

### Problem: "Connection refused" when testing
**Solution**: Ensure server is running and config has correct hostname
```bash
# Check if server is listening
netstat -an | grep 50050
# or
lsof -i :50050
```

### Problem: Client hangs on RPC call
**Solution**: Check firewall settings, verify network connectivity
```bash
# Test basic connectivity
telnet host1.local 50050
# or
nc -zv host1.local 50050
```

---

## Development Workflow

### 1. Make Code Changes
```bash
# Edit files in src/cpp/ or src/python/
vim src/cpp/server/Handlers.cpp
```

### 2. Rebuild (if C++ changes)
```bash
./scripts/build.sh
```

### 3. Restart Servers
```bash
# Kill all servers
pkill -f mini2_server

# Restart
./scripts/run_cluster.sh local
```

### 4. Test Changes
```bash
./build/mini2_client --gateway localhost:50050
```

### 5. Measure and Document
```bash
# Update research notes
vim docs/research_notes.md

# Update results
vim results/phase1_baseline.csv
```

---

## Next Steps

1. ✅ Verify basic setup works (you should be here now!)
2. 📖 Read `docs/IMPLEMENTATION_GUIDE.md` for detailed phase instructions
3. ✅ Follow `TODO.md` checklist for each phase
4. 📊 Collect measurements and update `results/` CSV files
5. 📝 Document findings in `docs/research_notes.md`
6. 🎯 Complete all 4 phases
7. 🎬 Prepare demo and final documentation

---

## Useful Commands Reference

```bash
# Build everything
./scripts/build.sh

# Generate proto code
./scripts/gen_proto.sh

# Start all servers
./scripts/run_cluster.sh local

# Stop all servers
pkill -f mini2_server

# Test client
./build/mini2_client --gateway localhost:50050 --mode baseline

# Check server logs
# (Add logging to your server code and redirect to files)
tail -f logs/server_A.log

# Clean build
rm -rf build && ./scripts/build.sh

# Check network connections
netstat -an | grep 5005

# Monitor resource usage
top -pid $(pgrep -f mini2_server)
```

---

## Getting Help

1. Review the project requirements: `mini2-chunks.md`
2. Check the implementation guide: `docs/IMPLEMENTATION_GUIDE.md`
3. Look at lab examples: `Labs/loop-grpc/`, `Labs/leader-adv/`
4. gRPC documentation: https://grpc.io/docs/languages/cpp/
5. Protocol Buffers: https://protobuf.dev/

Good luck! 🚀
