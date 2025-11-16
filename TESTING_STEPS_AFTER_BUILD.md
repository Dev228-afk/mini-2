# Post-Build Testing Guide for Mini-2 Project

## After Successful Build on Both Computers

### Step 1: Verify Build Artifacts

On **both Computer 1 and Computer 2**:

```bash
cd ~/mini-2/build  # or wherever you cloned the repo

# Check that all binaries were created
ls -lh src/cpp/mini2_server
ls -lh src/cpp/mini2_client
ls -lh src/cpp/inspect_shm

# Expected output: 3 executable files
```

---

### Step 2: Configure Network Settings

#### Find Your IP Addresses

**On Computer 1 (in WSL):**
```bash
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
# Note this IP (e.g., 172.20.10.2)
```

**On Computer 2 (in WSL):**
```bash
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
# Note this IP (e.g., 172.20.10.3)
```

#### Update Configuration File

**On both computers**, edit `config/network_setup.json`:

```bash
cd ~/mini-2
nano config/network_setup.json
```

Replace the IP addresses with your actual IPs:
- Replace all `localhost` with Computer 1's IP for nodes A, B, D
- Replace all `localhost` with Computer 2's IP for nodes C, E, F

Example:
```json
{
  "nodes": [
    {"id": "A", "host": "172.20.10.2", "port": 50050, "role": "gateway"},
    {"id": "B", "host": "172.20.10.2", "port": 50051, "role": "team_leader", "team": "GREEN"},
    {"id": "C", "host": "172.20.10.3", "port": 50052, "role": "worker", "team": "GREEN"},
    {"id": "D", "host": "172.20.10.2", "port": 50053, "role": "team_leader", "team": "PINK"},
    {"id": "E", "host": "172.20.10.3", "port": 50054, "role": "team_leader", "team": "PINK"},
    {"id": "F", "host": "172.20.10.3", "port": 50055, "role": "worker", "team": "PINK"}
  ],
  "shared_memory": {
    "segments": [
      {"name": "shm_host1", "members": ["A", "B", "D"]},
      {"name": "shm_host2", "members": ["C", "E", "F"]}
    ]
  }
}
```

---

### Step 3: Test Network Connectivity

**From Computer 1:**
```bash
ping -c 3 <Computer2_IP>
```

**From Computer 2:**
```bash
ping -c 3 <Computer1_IP>
```

Both should succeed with replies.

---

### Step 4: Configure Windows Firewall (Important!)

**On BOTH computers** (in Windows PowerShell as Administrator):

```powershell
# Allow incoming connections to WSL ports
New-NetFirewallRule -DisplayName "WSL Mini-2 Servers" -Direction Inbound -LocalPort 50050-50055 -Protocol TCP -Action Allow

# Port forwarding from Windows to WSL (on each computer)
$wsl_ip = wsl hostname -I
$wsl_ip = $wsl_ip.Trim()

# Forward ports 50050-50055 to WSL
netsh interface portproxy add v4tov4 listenport=50050 listenaddress=0.0.0.0 connectport=50050 connectaddress=$wsl_ip
netsh interface portproxy add v4tov4 listenport=50051 listenaddress=0.0.0.0 connectport=50051 connectaddress=$wsl_ip
netsh interface portproxy add v4tov4 listenport=50052 listenaddress=0.0.0.0 connectport=50052 connectaddress=$wsl_ip
netsh interface portproxy add v4tov4 listenport=50053 listenaddress=0.0.0.0 connectport=50053 connectaddress=$wsl_ip
netsh interface portproxy add v4tov4 listenport=50054 listenaddress=0.0.0.0 connectport=50054 connectaddress=$wsl_ip
netsh interface portproxy add v4tov4 listenport=50055 listenaddress=0.0.0.0 connectport=50055 connectaddress=$wsl_ip
```

---

### Step 5: Start Servers

#### On Computer 1 (Servers A, B, D):

```bash
cd ~/mini-2

# Start servers manually
./build/src/cpp/mini2_server A > logs/server_A.log 2>&1 &
./build/src/cpp/mini2_server B > logs/server_B.log 2>&1 &
./build/src/cpp/mini2_server D > logs/server_D.log 2>&1 &

# Or use the automated script:
# ./scripts/start_computer1.sh

# Verify servers are running
ps aux | grep mini2_server
```

#### On Computer 2 (Servers C, E, F):

```bash
cd ~/mini-2

# Start servers manually
./build/src/cpp/mini2_server C > logs/server_C.log 2>&1 &
./build/src/cpp/mini2_server E > logs/server_E.log 2>&1 &
./build/src/cpp/mini2_server F > logs/server_F.log 2>&1 &

# Or use the automated script:
# ./scripts/start_computer2.sh

# Verify servers are running
ps aux | grep mini2_server
```

---

## Phase-by-Phase Testing

### Phase 1: Network Communication & Health Checks

**Objective:** Verify servers can communicate across network.

**Test:**
```bash
# Wait 15 seconds for health checks to run
sleep 15

# Check logs on Computer 1
tail -20 logs/server_A.log | grep "healthy"

# Check logs on Computer 2
tail -20 logs/server_E.log | grep "healthy"
```

**Expected:** You should see health check messages showing servers can reach each other across computers.

---

### Phase 2: Request Forwarding & Aggregation

**Objective:** Test request routing from gateway to team leaders to workers.

#### Test 1: GREEN Team Request (Cross-Computer)

**From Computer 1:**
```bash
cd ~/mini-2

./build/src/cpp/mini2_client \
  --server 172.20.10.2:50050 \
  --query "test green team" \
  --need-green
```

**Expected Flow:**
1. Client → A (Computer 1, gateway)
2. A → B (Computer 1, local team leader)
3. B → C (Computer 2, **cross-network** worker)
4. C processes → B aggregates
5. B → A → Client

**Check Logs:**
```bash
# On Computer 1
grep "test green team" logs/server_A.log
grep "test green team" logs/server_B.log

# On Computer 2
grep "test green team" logs/server_C.log
```

#### Test 2: PINK Team Request (Cross-Computer)

```bash
./build/src/cpp/mini2_client \
  --server 172.20.10.2:50050 \
  --query "test pink team" \
  --need-pink
```

**Expected Flow:**
1. Client → A (Computer 1)
2. A → E (Computer 2, **cross-network** team leader)
3. E → F (Computer 2, local worker)
4. F processes → E aggregates
5. E → A (cross-network) → Client

#### Test 3: Both Teams Request

```bash
./build/src/cpp/mini2_client \
  --server 172.20.10.2:50050 \
  --query "test both teams" \
  --need-green \
  --need-pink
```

**Expected:** Both GREEN and PINK teams process in parallel, results aggregated at gateway.

---

### Phase 3: Chunked Responses

**Objective:** Test large dataset transfer with chunking.

#### Test 1: Small Dataset (No Chunking)

```bash
./build/src/cpp/mini2_client \
  --server 172.20.10.2:50050 \
  --dataset test_data/data_1k.csv \
  --query "all"
```

**Expected:** Single response with 1000 rows.

#### Test 2: Medium Dataset (Chunked)

```bash
./build/src/cpp/mini2_client \
  --server 172.20.10.2:50050 \
  --dataset test_data/data_10k.csv \
  --query "all" \
  --mode chunked
```

**Expected:**
- Session opened
- Multiple chunks received
- Total 10,000 rows
- Memory efficient at gateway

#### Test 3: Check Memory Usage

```bash
# While chunked request is running, check memory
ps aux | grep mini2_server | grep " A " | awk '{print $6}'
```

---

### Phase 4: Shared Memory Coordination

**Objective:** Test load-aware routing with shared memory.

#### Test 1: Inspect Shared Memory

**On Computer 1:**
```bash
./build/src/cpp/inspect_shm shm_host1
```

**Expected Output:**
```
Segment: shm_host1 (size: 128 bytes)
Magic: 0xDEADBEEF
Version: 1
Count: 3

Process 0:
  State: IDLE (0)
  Queue Size: 0
  Last Update: 1234567890 ms
  Memory: 45678912 bytes

Process 1:
  State: IDLE (0)
  Queue Size: 0
  Last Update: 1234567891 ms
  Memory: 42345678 bytes

Process 2:
  State: IDLE (0)
  Queue Size: 0
  Last Update: 1234567892 ms
  Memory: 40123456 bytes
```

**On Computer 2:**
```bash
./build/src/cpp/inspect_shm shm_host2
```

**Expected:** Similar output for C, E, F processes.

#### Test 2: Load-Aware Routing

Send multiple concurrent requests:

```bash
# Send 10 GREEN team requests simultaneously
for i in {1..10}; do
  ./build/src/cpp/mini2_client \
    --server 172.20.10.2:50050 \
    --query "load test $i" \
    --need-green &
done

# Wait a moment, then check shared memory
sleep 2
./build/src/cpp/inspect_shm shm_host1
```

**Expected:** You should see some processes in BUSY state with non-zero queue sizes.

**Check Logs for Load-Aware Routing:**
```bash
grep "Load-aware routing" logs/server_A.log
grep "FindLeastLoadedTeamLeader" logs/server_A.log
```

---

## Performance Measurements

### Measure Latency

```bash
# Single computer baseline (if you run all servers on one computer)
time ./build/src/cpp/mini2_client --server localhost:50050 --query "test"

# Two computers (cross-network)
time ./build/src/cpp/mini2_client --server 172.20.10.2:50050 --query "test"
```

**Record:**
- Single computer: _____ ms
- Two computers: _____ ms
- Network overhead: _____ ms

### Measure Memory

```bash
# Start servers, wait for baseline
sleep 5

# Check memory before request
ps aux | grep "mini2_server A" | awk '{print $6}'

# Send large dataset
./build/src/cpp/mini2_client --server 172.20.10.2:50050 --dataset test_data/data_10k.csv --query "all"

# Check memory after request
ps aux | grep "mini2_server A" | awk '{print $6}'
```

### Measure Throughput

```bash
# Send 100 requests and measure time
time for i in {1..100}; do
  ./build/src/cpp/mini2_client --server 172.20.10.2:50050 --query "test $i" > /dev/null
done

# Calculate: 100 requests / total_seconds = requests/sec
```

---

## Troubleshooting

### Servers won't start
```bash
# Kill old processes
pkill -9 mini2_server
sleep 2

# Check if ports are free
ss -tuln | grep 5005

# Restart servers
```

### "Connection refused"
```bash
# Verify server is listening
ss -tuln | grep 50050

# Check firewall
sudo iptables -L -n | grep 50050

# Test from same computer first
./build/src/cpp/mini2_client --server localhost:50050 --query "test"
```

### Shared memory errors
```bash
# List existing segments
ls -la /dev/shm/shm_host*

# Clean up old segments
rm /dev/shm/shm_host1
rm /dev/shm/shm_host2

# Restart servers to recreate
```

### High latency
```bash
# Check WSL networking
ping 8.8.8.8  # Internet
ping <other_computer_windows_ip>  # Direct ping to Windows IP

# May need to use Windows IP instead of WSL IP
```

---

## Success Criteria Checklist

- [ ] All 6 servers start successfully
- [ ] Phase 1: Health checks work across network
- [ ] Phase 2: GREEN team request works (A→B→C)
- [ ] Phase 2: PINK team request works (A→E→F)
- [ ] Phase 2: Both teams request works in parallel
- [ ] Phase 3: Chunked responses work for large datasets
- [ ] Phase 3: Memory usage is efficient
- [ ] Phase 4: Shared memory segments created (shm_host1, shm_host2)
- [ ] Phase 4: Load-aware routing selects IDLE servers
- [ ] Performance: Cross-network latency measured
- [ ] Performance: Memory usage measured
- [ ] Performance: Throughput calculated

---

## Demo Preparation

### What to Show:

1. **Network topology:** 2 computers, 6 servers, cross-network communication
2. **Phase 2:** Request forwarding across computers with logs
3. **Phase 3:** Chunked transfer of large dataset
4. **Phase 4:** Shared memory inspection showing load distribution
5. **Performance:** Compare single vs. two-computer latency

### Key Points:

- Explain why Phase 4 requires WSL (POSIX shared memory)
- Show shared memory is for **coordination** (status tracking), not data
- Demonstrate cross-network RPC calls in logs
- Present performance measurements with analysis

Good luck! 🎉
