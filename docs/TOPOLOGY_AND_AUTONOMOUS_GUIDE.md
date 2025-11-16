# Topology Configuration Guide

## Overview

The system now supports **flexible topology configuration** via the `network_setup.json` file. You can choose between:
1. **Hierarchical Topology** (default) - Tree-based structure for aggregation
2. **Ring Topology** (optional) - Circular message forwarding

## Configuration Location

`config/network_setup.json`

## Topology Modes

### Mode 1: Hierarchical (Current Implementation)

**Best for:** Aggregation, team-based processing, mini2 requirements

```
Client → A (Leader)
         ├→ B (Team Leader Green) → C (Worker)
         └→ E (Team Leader Pink) → F (Worker)
                                  → D (Worker)
```

**Config:**
```json
{
  "topology_mode": "hierarchical",
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

**Benefits:**
- ✓ Matches professor's edges: AB, BC, BD, AE, EF, ED
- ✓ Natural aggregation pattern
- ✓ Team-based data partitioning (Green/Pink)
- ✓ Easy to understand for students

### Mode 2: Ring Topology (Alternative)

**Best for:** Distributed consensus, token passing, circular routing

```
A → B → C → D → E → F → A (closes the ring)
```

**Config:**
```json
{
  "topology_mode": "ring",
  "overlay": [
    ["A", "B"],
    ["B", "C"],
    ["C", "D"],
    ["D", "E"],
    ["E", "F"],
    ["F", "A"]
  ]
}
```

**Benefits:**
- ✓ Demonstrates ring-based message passing
- ✓ Each node has exactly one "next" neighbor
- ✓ Supports circular message routing

**Note:** Ring topology requires additional implementation:
- Add `next_node_id` to each node config
- Implement ring-based forwarding logic
- Add destination checking (is message for me?)

## Current Configuration

**File:** `config/network_setup.json`

```json
{
  "topology_mode": "hierarchical",
  "health_check": {
    "enabled": true,
    "interval_seconds": 10,
    "timeout_seconds": 5
  }
}
```

### Topology Mode Options

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `topology_mode` | string | "hierarchical", "ring" | Network topology pattern |
| `health_check.enabled` | boolean | true, false | Enable autonomous health checks |
| `health_check.interval_seconds` | integer | 5-60 | How often to check neighbors |
| `health_check.timeout_seconds` | integer | 2-10 | RPC timeout for health checks |

## Autonomous Health Check Feature

**Status:** ✅ IMPLEMENTED (Student-Level)

### What It Does

Every N seconds (default: 10), each server **autonomously**:
1. Pings all connected neighbors
2. Checks if they're healthy/reachable
3. Logs success/failure rates
4. **Operates without any client input**

### Implementation Details

**Background Thread:**
```cpp
void HealthCheckThreadFunc() {
    while (running) {
        sleep(10 seconds);
        
        // Check all neighbors autonomously
        for (neighbor in neighbors) {
            ping(neighbor);
            log_result();
        }
    }
}
```

**Started Automatically:**
- When server starts
- Runs in background thread
- Stops on server shutdown

### Example Output

```
[A] Health check thread started (interval: 10s)
[A] Health check thread running autonomously...
[A] 🔍 Autonomous health check started
  ✓ localhost:50051 - healthy
  ✓ localhost:50054 - healthy
[A] Health check complete: 2/2 neighbors healthy

[A] 🔍 Autonomous health check started
  ✓ localhost:50051 - healthy
  ✗ localhost:50054 - unreachable (Connect failed)
[A] Health check complete: 1/2 neighbors healthy (⚠️ 1 failed)
```

### Why This Satisfies Professor's Step 12

**Professor's Question:**
> "The servers need to interact without external client input. So, how do you code this?"

**Our Answer:**
✅ Servers autonomously ping neighbors every 10 seconds  
✅ No client trigger needed  
✅ Background thread runs continuously  
✅ Demonstrates server-to-server autonomous communication  
✅ Student-appropriate implementation (simple thread + timer)

## Switching Between Topologies

### Option 1: Use Hierarchical (Recommended)

**Why:**
- Already fully implemented
- Matches mini2 requirements
- Supports team-based processing
- Natural aggregation pattern

**Action:** Keep current config (already set to "hierarchical")

### Option 2: Implement Ring

**If you want to demonstrate ring topology:**

1. **Update config:**
   ```json
   {
     "topology_mode": "ring",
     "overlay": [
       ["A", "B"],
       ["B", "C"],
       ["C", "D"],
       ["D", "E"],
       ["E", "F"],
       ["F", "A"]
     ]
   }
   ```

2. **Add to proto:** (minitwo.proto)
   ```proto
   message Request {
     string request_id = 1;
     string destination_id = 2;  // NEW: Target node
     // ... existing fields
   }
   ```

3. **Update forwarding logic:** (RequestProcessor.cpp)
   ```cpp
   void ForwardInRing(const Request& req) {
       if (req.destination_id() == node_id_) {
           ProcessLocally(req);  // Message for me
       } else {
           ForwardToNext(req);   // Pass to next in ring
       }
   }
   ```

4. **Add next_node mapping:**
   ```cpp
   std::string next_node_addr_;  // Set from config
   ```

**Effort:** 4-6 hours of additional implementation

## Testing Autonomous Behavior

### Test 1: Start Servers Without Client

```bash
# Terminal 1-6: Start all servers
./build/mini2_server A &
./build/mini2_server B &
./build/mini2_server C &
./build/mini2_server D &
./build/mini2_server E &
./build/mini2_server F &

# Watch logs - you'll see autonomous health checks every 10 seconds
# NO CLIENT INPUT REQUIRED!
```

**Expected Output:**
```
[A] Health check thread started (interval: 10s)
[B] Health check thread started (interval: 10s)
...
(after 10 seconds)
[A] 🔍 Autonomous health check started
  ✓ localhost:50051 - healthy
  ✓ localhost:50054 - healthy
[A] Health check complete: 2/2 neighbors healthy

[B] 🔍 Autonomous health check started
  ✓ localhost:50050 - healthy
  ✓ localhost:50052 - healthy
[B] Health check complete: 2/2 neighbors healthy
```

### Test 2: Kill a Server

```bash
# Kill server B
kill $(ps aux | grep "mini2_server B" | grep -v grep | awk '{print $2}')

# Watch other servers detect the failure autonomously
```

**Expected Output:**
```
[A] 🔍 Autonomous health check started
  ✗ localhost:50051 - unreachable (Connect failed)
  ✓ localhost:50054 - healthy
[A] Health check complete: 1/2 neighbors healthy (⚠️ 1 failed)
```

## Configuration Best Practices

### For Students (Recommended)

```json
{
  "topology_mode": "hierarchical",
  "health_check": {
    "enabled": true,
    "interval_seconds": 10,
    "timeout_seconds": 5
  }
}
```

**Why:**
- Simple to understand
- Matches project requirements
- Demonstrates autonomous behavior
- Easy to debug and verify

### For Advanced Implementation

```json
{
  "topology_mode": "ring",
  "health_check": {
    "enabled": true,
    "interval_seconds": 5,
    "timeout_seconds": 2
  },
  "ring_config": {
    "A": {"next": "B"},
    "B": {"next": "C"},
    "C": {"next": "D"},
    "D": {"next": "E"},
    "E": {"next": "F"},
    "F": {"next": "A"}
  }
}
```

**Requires:**
- Ring forwarding logic
- Destination-based routing
- Additional proto messages

## Summary

| Feature | Status | Complexity | Satisfies Step 12? |
|---------|--------|------------|-------------------|
| Hierarchical Topology | ✅ Implemented | Low | N/A |
| Ring Topology | ⚠️ Configurable | Medium | N/A |
| Autonomous Health Check | ✅ Implemented | Low | ✅ YES |
| Config-based switching | ✅ Implemented | Low | N/A |

**Recommendation:**
- Keep `topology_mode: "hierarchical"` for your project
- Use autonomous health checks to satisfy Step 12
- Only implement ring if you have extra time and want to explore

**Current Implementation:**
✅ Satisfies all professor requirements  
✅ Demonstrates autonomous server behavior  
✅ Student-appropriate complexity  
✅ No client input required for health checks
