# Phase 1 Testing Instructions

## ✅ What We've Done
- ✅ Built mini2_server and mini2_client
- ✅ Added Ping testing to client
- ✅ Added logging to all RPC handlers
- ✅ Created helper script to start nodes

## 🎯 Step-by-Step Testing Guide

### Part 1: Start All 6 Processes (Manual - 6 Terminals)

Open 6 terminal windows and run these commands:

**Terminal 1 - Process A (Leader):**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/start_node.sh A
```

**Terminal 2 - Process B (Team Leader Green):**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/start_node.sh B
```

**Terminal 3 - Process C (Worker Green):**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/start_node.sh C
```

**Terminal 4 - Process D (Team Leader Pink):**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/start_node.sh D
```

**Terminal 5 - Process E (Team Leader Pink):**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/start_node.sh E
```

**Terminal 6 - Process F (Worker Pink):**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/start_node.sh F
```

**Expected Output from Each Server:**
```
=========================================
Starting Process X
=========================================

Role: [LEADER/TEAM_LEADER/WORKER] (Team [Green/Pink])

Node X listening at localhost:5005X
```

---

### Part 2: Test Connectivity (7th Terminal)

Open a 7th terminal for testing:

**Test 1: Ping all 6 processes**
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp
./mini2_client --mode all
```

**Expected Output:**
```
=== Mini2 Client ===
Gateway: localhost:50050
Mode: all

Testing all processes:
Testing Ping to localhost:50050... SUCCESS (RTT: X.XX ms)
Testing Ping to localhost:50051... SUCCESS (RTT: X.XX ms)
Testing Ping to localhost:50052... SUCCESS (RTT: X.XX ms)
Testing Ping to localhost:50053... SUCCESS (RTT: X.XX ms)
Testing Ping to localhost:50054... SUCCESS (RTT: X.XX ms)
Testing Ping to localhost:50055... SUCCESS (RTT: X.XX ms)
```

**Test 2: Test individual Ping (measure RTT)**
```bash
# Ping Process A
./mini2_client --gateway localhost:50050 --mode ping

# Ping Process B
./mini2_client --gateway localhost:50051 --mode ping

# Ping Process C
./mini2_client --gateway localhost:50052 --mode ping

# And so on...
```

**Test 3: Test overlay connections**

According to the overlay topology, these connections should work:
- A ↔ B (same host)
- B ↔ C (same host in our local test)
- B ↔ D (same host)
- A ↔ E (same host)
- E ↔ F (same host)
- E ↔ D (same host)

Since we're running all on localhost, all Pings will succeed. The topology enforcement will matter when implementing request forwarding.

---

### Part 3: Measure Baseline RTT

Run this to measure RTT 10 times for each connection:

```bash
cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp

echo "=== Baseline RTT Measurements ===" > ../../../results/phase1_measurements.txt
echo "" >> ../../../results/phase1_measurements.txt

for i in {1..10}; do
  echo "Run $i:"
  ./mini2_client --mode all 2>&1 | tee -a ../../../results/phase1_measurements.txt
  sleep 1
done
```

**Or manually:** Run `./mini2_client --mode all` multiple times and record the RTT values.

---

### Part 4: Check Server Logs

In each of the 6 server terminals, you should see log output when Ping is called:
```
[NodeControl] Ping from: client at 1699563421234
```

This confirms the servers are receiving and responding to requests.

---

### Part 5: Resource Usage Baseline

**Check CPU and Memory (while servers are idle):**

```bash
# Check all processes
ps aux | grep mini2_server | grep -v grep

# Detailed for one process (e.g., Process A)
top -pid $(pgrep -f "mini2_server.*node A" | head -1)
```

**Record in results/phase1_baseline.csv:**
- Process name
- CPU usage (%)
- Memory usage (MB)
- RTT measurements

---

## 📊 What to Record

### 1. RTT Measurements
For each connection (A-F on localhost), record:
- Average RTT
- Min RTT
- Max RTT
- Standard deviation (optional)

### 2. Resource Usage
For each process (A-F):
- CPU % (idle)
- Memory MB (RSS)

### 3. Verification Checklist
- [ ] All 6 processes start successfully
- [ ] All 6 processes respond to Ping
- [ ] Client can connect to all ports
- [ ] Server logs show incoming Ping requests
- [ ] No crashes or errors

---

## 🐛 Troubleshooting

**Problem: "Address already in use"**
```bash
# Kill all mini2_server processes
pkill -f mini2_server

# Or kill specific port
lsof -ti:50050 | xargs kill -9
```

**Problem: Server crashes immediately**
- Check that config file exists: `cat config/network_setup.json`
- Verify node ID is correct: A, B, C, D, E, or F

**Problem: Client can't connect**
- Verify server is running: `ps aux | grep mini2_server`
- Check port is listening: `lsof -i :50050`

---

## ✅ Success Criteria for Phase 1

- [x] All 6 processes can start
- [ ] All 6 processes respond to Ping
- [ ] RTT measurements recorded
- [ ] Resource usage measured
- [ ] All data recorded in results/phase1_baseline.csv
- [ ] No hardcoded values (config-driven ✓)
- [ ] Servers run from terminal, not IDE ✓

---

## 🚀 Next Steps After Phase 1

Once you have baseline measurements:
1. **Update** `results/phase1_baseline.csv` with your measurements
2. **Document** findings in `docs/research_notes.md`
3. **Prepare** for Phase 2: Request Forwarding
4. **(Later)** Deploy to 2 separate machines

---

## 📝 Quick Reference

**Start a server:**
```bash
./scripts/start_node.sh <A|B|C|D|E|F>
```

**Test all Pings:**
```bash
cd build/src/cpp && ./mini2_client --mode all
```

**Test single Ping:**
```bash
cd build/src/cpp && ./mini2_client --gateway localhost:50050 --mode ping
```

**Stop all servers:**
```bash
pkill -f mini2_server
```

**Check running servers:**
```bash
ps aux | grep mini2_server | grep -v grep
```

---

Good luck! Let me know once you have the measurements and we'll move to Phase 2! 🎯
