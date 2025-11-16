# How to Test Ring Topology

## Quick Answer

**Ring topology is NOT currently implemented** - only the configuration file is ready. To test ring topology, you need to implement the forwarding logic first (4-6 hours of work).

---

## What Exists Now

✅ Ring configuration file: `config/network_setup_ring.json`  
✅ Hierarchical topology: Fully working  
⚠️ Ring forwarding logic: NOT implemented  
⚠️ Ring routing: NOT implemented

---

## What Ring Topology Requires

### 1. Configuration (✅ Done)

**File:** `config/network_setup_ring.json`

```json
{
  "topology_mode": "ring",
  "overlay": [
    ["A", "B"], ["B", "C"], ["C", "D"], 
    ["D", "E"], ["E", "F"], ["F", "A"]
  ]
}
```

Ring: A → B → C → D → E → F → A (closes)

### 2. Proto Update (⚠️ Needed)

**File:** `protos/minitwo.proto`

```proto
message Request {
  string request_id = 1;
  string destination_id = 2;  // NEW: Target node in ring
  string query = 3;
  bool need_green = 4;
  bool need_pink = 5;
}
```

### 3. Forwarding Logic (⚠️ Needed)

**File:** `src/cpp/server/RequestProcessor.cpp`

```cpp
void RequestProcessor::ForwardInRing(const mini2::Request& req) {
    std::cout << "[" << node_id_ << "] Received request for: " 
              << req.destination_id() << std::endl;
    
    // Check if message is for me
    if (req.destination_id() == node_id_) {
        std::cout << "[" << node_id_ << "] Processing locally (I'm destination)" 
                  << std::endl;
        ProcessLocally(req);
    } else {
        // Forward to next node in ring
        std::cout << "[" << node_id_ << "] Forwarding to next node in ring" 
                  << std::endl;
        
        if (next_node_stub_) {
            grpc::ClientContext ctx;
            mini2::HeartbeatAck ack;
            auto status = next_node_stub_->HandleRequest(&ctx, req, &ack);
            
            if (status.ok()) {
                std::cout << "[" << node_id_ << "] Forwarded successfully" 
                         << std::endl;
            } else {
                std::cerr << "[" << node_id_ << "] Forward failed: " 
                         << status.error_message() << std::endl;
            }
        }
    }
}
```

### 4. Next Node Setup (⚠️ Needed)

**File:** `src/cpp/server/RequestProcessor.h`

```cpp
class RequestProcessor {
private:
    std::string next_node_id_;
    std::unique_ptr<mini2::TeamIngress::Stub> next_node_stub_;
    
public:
    void SetNextNode(const std::string& next_id, const std::string& address);
};
```

**File:** `src/cpp/server/ServerMain.cpp`

```cpp
// Read next_node from config
std::string next_node_id = cfg.nodes[node_id].next_node;
std::string next_addr = cfg.nodes[next_node_id].host + ":" + 
                        std::to_string(cfg.nodes[next_node_id].port);
processor->SetNextNode(next_node_id, next_addr);
```

---

## Implementation Steps

### Step 1: Update Proto (30 minutes)

1. Edit `protos/minitwo.proto`
2. Add `string destination_id = 2;` to Request message
3. Run `./scripts/gen_proto.sh`

### Step 2: Add Next Node Connection (1 hour)

1. Update `RequestProcessor.h` - add next_node_stub_
2. Update `RequestProcessor.cpp` - add SetNextNode()
3. Update `ServerMain.cpp` - call SetNextNode() from config

### Step 3: Implement Ring Forwarding (2 hours)

1. Add `ForwardInRing()` method to RequestProcessor
2. Update handlers to use ring forwarding when topology_mode == "ring"
3. Add destination checking logic

### Step 4: Update Client (1 hour)

1. Update client to specify destination_id in requests
2. Test sending messages to specific nodes

### Step 5: Build & Test (1 hour)

1. Rebuild: `./scripts/build.sh`
2. Run test: `./scripts/test_ring_topology.sh`
3. Verify messages travel around the ring

**Total Time: 4-6 hours**

---

## Testing Current Implementation (Now)

Since ring is not implemented, you can test the **hierarchical topology** which is fully working:

### Run Demo Script:

```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
./scripts/test_ring_topology.sh
```

This script will:
1. Explain what ring requires
2. Show current hierarchical topology working
3. Display autonomous health checks
4. Demonstrate server-to-server communication

---

## Comparison: Hierarchical vs Ring

### Hierarchical (Current - ✅ Working)

```
Client → A (Leader)
         ├→ B (Team Leader) → C (Worker)
         └→ E (Team Leader) → D, F (Workers)
```

**Benefits:**
- ✅ Already implemented
- ✅ Natural for aggregation
- ✅ Matches project requirements (AB, BC, BD, AE, EF, ED)
- ✅ Team-based data partitioning

**Use Case:** Your current mini2 project

### Ring (Not Implemented - ⚠️)

```
A → B → C → D → E → F → A (closes)
```

**Benefits:**
- Token passing
- Distributed consensus
- Circular routing
- Every node equal

**Use Case:** Distributed databases, token ring networks

---

## Quick Test: Verify Current Topology

```bash
# Start servers
./build/src/cpp/mini2_server A &
./build/src/cpp/mini2_server B &
./build/src/cpp/mini2_server E &

# Wait 15 seconds and check logs
sleep 15
tail -20 /tmp/server_A.log

# You'll see autonomous health checks (hierarchical)
```

---

## Decision Matrix

| Scenario | Recommendation | Reason |
|----------|---------------|--------|
| **Project submission soon** | Use hierarchical | Already working, tested |
| **Want to learn ring** | Implement ring | 4-6 hours extra work |
| **Professor requires ring** | Implement ring | Follow requirements |
| **Unsure** | Use hierarchical | Safer, proven |

---

## If You Want to Implement Ring

### Minimal Working Example

I can help you implement a minimal ring topology in about 2-3 hours if you:

1. **Really want ring topology**
2. **Have 4-6 hours available**
3. **Understand it's not required** (hierarchical satisfies all requirements)

Let me know and I'll provide:
- Complete proto updates
- Full forwarding implementation
- Test client for ring routing
- Verification scripts

---

## Current Recommendation

**Stick with hierarchical topology** because:

1. ✅ Already fully implemented and tested
2. ✅ Satisfies all 12 professor requirements
3. ✅ Demonstrates autonomous behavior (Step 12)
4. ✅ Natural for your mini2 aggregation use case
5. ✅ Matches the edges specified (AB, BC, BD, AE, EF, ED)
6. ✅ No additional work needed

Ring topology is **optional** and would require significant additional implementation with no added benefit for your project requirements.

---

## Summary

**To test ring topology:** You need to implement it first (4-6 hours)  
**To test current system:** Run `./scripts/test_ring_topology.sh`  
**Recommendation:** Use hierarchical (already working perfectly)

Your current implementation satisfies all requirements including autonomous behavior. Ring topology would be extra credit at best.
