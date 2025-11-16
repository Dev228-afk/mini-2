# Two-Computer Windows Deployment Guide

## 🚨 CRITICAL: Phase 4 Shared Memory on Windows

### What Phase 4 Shared Memory Does:
**Phase 4 shared memory is used for COORDINATION, NOT data processing:**
- ✅ Tracks process status (IDLE/BUSY/SHUTDOWN)
- ✅ Monitors queue sizes
- ✅ Records memory usage
- ✅ Enables load-aware routing (select least busy server)
- ❌ Does NOT store request/response data
- ❌ Does NOT process CSV data

**Important:** The current implementation uses **POSIX shared memory** which is NOT available on Windows. 

### Windows Deployment Options:

#### Option 1: Skip Phase 4 (Recommended for Windows)
The system works perfectly without Phase 4 - you just won't have load-aware routing. All other phases work fine:
- ✅ Phase 1: Network communication (gRPC)
- ✅ Phase 2: Request forwarding and aggregation
- ✅ Phase 3: Chunked responses and session management
- ❌ Phase 4: Skip (or use Option 2)

#### Option 2: Use WSL (Windows Subsystem for Linux)
If you need Phase 4, run servers in WSL instead of native Windows:
```bash
# On each Windows PC, install WSL:
wsl --install

# Then build and run in WSL (Linux environment)
cd /path/to/mini_2
./scripts/build.sh
```

---

## 🖥️ Two-Computer Setup

### Network Configuration

**Computer 1 (Host1):**
- IP Address: `192.168.1.100` (check with `ipconfig`)
- Runs servers: A, B, D
- Shared memory segment: shm_host1 (if using WSL)

**Computer 2 (Host2):**
- IP Address: `192.168.1.101` (check with `ipconfig`)
- Runs servers: C, E, F
- Shared memory segment: shm_host2 (if using WSL)

### Step 1: Find IP Addresses

**On each Windows PC:**
```cmd
ipconfig

# Look for "Ethernet adapter" section:
# IPv4 Address: 192.168.1.100  <- Use this
```

### Step 2: Update Configuration File

Create `config/network_setup_windows.json`:

```json
{
  "nodes": [
    {
      "id": "A",
      "role": "LEADER",
      "host": "192.168.1.100",
      "port": 50050,
      "team": "GREEN"
    },
    {
      "id": "B",
      "role": "TEAM_LEADER",
      "host": "192.168.1.100",
      "port": 50051,
      "team": "GREEN"
    },
    {
      "id": "C",
      "role": "WORKER",
      "host": "192.168.1.101",
      "port": 50052,
      "team": "GREEN"
    },
    {
      "id": "D",
      "role": "TEAM_LEADER",
      "host": "192.168.1.100",
      "port": 50053,
      "team": "PINK"
    },
    {
      "id": "E",
      "role": "TEAM_LEADER",
      "host": "192.168.1.101",
      "port": 50054,
      "team": "PINK"
    },
    {
      "id": "F",
      "role": "WORKER",
      "host": "192.168.1.101",
      "port": 50055,
      "team": "PINK"
    }
  ],
  "overlay": [
    ["A", "B"],
    ["B", "C"],
    ["B", "D"],
    ["A", "E"],
    ["E", "F"],
    ["E", "D"]
  ],
  "topology_mode": "hierarchical",
  "health_check": {
    "enabled": true,
    "interval_seconds": 10,
    "timeout_seconds": 5
  },
  "client_gateway": "A",
  "shared_memory": {
    "segments": [
      {
        "name": "shm_host1",
        "members": ["A", "B", "D"]
      },
      {
        "name": "shm_host2",
        "members": ["C", "E", "F"]
      }
    ],
    "fields": ["status", "queue_size", "last_ts_ms"]
  }
}
```

### Step 3: Configure Windows Firewall

**On BOTH computers, allow port range 50050-50055:**

```cmd
# Run as Administrator in Command Prompt:
netsh advfirewall firewall add rule name="Mini2 gRPC Servers" dir=in action=allow protocol=TCP localport=50050-50055

# Verify:
netsh advfirewall firewall show rule name="Mini2 gRPC Servers"
```

### Step 4: Test Network Connectivity

**From Computer 1, test Computer 2:**
```cmd
ping 192.168.1.101
```

**From Computer 2, test Computer 1:**
```cmd
ping 192.168.1.100
```

Both should respond successfully.

---

## 🚀 Testing All Phases (Without Phase 4)

### Phase 1: Basic Communication

**Computer 1 (192.168.1.100):**
```bash
# Start servers A, B, D
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node A &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node B &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node D &
```

**Computer 2 (192.168.1.101):**
```bash
# Start servers C, E, F
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node C &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node E &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node F &
```

**Test from Computer 1:**
```bash
# Test ping to local and remote servers
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --mode ping
```

**Expected Output:**
```
✅ Health checks working between computers
✅ Servers A, B, D on Computer 1
✅ Servers C, E, F on Computer 2
✅ Cross-network communication via Ethernet
```

### Phase 2: Request Forwarding

**Test data processing across computers:**

```bash
# From Computer 1:
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --query "SELECT * FROM test" --need-green --need-pink
```

**What happens:**
1. Client → A (Computer 1)
2. A → B (Computer 1, same machine)
3. A → E (Computer 2, across network)
4. B → C (Computer 2, across network)
5. E → F (Computer 2, same machine)
6. Results aggregate back to A
7. A → Client

**Expected Output:**
```
✅ Request routed to both GREEN and PINK teams
✅ Workers on both computers process data
✅ Results aggregated correctly
✅ Cross-computer communication successful
```

### Phase 3: Chunked Responses

**Test with large dataset:**

```bash
# Load dataset on workers (do this on both computers)
# Computer 1: (B doesn't process, but D might if it's a worker in your setup)
# Computer 2:
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node C --dataset test_data/data_10k.csv &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node F --dataset test_data/data_10k.csv &

# Test chunked response
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --query "all" --mode chunked
```

**Expected Output:**
```
✅ Session opened
✅ Large dataset split into chunks
✅ Chunks retrieved incrementally
✅ Memory efficient (no huge buffer at gateway)
```

---

## 📊 Phase 4: Shared Memory (Optional - WSL Only)

### Understanding Phase 4 Shared Memory

**What it does:**
- Stores only **metadata** in shared memory (per-host)
- Each process updates its status every 2 seconds
- Gateway reads status to make routing decisions

**Example shared memory content:**
```
Process A: IDLE,   Queue=0, Memory=45MB, Updated=0.5s ago
Process B: BUSY,   Queue=3, Memory=52MB, Updated=1.2s ago
Process D: IDLE,   Queue=0, Memory=40MB, Updated=0.8s ago
```

**What it does NOT do:**
- ❌ Does NOT store CSV data
- ❌ Does NOT store requests/responses
- ❌ Does NOT process data
- ❌ Does NOT transfer data between computers

**Benefit:**
- **Without Phase 4:** Gateway uses round-robin (B → D → B → D...)
- **With Phase 4:** Gateway picks least busy (B is IDLE, use B; D is BUSY, skip D)

### Testing Phase 4 (WSL Only)

**On Computer 1 (WSL):**
```bash
# Servers will share memory locally
wsl
cd /path/to/mini_2
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node A &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node B &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node D &

# Inspect shared memory
./build/src/cpp/inspect_shm shm_host1
```

**On Computer 2 (WSL):**
```bash
wsl
cd /path/to/mini_2
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node C &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node E &
./build/src/cpp/mini2_server --config config/network_setup_windows.json --node F &

# Inspect shared memory
./build/src/cpp/inspect_shm shm_host2
```

**Expected Output:**
```
Segment: shm_host1 (Computer 1 only)
├─ Process A: IDLE, Q=0
├─ Process B: BUSY, Q=2  <- Has pending work
└─ Process D: IDLE, Q=0

Segment: shm_host2 (Computer 2 only)
├─ Process C: IDLE, Q=0
├─ Process E: IDLE, Q=0
└─ Process F: BUSY, Q=1
```

**Load-aware routing in action:**
```
[A] Load-aware routing: Selected B for GREEN team
[A]   Reason: B is IDLE (Q=0), better than round-robin
```

---

## 🧪 Complete Test Sequence

### 1. Baseline Test (Phase 1)
```bash
# Verify all servers are reachable
for port in 50050 50051 50052 50053 50054 50055; do
  echo "Testing port $port..."
  ./build/src/cpp/mini2_client --server 192.168.1.100:$port --mode ping
done
```

### 2. Request Forwarding Test (Phase 2)
```bash
# Test GREEN team only
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --query "test green" --need-green

# Test PINK team only
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --query "test pink" --need-pink

# Test both teams
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --query "test both" --need-green --need-pink
```

### 3. Data Processing Test (Phase 2 + 3)
```bash
# Load real dataset
./build/src/cpp/mini2_client --server 192.168.1.100:50050 --dataset test_data/data_1k.csv --query "all"
```

### 4. Performance Test (All Phases)
```bash
# Measure end-to-end latency
time ./build/src/cpp/mini2_client --server 192.168.1.100:50050 --dataset test_data/data_10k.csv --query "all"

# Monitor memory on both computers
./build/src/cpp/show_distributed_memory --config config/network_setup_windows.json
```

---

## 📝 Measurement & Reporting

### Metrics to Collect

**Phase 1 (Basecamp):**
- RTT (Round-Trip Time) for Ping
- Network latency between computers
- Successful connection rate

**Phase 2 (Forwarding):**
- End-to-end request latency
- Message count (how many RPCs)
- CPU usage on each server

**Phase 3 (Chunking):**
- Memory usage at gateway
- Chunk retrieval time
- Total transfer time vs. RequestOnce

**Phase 4 (Shared Memory - Optional):**
- Status update frequency
- Routing decision accuracy
- Load balancing effectiveness

### Sample Results Table

```
| Phase | Metric | Without Optimization | With Optimization | Improvement |
|-------|--------|---------------------|-------------------|-------------|
| 1 | Network RTT | 2ms | 2ms | - |
| 2 | Request latency | 50ms | 45ms | 10% |
| 3 | Memory (Gateway) | 500MB | 50MB | 90% |
| 4 | Routing time | 5ms | 0.05ms | 100x |
```

---

## 🐛 Troubleshooting

### "Cannot connect to remote server"
```bash
# Check firewall on target computer
netsh advfirewall show allprofiles

# Verify server is listening
netstat -an | findstr "50050"
```

### "Shared memory failed to initialize" (Expected on Windows)
```
This is normal if not using WSL. Phase 4 is optional.
System will continue without load-aware routing.
```

### "Connection refused"
- Verify IP addresses are correct
- Check servers are actually running
- Ensure ports are not blocked by firewall

---

## ✅ Summary

**Phases Working on Windows:**
- ✅ Phase 1: Basic communication (gRPC over Ethernet)
- ✅ Phase 2: Request forwarding across computers
- ✅ Phase 3: Chunked responses and session management
- ⚠️ Phase 4: Only works in WSL (optional)

**Key Points:**
1. Phase 4 shared memory is for **coordination** (status), not **data processing**
2. Shared memory is **per-host only** (not across network)
3. System works fine without Phase 4 on Windows
4. All data processing uses gRPC (works on Windows natively)

**For your demo:**
- Show Phases 1-3 working across 2 Windows computers
- Explain Phase 4 requires POSIX (Linux/WSL)
- Demonstrate cross-network data processing
- Measure and compare performance
