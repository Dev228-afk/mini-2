# Phase 3: Multi-Machine Testing Guide

## Overview

This guide explains how to perform Phase 3 chunking strategy tests across **2+ machines** to demonstrate true distributed computing performance.

---

## Prerequisites

### What You Need:
1. **2 or more physical machines** (or VMs) on the same network
2. **Network connectivity** between machines
3. **Same codebase** on all machines
4. **gRPC, Protobuf, CMake** installed on all machines

---

## Architecture for 2-Machine Setup

### Recommended Configuration:

**Machine 1 (e.g., 192.168.1.100 or host1.local)**
```
Process A (Leader)           - Port 50050  [Client connects here]
Process B (Green Team Leader) - Port 50051
Process C (Green Worker)      - Port 50052
```

**Machine 2 (e.g., 192.168.1.101 or host2.local)**
```
Process D (Pink Team Leader)  - Port 50053
Process E (Pink Team Leader)  - Port 50054
Process F (Pink Worker)       - Port 50055
```

### Network Flow:
```
Client (Machine 1 or 3) → A (Machine 1) → B (Machine 1) → C (Machine 1)
                                        ↓
                                        E (Machine 2) → D (Machine 2)
                                        ↓
                                        E (Machine 2) → F (Machine 2)
```

**Cross-machine connections**:
- A → E (Machine 1 → Machine 2)
- E → D (Machine 2 → Machine 2)

---

## Step-by-Step Setup

### Step 1: Find Machine IP Addresses

On **Machine 1**:
```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1

# Linux
ip addr show | grep "inet " | grep -v 127.0.0.1

# Expected output: 192.168.1.100 (or similar)
```

On **Machine 2**:
```bash
# Same commands
# Expected output: 192.168.1.101 (or similar)
```

### Step 2: Update Configuration on Both Machines

Edit `config/network_setup.json` on **BOTH machines** with **SAME content**:

```json
{
  "nodes": [
    {
      "id": "A",
      "role": "LEADER",
      "host": "192.168.1.100",    ← Machine 1 IP
      "port": 50050,
      "team": "GREEN"
    },
    {
      "id": "B",
      "role": "TEAM_LEADER",
      "host": "192.168.1.100",    ← Machine 1 IP
      "port": 50051,
      "team": "GREEN"
    },
    {
      "id": "C",
      "role": "WORKER",
      "host": "192.168.1.100",    ← Machine 1 IP
      "port": 50052,
      "team": "GREEN"
    },
    {
      "id": "D",
      "role": "TEAM_LEADER",
      "host": "192.168.1.101",    ← Machine 2 IP
      "port": 50053,
      "team": "PINK"
    },
    {
      "id": "E",
      "role": "TEAM_LEADER",
      "host": "192.168.1.101",    ← Machine 2 IP
      "port": 50054,
      "team": "PINK"
    },
    {
      "id": "F",
      "role": "WORKER",
      "host": "192.168.1.101",    ← Machine 2 IP
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
  ]
}
```

### Step 3: Copy Dataset to Both Machines

Ensure the dataset exists on **both machines** at the **same path**:

**Option 1: Same absolute path**
```bash
# On Machine 1
mkdir -p /Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/
scp unique_2020_fire_data.csv user@machine2:/Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/
```

**Option 2: Relative path**
```bash
# Copy to mini_2/Data/ on both machines
mkdir -p Data
cp /path/to/unique_2020_fire_data.csv Data/
```

### Step 4: Build on Both Machines

On **Machine 1**:
```bash
cd /path/to/mini_2
./scripts/build.sh
```

On **Machine 2**:
```bash
cd /path/to/mini_2
./scripts/build.sh
```

### Step 5: Check Firewall Settings

**Important**: Ensure ports are open on both machines.

**macOS**:
```bash
# Usually no firewall issues on local network
# If needed:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /path/to/mini2_server
```

**Linux (Ubuntu)**:
```bash
sudo ufw allow 50050:50055/tcp
sudo ufw reload
```

### Step 6: Test Network Connectivity

From **Machine 1**, test Machine 2:
```bash
# Test if Machine 2 ports are reachable
nc -zv 192.168.1.101 50053
nc -zv 192.168.1.101 50054
nc -zv 192.168.1.101 50055
```

From **Machine 2**, test Machine 1:
```bash
nc -zv 192.168.1.100 50050
nc -zv 192.168.1.100 50051
nc -zv 192.168.1.100 50052
```

---

## Starting Servers

### Terminal Layout

**Machine 1 - Open 3 terminals**:

Terminal 1 (Process A):
```bash
cd /path/to/mini_2/build/src/cpp
./mini2_server A
```

Terminal 2 (Process B):
```bash
cd /path/to/mini_2/build/src/cpp
./mini2_server B
```

Terminal 3 (Process C):
```bash
cd /path/to/mini_2/build/src/cpp
./mini2_server C
```

**Machine 2 - Open 3 terminals**:

Terminal 1 (Process D):
```bash
cd /path/to/mini_2/build/src/cpp
./mini2_server D
```

Terminal 2 (Process E):
```bash
cd /path/to/mini_2/build/src/cpp
./mini2_server E
```

Terminal 3 (Process F):
```bash
cd /path/to/mini_2/build/src/cpp
./mini2_server F
```

### Expected Output

You should see cross-machine connections:
```
[Process A] Connecting to team leader E at 192.168.1.101:50054
[Process A] Successfully connected to E
[Process E] Received request from A (192.168.1.100)
```

---

## Phase 3 Testing Scenarios

### Test 1: Strategy A (RequestOnce) - Small Dataset

**From Machine 1 (or 3rd machine)**:
```bash
cd /path/to/mini_2/build/src/cpp

# Test with small dataset (100 rows)
./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode request \
  --dataset /Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/unique_2020_fire_data.csv
```

**Expected Output**:
```
=== Test 1: Green Team Only ===
Request ID: test-green-001
  Total Rows: 33
  Latency: XXX ms

=== Test 2: Pink Team Only ===
Request ID: test-pink-001
  Total Rows: 67
  Latency: XXX ms

=== Test 3: Both Teams ===
Request ID: test-both-001
  Total Rows: 100
  Latency: XXX ms
```

**Record**: Total time, latency for each team

---

### Test 2: Strategy A - Large Dataset

```bash
./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode request \
  --dataset /path/to/merged.csv
```

**Expected**: Higher latency, more chunks

**Record**: Total time, memory usage on Process A

---

### Test 3: Strategy B - GetNext (Small Dataset)

```bash
./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode strategy-b-getnext
```

**Expected Output**:
```
Strategy B (GetNext) Results:
Total chunks: 4
Time to first chunk: XX ms ⚡
Total time: XXX ms
RPC calls made: 5 (1 StartRequest + 4 GetNext)
```

**Record**: Time to first chunk, total time, RPC count

---

### Test 4: Strategy B - PollNext (Small Dataset)

```bash
./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode strategy-b-pollnext
```

**Expected Output**:
```
Strategy B (PollNext) Results:
Total chunks: 4
Time to first chunk: XX ms ⚡
Total time: XXX ms
RPC calls made: 8 (1 StartRequest + 7 PollNext)
```

**Record**: Time to first chunk, polling attempts, total time

---

### Test 5: Phase 3 Comparison (All Strategies)

```bash
./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode phase3
```

This runs all three strategies back-to-back for direct comparison.

---

## Measuring Performance

### 1. Latency (Network Impact)

**Localhost** (all on Machine 1):
- Expected latency: 10-30ms
- RTT: <1ms

**Cross-machine** (Machine 1 + Machine 2):
- Expected latency: 50-200ms (depending on network)
- RTT: 1-50ms

**Measure RTT between machines**:
```bash
# From Machine 1 to Machine 2
ping -c 10 192.168.1.101

# Expected:
# time=2.5 ms (good local network)
# time=15 ms (WiFi)
# time=50 ms (different networks/VPN)
```

### 2. Memory Usage at Process A

**While test is running**, on Machine 1:
```bash
# Terminal on Machine 1
ps aux | grep mini2_server

# Or use top
top -pid <PID_of_Process_A>
```

**Record**:
- RSS (Resident Set Size) - actual memory used
- Peak memory during large dataset

### 3. Time to First Chunk

Strategy A: N/A (all at once)
Strategy B GetNext: **Time from StartRequest to first GetNext response**
Strategy B PollNext: **Time from StartRequest to first ready=true**

### 4. Total Completion Time

Start → All chunks received

---

## Fairness Testing (Two Concurrent Clients)

### Setup: Run from 2 different terminals

**Terminal 1 (Large request)**:
```bash
time ./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode request \
  --dataset /path/to/merged.csv
```

**Terminal 2 (Small request - start 1 second later)**:
```bash
sleep 1 && time ./mini2_client \
  --gateway 192.168.1.100:50050 \
  --mode request \
  --dataset /path/to/unique_2020_fire_data.csv
```

**Questions to Answer**:
- Does small request have to wait for large request to finish?
- What is the wait time for the small request?
- Is Strategy A or Strategy B better for fairness?

---

## Recording Results

### Fill in `results/phase3_comparison.csv`

```csv
strategy,dataset,chunks,time_to_first_ms,total_time_ms,rpc_calls,peak_mem_mb,fairness_wait_ms
RequestOnce,small_100rows,4,N/A,145,1,25,120
GetNext,small_100rows,4,45,180,5,15,30
PollNext,small_100rows,4,48,190,8,15,32
RequestOnce,large_1Mrows,1000,N/A,8500,1,450,5000
GetNext,large_1Mrows,1000,250,9000,1001,180,800
PollNext,large_1Mrows,1000,260,9200,1500,180,820
```

### Update `docs/research_notes.md`

```markdown
## Phase 3: Multi-Machine Testing Results

### Test Environment
- Machine 1: MacBook Pro M1, macOS, 16GB RAM, 192.168.1.100
- Machine 2: MacBook Air M2, macOS, 8GB RAM, 192.168.1.101
- Network: Local WiFi, RTT: 15ms average
- Dataset Small: 100 rows (3KB)
- Dataset Large: 1M rows (250MB)

### Strategy A: RequestOnce
**Advantages**:
- Simplest implementation (1 RPC call)
- Lowest latency for small datasets (145ms)

**Disadvantages**:
- High memory usage (450MB for 1M rows)
- Blocks small requests (5000ms wait)
- Not suitable for large datasets

### Strategy B: GetNext
**Advantages**:
- Lower memory usage (180MB vs 450MB)
- Faster time to first chunk (250ms vs 8500ms)
- Better fairness (800ms wait vs 5000ms)

**Disadvantages**:
- More RPC calls (1001 vs 1)
- Slightly higher total time (9000ms vs 8500ms)

### Recommendations
- **Small datasets (<10MB)**: Use Strategy A (RequestOnce)
- **Large datasets (>10MB)**: Use Strategy B (GetNext/PollNext)
- **Concurrent clients**: Use Strategy B for better fairness
```

---

## Troubleshooting

### Problem: "Connection refused"

**Solution**:
```bash
# Check if server is running
ps aux | grep mini2_server

# Check if port is listening
lsof -i :50050

# Test with telnet
telnet 192.168.1.101 50053
```

### Problem: "Cannot load dataset"

**Solution**:
```bash
# Ensure dataset path is correct on each machine
# Use absolute path in client command
--dataset /full/path/to/dataset.csv
```

### Problem: "Deadline exceeded"

**Solution**:
- Network is too slow
- Server is overloaded
- Increase timeout in client code

### Problem: Different results on different machines

**Solution**:
- Ensure same codebase (git commit hash)
- Ensure same dataset (checksum: `md5 dataset.csv`)
- Rebuild on both machines

---

## Quick Test Script

Create `scripts/test_multi_machine.sh`:

```bash
#!/bin/bash
# Run this on the CLIENT machine

GATEWAY="192.168.1.100:50050"
DATASET_SMALL="/path/to/unique_2020_fire_data.csv"
DATASET_LARGE="/path/to/merged.csv"

cd /path/to/mini_2/build/src/cpp

echo "==================================="
echo "Phase 3: Multi-Machine Testing"
echo "Gateway: $GATEWAY"
echo "==================================="

echo ""
echo "Test 1: Strategy A - Small Dataset"
./mini2_client --gateway $GATEWAY --mode request --dataset $DATASET_SMALL

echo ""
echo "Test 2: Strategy B GetNext - Small Dataset"
./mini2_client --gateway $GATEWAY --mode strategy-b-getnext

echo ""
echo "Test 3: Strategy B PollNext - Small Dataset"
./mini2_client --gateway $GATEWAY --mode strategy-b-pollnext

echo ""
echo "Test 4: All Strategies Comparison"
./mini2_client --gateway $GATEWAY --mode phase3

echo ""
echo "==================================="
echo "Testing Complete!"
echo "==================================="
```

Run it:
```bash
chmod +x scripts/test_multi_machine.sh
./scripts/test_multi_machine.sh
```

---

## Summary Checklist

- [ ] Configure 2+ machines with correct IPs
- [ ] Update `network_setup.json` on all machines
- [ ] Copy dataset to all machines
- [ ] Build on all machines
- [ ] Test network connectivity
- [ ] Start all 6 servers (3 per machine)
- [ ] Run Strategy A tests (small + large)
- [ ] Run Strategy B GetNext tests (small + large)
- [ ] Run Strategy B PollNext tests (small + large)
- [ ] Test concurrent clients (fairness)
- [ ] Measure memory usage
- [ ] Record all results in CSV
- [ ] Document findings in research_notes.md

---

## Expected Outcome

After completing these tests, you should have:

1. **Quantitative data** showing performance differences between strategies
2. **Evidence** that your system works across multiple machines
3. **Analysis** of when each strategy is appropriate
4. **Comparison tables** for your report

This demonstrates true distributed computing and satisfies the "minimum 2 machines" requirement!
