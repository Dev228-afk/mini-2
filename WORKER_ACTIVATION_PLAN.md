# Option 2: Activating Real Workers (C, D, F)

## Current Problem

**Team leaders (B, E) are generating data themselves instead of forwarding to workers.**

Workers C, D, F are idle because:
1. Team leaders don't forward requests to them
2. Team leaders generate mock data locally

---

## What Needs to Change

### 1. Team Leaders Must Forward to Workers

**Process B** should forward to **Process C**:
```cpp
// In HandleTeamRequest() for node B:
// Instead of: GenerateMockData() locally
// Do: Forward request to worker C via RPC
```

**Process E** should forward to **Process F**:
```cpp
// In HandleTeamRequest() for node E:
// Instead of: GenerateMockData() locally
// Do: Forward request to worker F via RPC
```

**Process D**: Currently configured as TEAM_LEADER but not used
- Option A: Keep D as backup team leader (not forwarded to)
- Option B: Change D to WORKER and have it process data

---

## Implementation Plan

### Step 1: Add Worker Connections to Team Leaders

In `RequestProcessor.h`, add:
```cpp
void SetWorkers(const std::vector<std::string>& worker_addresses);

private:
    std::map<std::string, std::unique_ptr<mini2::TeamIngress::Stub>> worker_stubs_;
```

### Step 2: Update ServerMain.cpp

```cpp
if (node_id == "B") {
    // B: Green team leader
    processor->SetLeaderAddress("localhost:50050");  // Connect to A
    processor->SetWorkers({"localhost:50052"});       // Connect to C
}
else if (node_id == "E") {
    // E: Pink team leader
    processor->SetLeaderAddress("localhost:50050");  // Connect to A
    processor->SetWorkers({"localhost:50055"});       // Connect to F
}
```

### Step 3: Modify HandleTeamRequest

```cpp
void RequestProcessor::HandleTeamRequest(const mini2::Request& req) {
    std::cout << "[TeamLeader " << node_id_ << "] Handling request: " << req.request_id() << std::endl;

    if (worker_stubs_.empty()) {
        // No workers configured, generate data locally (Phase 2 behavior)
        std::cout << "[TeamLeader " << node_id_ << "] No workers, generating locally..." << std::endl;
        for (uint32_t i = 0; i < 2; i++) {
            auto worker_result = GenerateMockData(req.request_id(), i);
            ReceiveWorkerResult(worker_result);
        }
    } else {
        // Forward to workers (Phase 3 behavior)
        std::cout << "[TeamLeader " << node_id_ << "] Forwarding to " << worker_stubs_.size() << " worker(s)..." << std::endl;
        for (auto& [addr, stub] : worker_stubs_) {
            ClientContext ctx;
            mini2::HeartbeatAck ack;
            Status status = stub->HandleRequest(&ctx, req, &ack);
            if (status.ok()) {
                std::cout << "[TeamLeader " << node_id_ << "] ✓ Forwarded to worker: " << addr << std::endl;
            } else {
                std::cerr << "[TeamLeader " << node_id_ << "] ✗ Failed to forward to worker: " 
                         << status.error_message() << std::endl;
            }
        }
    }

    // Wait for worker results (would be async in real implementation)
    std::this_thread::sleep_for(std::chrono::milliseconds(5));

    // Aggregate and send back to leader...
}
```

### Step 4: Workers Process Requests

Workers (C, F) need to implement:
```cpp
void RequestProcessor::HandleWorkerRequest(const mini2::Request& req) {
    std::cout << "[Worker " << node_id_ << "] Processing request: " << req.request_id() << std::endl;
    
    // Generate data
    auto result = GenerateMockData(req.request_id(), 0);
    
    // Send back to team leader
    if (leader_stub_) {
        ClientContext ctx;
        mini2::HeartbeatAck ack;
        Status status = leader_stub_->PushWorkerResult(&ctx, result, &ack);
        if (status.ok()) {
            std::cout << "[Worker " << node_id_ << "] ✓ Sent result to team leader" << std::endl;
        }
    }
}
```

---

## Recommended Approach

### For NOW (Phase 2 Complete):
**✅ Keep current behavior - workers idle**
- You've already proven Phase 2 works
- Move to Phase 3 (chunking strategies)
- Come back to activate workers later if needed

### For Phase 3 (Real Workers):
**🔜 Activate workers when implementing real data processing**
- Replace mock data with fire dataset
- Have workers actually process partitions
- Measure real distributed performance

---

## Summary

**Workers C, D, F being idle is NORMAL for Phase 2.**

Your options:
1. ✅ **Accept current behavior** (recommended) - Phase 2 is complete!
2. 🔧 **Activate workers now** - I can implement the changes above
3. ⏳ **Wait for Phase 3** - Activate workers when using real data

**What do you prefer?**
