# Two-Computer Testing Checklist

## Pre-Deployment Setup

### Step 1: Find IP Addresses
- [ ] Computer 1: Run `ipconfig` and note IPv4 address: ________________
- [ ] Computer 2: Run `ipconfig` and note IPv4 address: ________________

### Step 2: Update Configuration
- [ ] Edit `config/network_setup_windows.json`
- [ ] Replace `192.168.1.100` with Computer 1's actual IP
- [ ] Replace `192.168.1.101` with Computer 2's actual IP
- [ ] Verify JSON is valid (no syntax errors)

### Step 3: Configure Firewall
**On Computer 1:**
```cmd
netsh advfirewall firewall add rule name="Mini2 Servers" dir=in action=allow protocol=TCP localport=50050-50055
```
- [ ] Firewall rule added successfully

**On Computer 2:**
```cmd
netsh advfirewall firewall add rule name="Mini2 Servers" dir=in action=allow protocol=TCP localport=50050-50055
```
- [ ] Firewall rule added successfully

### Step 4: Test Network Connectivity
**From Computer 1:**
```cmd
ping <Computer2_IP>
```
- [ ] Ping successful (replies received)

**From Computer 2:**
```cmd
ping <Computer1_IP>
```
- [ ] Ping successful (replies received)

---

## Phase 1: Basecamp - Network Communication

### Objective
Verify gRPC communication works across Ethernet connection.

### Steps

**Computer 1:**
- [ ] Run: `./scripts/start_computer1.sh`
- [ ] Verify Server A started (PID shown)
- [ ] Verify Server B started (PID shown)
- [ ] Verify Server D started (PID shown)
- [ ] Check logs: `tail logs/server_A.log`

**Computer 2:**
- [ ] Run: `./scripts/start_computer2.sh`
- [ ] Verify Server C started (PID shown)
- [ ] Verify Server E started (PID shown)
- [ ] Verify Server F started (PID shown)
- [ ] Check logs: `tail logs/server_E.log`

### Test: Health Checks
**From Computer 1:**
```bash
# Wait 15 seconds for autonomous health checks
sleep 15

# Check if Server A can reach Server E (on Computer 2)
grep "localhost:50054" logs/server_A.log | grep "healthy"
```
- [ ] Health check from A→E successful (cross-computer)

**From Computer 2:**
```bash
# Check if Server E can reach servers on Computer 1
grep "healthy" logs/server_E.log
```
- [ ] Health checks from E→A and E→D successful

### Measurements
- [ ] Record RTT (Round-Trip Time): _______ ms
- [ ] Record network latency: _______ ms
- [ ] All 6 servers running: YES / NO

### Success Criteria
✅ All servers start successfully  
✅ Health checks work across network  
✅ No connection errors in logs  
✅ Servers can discover each other via config  

---

## Phase 2: Request Forwarding & Aggregation

### Objective
Test request routing from gateway to team leaders to workers across computers.

### Test 1: GREEN Team Request
**From Computer 1:**
```bash
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --query "test green" --need-green
```

**Expected Flow:**
1. Client → A (Computer 1)
2. A → B (Computer 1, local)
3. B → C (Computer 2, across network)
4. C processes → B aggregates
5. B → A → Client

- [ ] Request completed successfully
- [ ] Check A log: `grep "test green" logs/server_A.log`
- [ ] Check B log: `grep "test green" logs/server_B.log`
- [ ] Check C log (on Computer 2): `grep "test green" logs/server_C.log`

### Test 2: PINK Team Request
```bash
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --query "test pink" --need-pink
```

**Expected Flow:**
1. Client → A (Computer 1)
2. A → E (Computer 2, across network)
3. E → F (Computer 2, local)
4. F processes → E aggregates
5. E → A (across network) → Client

- [ ] Request completed successfully
- [ ] Cross-computer communication A→E verified
- [ ] Worker F processed request

### Test 3: Both Teams Request
```bash
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --query "test both" --need-green --need-pink
```

**Expected Flow:**
Both GREEN and PINK teams process in parallel, results aggregated at A.

- [ ] Request completed successfully
- [ ] GREEN team results received
- [ ] PINK team results received
- [ ] Results properly aggregated

### Measurements
- [ ] End-to-end latency (GREEN only): _______ ms
- [ ] End-to-end latency (PINK only): _______ ms
- [ ] End-to-end latency (both teams): _______ ms
- [ ] Number of RPC calls: _______

### Success Criteria
✅ Requests route to correct teams  
✅ Cross-computer forwarding works  
✅ Results aggregate correctly  
✅ No data loss or corruption  

---

## Phase 3: Multi-Chunk Response Strategies

### Objective
Test chunked data transfer and session management with large datasets.

### Preparation
**On Computer 2 (servers C and F need data):**
```bash
# Ensure test data exists
ls test_data/data_10k.csv

# If not, create it:
python3 test_data/data.py
```

### Test 1: Small Dataset
```bash
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --dataset test_data/data_1k.csv --query "all"
```

- [ ] Request completed
- [ ] Data transferred successfully
- [ ] Correct number of rows: 1000

### Test 2: Medium Dataset (Chunked)
```bash
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --dataset test_data/data_10k.csv --query "all" --mode chunked
```

- [ ] Session opened
- [ ] Multiple chunks received
- [ ] Correct number of rows: 10,000
- [ ] Check memory usage on A: `ps aux | grep mini2_server`

### Test 3: Large Dataset
```bash
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --dataset test_data/data_100k.csv --query "all" --mode chunked
```

- [ ] Request completed (may take time)
- [ ] No memory overflow at gateway
- [ ] Correct number of rows: 100,000

### Test 4: Session Timeout
```bash
# Start request but don't fetch chunks
./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --query "test" --mode session

# Wait 6 minutes (session timeout is 5 minutes)
sleep 360

# Try to fetch chunk - should fail
# Check A log for session cleanup message
grep "Session timeout" logs/server_A.log
```

- [ ] Session cleanup executed
- [ ] Memory freed after timeout

### Measurements
- [ ] Memory at A (1k dataset): _______ MB
- [ ] Memory at A (10k dataset): _______ MB
- [ ] Memory at A (100k dataset): _______ MB
- [ ] Chunk retrieval time: _______ ms per chunk
- [ ] Total transfer time: _______ seconds

### Success Criteria
✅ Chunked transfer works  
✅ Memory usage is efficient  
✅ Session management works  
✅ Session timeout cleanup works  
✅ Large datasets transfer correctly  

---

## Phase 4: Shared Memory (Optional - WSL Only)

### Note
⚠️ **Phase 4 requires POSIX shared memory - NOT available on native Windows!**

If testing on Windows, either:
- Skip Phase 4 (system works fine without it)
- Use WSL (Windows Subsystem for Linux)

### What Phase 4 Does
- Stores **coordination data only** (process status, queue size)
- Does **NOT** store request/response data
- Enables **load-aware routing** (pick least busy server)
- Shared memory is **per-computer only** (not across network)

### Test (WSL Only)

**On Computer 1 (in WSL):**
```bash
# Servers should already be running
# Inspect shared memory segment
./build/src/cpp/inspect_shm shm_host1
```

**Expected Output:**
```
Segment: shm_host1
├─ Process A: IDLE, Q=0, Memory=45MB
├─ Process B: IDLE, Q=0, Memory=42MB
└─ Process D: IDLE, Q=0, Memory=40MB
```

- [ ] Shared memory segment exists
- [ ] All 3 processes visible
- [ ] Status updates every 2 seconds

**On Computer 2 (in WSL):**
```bash
./build/src/cpp/inspect_shm shm_host2
```

- [ ] Shared memory segment exists
- [ ] All 3 processes (C, E, F) visible

### Test Load-Aware Routing
```bash
# Send multiple requests to create load
for i in {1..10}; do
  ./build/src/cpp/mini2_client --server <Computer1_IP>:50050 --query "test $i" --need-green &
done

# Check A log for routing decisions
grep "Load-aware routing" logs/server_A.log
```

- [ ] A selects IDLE servers over BUSY
- [ ] Routing based on queue size

### Measurements
- [ ] Status update frequency: _______ seconds
- [ ] Routing decision time: _______ ms
- [ ] Load balancing effectiveness: _______

### Success Criteria (if testing)
✅ Shared memory segments created  
✅ Status updates working  
✅ Load-aware routing functional  
✅ No cross-computer shared memory (by design)  

---

## Performance Comparison

### Data to Collect

| Metric | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|--------|---------|---------|---------|---------|
| Network RTT (ms) | _____ | _____ | _____ | _____ |
| Request latency (ms) | _____ | _____ | _____ | _____ |
| Memory at gateway (MB) | _____ | _____ | _____ | _____ |
| RPC call count | _____ | _____ | _____ | _____ |
| Throughput (req/sec) | _____ | _____ | _____ | _____ |

### Cross-Computer vs Single-Computer
Test same workload on single computer and compare:

| Metric | Single Computer | Two Computers | Difference |
|--------|----------------|---------------|------------|
| Latency | _____ ms | _____ ms | _____ ms |
| Throughput | _____ req/s | _____ req/s | _____ req/s |

---

## Troubleshooting

### Problem: "Connection refused"
**Solution:**
```bash
# Verify server is running
ps aux | grep mini2_server

# Verify listening on correct port
netstat -an | grep "50050"

# Check firewall
netsh advfirewall show allprofiles
```

### Problem: "Cannot reach remote server"
**Solution:**
```bash
# Test basic connectivity
ping <remote_IP>

# Test port connectivity
telnet <remote_IP> 50050

# Check firewall rules
netsh advfirewall firewall show rule name="Mini2 Servers"
```

### Problem: "Shared memory initialization failed"
**Solution:**
This is **expected on Windows**. Phase 4 requires WSL or Linux. System will continue working without Phase 4.

### Problem: "Wrong data received"
**Solution:**
```bash
# Check configuration
cat config/network_setup_windows.json | grep "host"

# Verify all nodes have correct IPs
# Restart all servers after config changes
```

---

## Final Checklist

### All Phases Working
- [ ] Phase 1: Network communication across computers ✅
- [ ] Phase 2: Request forwarding GREEN team ✅
- [ ] Phase 2: Request forwarding PINK team ✅
- [ ] Phase 2: Request forwarding both teams ✅
- [ ] Phase 3: Chunked responses working ✅
- [ ] Phase 3: Session management working ✅
- [ ] Phase 3: Memory efficient ✅
- [ ] Phase 4: Shared memory (optional, WSL only) ⚠️

### Performance Data Collected
- [ ] Latency measurements recorded
- [ ] Memory usage recorded
- [ ] Throughput calculated
- [ ] Cross-computer overhead measured

### Documentation
- [ ] Configuration file updated with real IPs
- [ ] Test results documented
- [ ] Screenshots/logs saved
- [ ] Performance comparison table completed

### Demo Ready
- [ ] All servers start successfully
- [ ] Cross-computer communication demonstrated
- [ ] Data processing works end-to-end
- [ ] Can explain Phase 4 limitation on Windows

---

## Summary

**Working on Windows (native):**
- ✅ Phase 1: gRPC communication
- ✅ Phase 2: Request forwarding
- ✅ Phase 3: Chunked responses
- ❌ Phase 4: Requires WSL/Linux

**Key Understanding:**
- Shared memory is for **coordination** (status), not **data processing**
- Shared memory is **per-computer only** (not across network)
- All data processing uses **gRPC** (works on Windows)
- System is **fully functional** without Phase 4

**For your demo:**
- Show Phases 1-3 working across 2 Windows computers
- Explain Phase 4 requires POSIX (Linux/WSL)
- Demonstrate cross-network data processing
- Present performance measurements
