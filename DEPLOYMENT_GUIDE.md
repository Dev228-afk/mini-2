# Deploying to 2 Machines - Complete Guide

## Understanding the Requirement

**"Deploy (or code should work on minimum 2 machines) to 2 machines"**

This means your system must be able to run across **at least 2 physical machines**, not just localhost. This demonstrates true distributed computing.

---

## Current Setup (Development)

Currently running on **1 machine (localhost)**:
```
localhost:50050 - Process A
localhost:50051 - Process B  
localhost:50052 - Process C
localhost:50053 - Process D
localhost:50054 - Process E
localhost:50055 - Process F
```

---

## Production Setup (2 Machines)

### Recommended Split: By Team

**Machine 1 (host1.example.com or 192.168.1.100)**
- Process A (Leader) - Port 50050
- Process B (Green Team Leader) - Port 50051
- Process C (Green Worker) - Port 50052

**Machine 2 (host2.example.com or 192.168.1.101)**
- Process D (Pink Team Leader) - Port 50053
- Process E (Pink Team Leader) - Port 50054
- Process F (Pink Worker) - Port 50055

### Why this split?
- ✅ Each machine has 1 team
- ✅ Process A can communicate with both teams
- ✅ Demonstrates cross-machine RPC
- ✅ Balanced load (3 processes per machine)

---

## Step-by-Step Deployment

### Step 1: Prepare Both Machines

On **both Machine 1 and Machine 2**:

```bash
# Install dependencies
brew install grpc protobuf cmake

# Clone/copy your project
git clone <your-repo> /path/to/mini_2
# OR
scp -r mini_2/ user@machine2:/path/to/mini_2

cd mini_2
```

### Step 2: Update Configuration

Edit `config/network_setup.json`:

```json
{
  "nodes": {
    "A": {
      "id": "A",
      "role": "leader",
      "host": "192.168.1.100",  // ← Machine 1 IP
      "port": 50050,
      "team": "none"
    },
    "B": {
      "id": "B",
      "role": "team_leader",
      "host": "192.168.1.100",  // ← Machine 1 IP
      "port": 50051,
      "team": "green"
    },
    "C": {
      "id": "C",
      "role": "worker",
      "host": "192.168.1.100",  // ← Machine 1 IP
      "port": 50052,
      "team": "green"
    },
    "D": {
      "id": "D",
      "role": "team_leader",
      "host": "192.168.1.101",  // ← Machine 2 IP
      "port": 50053,
      "team": "pink"
    },
    "E": {
      "id": "E",
      "role": "team_leader",
      "host": "192.168.1.101",  // ← Machine 2 IP
      "port": 50054,
      "team": "pink"
    },
    "F": {
      "id": "F",
      "role": "worker",
      "host": "192.168.1.101",  // ← Machine 2 IP
      "port": 50055,
      "team": "pink"
    }
  },
  "overlay_edges": [
    {"from": "A", "to": "B"},
    {"from": "B", "to": "C"},
    {"from": "B", "to": "D"},
    {"from": "A", "to": "E"},
    {"from": "E", "to": "F"},
    {"from": "E", "to": "D"}
  ]
}
```

**Important**: Replace `192.168.1.100` and `192.168.1.101` with your actual machine IPs.

### Step 3: Find Your Machine IPs

**On Machine 1:**
```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1

# Linux
hostname -I
```

**On Machine 2:**
```bash
# Same commands as above
```

### Step 4: Build on Both Machines

**On Machine 1:**
```bash
cd /path/to/mini_2
./scripts/gen_proto.sh
./scripts/build.sh
```

**On Machine 2:**
```bash
cd /path/to/mini_2
./scripts/gen_proto.sh
./scripts/build.sh
```

### Step 5: Configure Firewall

**On both machines**, allow incoming connections on ports 50050-50055:

**macOS:**
```bash
# System Settings > Network > Firewall > Options
# Add mini2_server to allowed apps
```

**Linux (Ubuntu):**
```bash
sudo ufw allow 50050:50055/tcp
sudo ufw reload
```

### Step 6: Start Processes

**On Machine 1 (192.168.1.100):**
```bash
# Terminal 1
./scripts/start_node.sh A

# Terminal 2
./scripts/start_node.sh B

# Terminal 3
./scripts/start_node.sh C
```

**On Machine 2 (192.168.1.101):**
```bash
# Terminal 1
./scripts/start_node.sh D

# Terminal 2
./scripts/start_node.sh E

# Terminal 3
./scripts/start_node.sh F
```

### Step 7: Test Cross-Machine Communication

**From Machine 1:**
```bash
# Test Ping to all nodes
cd build/src/cpp
./mini2_client --gateway 192.168.1.100:50050 --mode all

# Test request processing
./mini2_client --gateway 192.168.1.100:50050 --mode request
```

---

## Verification Checklist

- [ ] Both machines can ping each other
- [ ] Ports 50050-50055 are open on both machines
- [ ] All 6 servers start without errors
- [ ] Client can ping all 6 nodes (even on Machine 2)
- [ ] Request processing works across machines
- [ ] Server logs show cross-machine RPC calls

---

## Troubleshooting

### "Connection refused" to Machine 2 nodes

**Cause**: Firewall blocking or wrong IP address

**Fix**:
```bash
# On Machine 2, check if server is listening
lsof -i:50053 -sTCP:LISTEN

# Test connectivity from Machine 1
telnet 192.168.1.101 50053
# Or
nc -zv 192.168.1.101 50053
```

### "Address already in use"

**Cause**: Old process still running

**Fix**:
```bash
# Kill old processes
pkill -f mini2_server

# Check ports
lsof -i:50050-50055
```

### Cross-machine latency too high

**Cause**: Network congestion or WiFi

**Fix**:
- Use wired Ethernet connections
- Ensure both machines on same subnet
- Check network with: `ping 192.168.1.101`

---

## Testing Locally First (Current Setup)

Before deploying to 2 machines, you should:

1. ✅ **Test on localhost** (what you're doing now)
2. ✅ **Verify all functionality works**
3. ✅ **Measure baseline performance**
4. Then **deploy to 2 machines**

---

## Alternative: Use 2 Machines at School/Lab

If you have access to lab computers:

```bash
# Machine 1: lab-computer-01
host1.sjsu.edu or 10.0.x.1

# Machine 2: lab-computer-02  
host2.sjsu.edu or 10.0.x.2
```

Same deployment steps apply!

---

## Documentation Requirements

In your report, include:

1. **Network Diagram**: Show which processes run on which machine
2. **Configuration**: Show the updated `network_setup.json`
3. **Screenshots**: Server outputs from both machines
4. **Performance**: Compare localhost vs 2-machine latency
5. **Challenges**: Any issues faced during deployment

---

## Summary

**For Phase 1 & 2 Testing**: 
- ✅ OK to use localhost (faster iteration)
- Focus on functionality first

**For Final Demo/Report**:
- ❗ MUST deploy to 2 machines
- Show cross-machine RPC working
- Measure real network latency

**Your Code Already Supports This!**
- Configuration is in JSON (no hardcoding)
- gRPC works across machines automatically
- Just update IPs and deploy! 🚀

---

## Quick Reference

**Find Machine IP:**
```bash
ifconfig | grep "inet "  # macOS
hostname -I              # Linux
```

**Test Connectivity:**
```bash
ping <machine2-ip>
telnet <machine2-ip> 50053
```

**Check Firewall:**
```bash
sudo ufw status  # Linux
# System Settings > Firewall  # macOS
```

**Kill All Servers:**
```bash
pkill -f mini2_server
```
