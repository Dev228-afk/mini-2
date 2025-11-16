# Missing Feature: Autonomous Server Behavior (Professor's Step 12)

## Problem
Your servers are 100% reactive - they only respond to external client RPCs. 
The professor asks: "How do you code servers to interact without external client input?"

## What's Missing

### 1. Periodic Heartbeat Between Servers
Currently: Heartbeat only when client calls Ping RPC
Should be: Servers autonomously ping neighbors every N seconds

### 2. Proactive Load Monitoring
Currently: Status only reported when requested
Should be: Servers detect overload and notify neighbors autonomously

### 3. Background Health Checks
Currently: No self-initiated health verification
Should be: Each server periodically checks if neighbors are alive

## Implementation Plan

### Option A: Simple Background Heartbeat (Recommended for Students)

**Add to RequestProcessor.h:**
```cpp
class RequestProcessor {
private:
    // Existing members...
    std::thread heartbeat_thread_;
    std::atomic<bool> heartbeat_running_;
    
public:
    void StartHeartbeatThread();
    void StopHeartbeatThread();
    
private:
    void HeartbeatThreadFunc();
};
```

**Add to RequestProcessor.cpp:**
```cpp
void RequestProcessor::StartHeartbeatThread() {
    heartbeat_running_ = true;
    heartbeat_thread_ = std::thread(&RequestProcessor::HeartbeatThreadFunc, this);
    std::cout << "[" << node_id_ << "] Heartbeat thread started" << std::endl;
}

void RequestProcessor::StopHeartbeatThread() {
    heartbeat_running_ = false;
    if (heartbeat_thread_.joinable()) {
        heartbeat_thread_.join();
    }
}

void RequestProcessor::HeartbeatThreadFunc() {
    while (heartbeat_running_) {
        // Sleep first (10 second interval)
        std::this_thread::sleep_for(std::chrono::seconds(10));
        
        if (!heartbeat_running_) break;
        
        // Send heartbeat to all connected neighbors
        std::cout << "[" << node_id_ << "] Sending autonomous heartbeats..." << std::endl;
        
        // Ping team leaders
        for (auto& [addr, stub] : team_leader_stubs_) {
            grpc::ClientContext ctx;
            mini2::Heartbeat hb;
            hb.set_from(node_id_);
            hb.set_ts_unix_ms(std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
            
            mini2::HeartbeatAck ack;
            auto status = stub->Ping(&ctx, hb, &ack);
            
            if (status.ok()) {
                std::cout << "[" << node_id_ << "] ✓ Heartbeat to " << addr << std::endl;
            } else {
                std::cerr << "[" << node_id_ << "] ✗ Heartbeat failed to " << addr 
                         << ": " << status.error_message() << std::endl;
            }
        }
        
        // Ping workers
        for (auto& [addr, stub] : worker_stubs_) {
            grpc::ClientContext ctx;
            mini2::Heartbeat hb;
            hb.set_from(node_id_);
            hb.set_ts_unix_ms(std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
            
            mini2::HeartbeatAck ack;
            stub->Ping(&ctx, hb, &ack);
        }
    }
    
    std::cout << "[" << node_id_ << "] Heartbeat thread stopped" << std::endl;
}
```

**Update Constructor/Destructor:**
```cpp
RequestProcessor::RequestProcessor(const std::string& nodeId) 
    : node_id_(nodeId)
    , shutting_down_(false)
    , requests_processed_(0)
    , heartbeat_running_(false)
    , start_time_(std::chrono::steady_clock::now()) {
    std::cout << "[RequestProcessor] Initialized for node " << nodeId << std::endl;
    StartHeartbeatThread();  // NEW: Start autonomous behavior
}

RequestProcessor::~RequestProcessor() {
    StopHeartbeatThread();  // NEW: Clean shutdown
    if (worker_queue_) {
        worker_queue_->Stop();
    }
}
```

### Option B: Proactive Load Monitoring (Advanced)

**Add to RequestProcessor.h:**
```cpp
class RequestProcessor {
private:
    std::thread monitor_thread_;
    std::atomic<bool> monitor_running_;
    
    void StartMonitorThread();
    void StopMonitorThread();
    void MonitorThreadFunc();
    void NotifyNeighborsOfLoad();
};
```

**Implementation:**
```cpp
void RequestProcessor::MonitorThreadFunc() {
    const int OVERLOAD_THRESHOLD = 10;
    
    while (monitor_running_) {
        std::this_thread::sleep_for(std::chrono::seconds(5));
        
        if (!monitor_running_) break;
        
        // Check queue size
        int queue_size = worker_queue_ ? worker_queue_->GetQueueSize() : 0;
        
        if (queue_size > OVERLOAD_THRESHOLD) {
            std::cout << "[" << node_id_ << "] ⚠️ OVERLOAD DETECTED (queue=" 
                     << queue_size << ")" << std::endl;
            NotifyNeighborsOfLoad();
        }
    }
}

void RequestProcessor::NotifyNeighborsOfLoad() {
    // Proactively broadcast status to neighbors
    for (auto& [addr, stub] : team_leader_stubs_) {
        grpc::ClientContext ctx;
        mini2::BroadcastMessage msg;
        msg.set_message_type("overload_warning");
        msg.set_from_node(node_id_);
        
        mini2::HeartbeatAck ack;
        stub->Broadcast(&ctx, msg, &ack);
    }
}
```

### Option C: Autonomous Data Synchronization

**Periodically sync state with ring neighbors:**
```cpp
void RequestProcessor::SyncThreadFunc() {
    while (sync_running_) {
        std::this_thread::sleep_for(std::chrono::seconds(30));
        
        if (!sync_running_) break;
        
        // Get my current status
        auto my_status = GetStatus();
        
        // Share with next node in ring
        if (next_node_stub_) {
            grpc::ClientContext ctx;
            mini2::StatusRequest req;
            req.set_from_node(node_id_);
            
            mini2::StatusResponse resp;
            auto status = next_node_stub_->GetStatus(&ctx, req, &resp);
            
            if (status.ok()) {
                std::cout << "[" << node_id_ << "] Sync with next node: " 
                         << resp.node_id() << " is " << resp.state() << std::endl;
            }
        }
    }
}
```

## Why This Matters

1. **Professor's Intent**: Tests understanding of autonomous distributed systems
2. **Real Systems**: Servers must self-monitor and coordinate without external triggers
3. **Fault Tolerance**: Autonomous heartbeats detect failures without waiting for client requests
4. **Load Balancing**: Proactive monitoring enables dynamic work redistribution

## Student-Friendly Implementation

**Start with Option A (heartbeat)** - it's simple and demonstrates the concept clearly:
- Minimal code changes
- Clear autonomous behavior
- Easy to debug and verify
- Shows servers talking without client input

## How to Test

1. Start all servers
2. Don't send any client requests
3. Watch server logs - you should see:
   ```
   [A] Sending autonomous heartbeats...
   [A] ✓ Heartbeat to localhost:50051
   [A] ✓ Heartbeat to localhost:50054
   [B] Received Ping from: A at 1234567890
   ```

This proves servers interact independently!
