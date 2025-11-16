# Architecture Analysis: Handling Client Exit & Message Reliability

## Current Architecture Overview

Your system uses:
- **Strategy A (RequestOnce)**: Synchronous - client blocks until all results arrive
- **Strategy B (GetNext/PollNext)**: Asynchronous - client pulls chunks on demand
- **Sessions**: Server maintains session state with chunks in memory
- **No persistence**: All data lives in memory only
- **No acknowledgment tracking**: HeartbeatAck just returns boolean

---

## Question 1: What if the client wants to exit and there are still pending messages?

### Current State: **PROBLEM**
```cpp
// In SessionManager.cpp - data only in memory
Session& session = it->second;
session.chunks.push_back(result);  // Lost if client exits!
```

**Issue**: If client exits during Strategy B (GetNext), server keeps working and storing chunks in memory that nobody will retrieve.

### Solution Options (Student-Level):

**Option A: Session Timeout (Simple - Recommended)**
```cpp
// Add to SessionManager.h
struct Session {
    std::chrono::steady_clock::time_point last_access;
    std::chrono::seconds timeout_duration{300};  // 5 minutes
    // ... existing fields
};

// Add periodic cleanup
void SessionManager::CleanupStaleSession() {
    auto now = std::chrono::steady_clock::now();
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    
    for (auto it = sessions_.begin(); it != sessions_.end(); ) {
        auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
            now - it->second.last_access);
        
        if (elapsed > it->second.timeout_duration) {
            std::cout << "[SessionManager] Cleaning up stale session: " 
                      << it->first << std::endl;
            it = sessions_.erase(it);
        } else {
            ++it;
        }
    }
}
```

**Option B: Explicit Close Session**
```proto
// Add to minitwo.proto
message CloseSessionReq { string session_id = 1; }
message CloseSessionResp { bool success = 1; }

service ClientGateway {
    // ... existing RPCs
    rpc CloseSession(CloseSessionReq) returns (CloseSessionResp);
}
```

---

## Question 2: Save it to disk? What if client starts on different host?

### Current State: **NO PERSISTENCE**

Your system has NO disk persistence. Everything is in-memory only.

### Solution: Session Persistence (Student-Level)

**Simple File-Based Approach:**
```cpp
// Add to SessionManager.h
class SessionManager {
private:
    std::string persistence_dir_ = "./sessions";
    
    void SaveSessionToDisk(const std::string& session_id);
    bool LoadSessionFromDisk(const std::string& session_id);
};

// Implementation
void SessionManager::SaveSessionToDisk(const std::string& session_id) {
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    auto it = sessions_.find(session_id);
    if (it == sessions_.end()) return;
    
    std::string filepath = persistence_dir_ + "/" + session_id + ".dat";
    std::ofstream file(filepath, std::ios::binary);
    
    // Write session metadata
    file.write(session_id.c_str(), session_id.size());
    
    // Write number of chunks
    uint32_t chunk_count = it->second.chunks.size();
    file.write((char*)&chunk_count, sizeof(chunk_count));
    
    // Write each chunk
    for (const auto& chunk : it->second.chunks) {
        std::string serialized = chunk.SerializeAsString();
        uint32_t size = serialized.size();
        file.write((char*)&size, sizeof(size));
        file.write(serialized.c_str(), size);
    }
    
    file.close();
}
```

**For Cross-Host Access:**
- Use shared storage (NFS, S3, network drive)
- Session ID becomes the "ticket" - client can resume from any machine
- Add session recovery RPC:

```proto
message RecoverSessionReq { 
    string session_id = 1; 
    string client_host = 2;
}
message RecoverSessionResp { 
    bool success = 1; 
    uint32 available_chunks = 2;
}
```

---

## Question 3: How does a client know the message was received (accepted)?

### Current State: **WEAK ACKNOWLEDGMENT**

```cpp
// Current approach - just returns ok=true
mini2::HeartbeatAck ack;
auto status = stub->StartRequest(&ctx1, req, &session);
if (!status.ok()) {
    // Only knows about RPC failure, not processing failure
}
```

**Problems:**
- `HeartbeatAck` just has `bool ok` - no details
- Client doesn't know if server actually processed the request
- No sequence numbers for tracking

### Solution: Proper Acknowledgment (Student-Level)

**Update Proto:**
```proto
message RequestAck {
    bool accepted = 1;
    string request_id = 2;
    int64 timestamp_ms = 3;
    string status = 4;  // "QUEUED", "PROCESSING", "COMPLETED", "FAILED"
    string error_message = 5;  // If rejected
}

service ClientGateway {
    rpc StartRequest(Request) returns (RequestAck);  // Changed from SessionOpen
    // ... other RPCs
}
```

**Client-side tracking:**
```cpp
struct PendingRequest {
    std::string request_id;
    mini2::Request original_request;
    bool acknowledged = false;
    std::chrono::steady_clock::time_point sent_at;
    int retry_count = 0;
};

class ClientRequestTracker {
private:
    std::map<std::string, PendingRequest> pending_;
    std::mutex mutex_;
    
public:
    void TrackRequest(const std::string& id, const mini2::Request& req) {
        std::lock_guard<std::mutex> lock(mutex_);
        PendingRequest pr;
        pr.request_id = id;
        pr.original_request = req;
        pr.sent_at = std::chrono::steady_clock::now();
        pending_[id] = pr;
    }
    
    void MarkAcknowledged(const std::string& id) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_.count(id)) {
            pending_[id].acknowledged = true;
        }
    }
    
    std::vector<PendingRequest> GetUnacknowledged() {
        std::lock_guard<std::mutex> lock(mutex_);
        std::vector<PendingRequest> unacked;
        for (const auto& pair : pending_) {
            if (!pair.second.acknowledged) {
                unacked.push_back(pair.second);
            }
        }
        return unacked;
    }
};
```

---

## Question 4: If message was not accepted, does client retain & resend?

### Current State: **NO RETRY MECHANISM**

Your client sends once and hopes for the best. No retry logic.

### Solution: Client-Side Retry (Student-Level)

```cpp
class ReliableClient {
private:
    ClientRequestTracker tracker_;
    std::unique_ptr<mini2::ClientGateway::Stub> stub_;
    int max_retries_ = 3;
    std::chrono::seconds retry_delay_{5};
    
public:
    bool SendWithRetry(const mini2::Request& req) {
        std::string req_id = req.request_id();
        tracker_.TrackRequest(req_id, req);
        
        for (int attempt = 0; attempt < max_retries_; attempt++) {
            grpc::ClientContext ctx;
            mini2::RequestAck ack;
            
            auto status = stub_->StartRequest(&ctx, req, &ack);
            
            if (status.ok() && ack.accepted()) {
                std::cout << "[Client] Request " << req_id 
                          << " accepted on attempt " << (attempt + 1) << std::endl;
                tracker_.MarkAcknowledged(req_id);
                return true;
            }
            
            // Log failure
            std::cerr << "[Client] Attempt " << (attempt + 1) << " failed: ";
            if (!status.ok()) {
                std::cerr << status.error_message() << std::endl;
            } else {
                std::cerr << ack.error_message() << std::endl;
            }
            
            // Wait before retry (exponential backoff)
            if (attempt < max_retries_ - 1) {
                int delay_sec = retry_delay_.count() * (1 << attempt);  // 5, 10, 20 seconds
                std::cout << "[Client] Retrying in " << delay_sec << " seconds..." << std::endl;
                std::this_thread::sleep_for(std::chrono::seconds(delay_sec));
            }
        }
        
        std::cerr << "[Client] Request " << req_id << " failed after " 
                  << max_retries_ << " attempts" << std::endl;
        return false;
    }
};
```

---

## Question 5: How does client receive a reply?

### Current State: **ALREADY IMPLEMENTED** ✓

You have TWO working approaches:

**Approach 1: Synchronous (RequestOnce)**
```cpp
// Client blocks until complete
mini2::AggregatedResult result;
auto status = stub->RequestOnce(&ctx, req, &result);
// Result contains all chunks immediately
```

**Approach 2: Pull-Based (GetNext/PollNext)**
```cpp
// Client pulls chunks on demand
while (true) {
    mini2::NextChunkReq next_req;
    next_req.set_request_id(session_id);
    next_req.set_next_index(index);
    
    mini2::NextChunkResp resp;
    stub->GetNext(&ctx, next_req, &resp);
    
    if (!resp.has_more()) break;
    // Process resp.chunk()
}
```

**Both avoid callbacks and work through firewalls!** ✓

---

## Question 6: Callbacks? Firewalls?

### Why Callbacks Don't Work in Your System:

**Problem with Server-to-Client Callbacks:**
```
Client (behind NAT/Firewall) <--X-- Server
  |                                    |
  | Can initiate connection            |
  +---------------------------------> |
                                       |
  | Server CANNOT call back            |
  X <------------------------------- |
```

**Your Solution: PULL-BASED (Perfect!)**
```
Client initiates ALL calls:
  GetNext() -----> Server (returns chunk)
  GetNext() -----> Server (returns chunk)
  GetNext() -----> Server (returns chunk)
```

This works because:
- Client always initiates connection
- No inbound connections needed
- Firewall-friendly (only outbound HTTP/2)
- Client controls polling rate

---

## Recommended Implementation Priority (Student Project)

### Must Have (Phase 1):
1. **Session timeout/cleanup** - prevent memory leaks
2. **Proper acknowledgment messages** - replace HeartbeatAck with RequestAck
3. **Client request tracking** - know what's pending

### Should Have (Phase 2):
4. **Basic retry mechanism** - handle transient failures
5. **Session recovery** - allow client reconnection

### Nice to Have (Phase 3):
6. **Disk persistence** - survive server restarts
7. **Cross-host recovery** - client mobility

---

## Code Changes Summary

Your current architecture is actually pretty good! Main gaps:

| Issue | Current | Recommended Fix |
|-------|---------|-----------------|
| Client exit with pending data | Memory leak | Session timeout |
| Message acceptance | Weak (HeartbeatAck) | Proper RequestAck |
| Retry logic | None | Client-side retry with exponential backoff |
| Persistence | None | Optional: file-based session storage |
| Reply mechanism | ✓ Already works! | Keep current pull-based approach |
| Firewall traversal | ✓ Already works! | Keep client-initiated RPCs |

Your pull-based approach (GetNext/PollNext) is **exactly right** for avoiding callback/firewall issues!
