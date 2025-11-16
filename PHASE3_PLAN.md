# Phase 3: Chunking Strategies - Implementation Plan

## Overview

Phase 3 implements two different strategies for returning large result sets to clients:

- **Strategy A**: Return all chunks at once (RequestOnce) - **ALREADY WORKING!**
- **Strategy B**: Progressive chunking (StartRequest + GetNext/PollNext)

**Goal**: Compare performance, memory usage, and latency between strategies.

---

## Strategy A: All Chunks at Once ✅ (ALREADY DONE!)

### Current Implementation:
```cpp
Status RequestOnce(Request) returns (AggregatedResult)
  - AggregatedResult contains: repeated bytes chunks
  - All data returned in single RPC call
```

**Status**: ✅ Working in Phase 2!
- Client calls `RequestOnce`
- Gets all chunks immediately: `chunks: [chunk0, chunk1, chunk2, chunk3]`
- Total time: ~14-21ms

**Advantages**:
- ✅ Simple - one RPC call
- ✅ Low latency for small datasets
- ✅ No session management needed

**Disadvantages**:
- ❌ High memory usage (all data in memory)
- ❌ High initial latency (wait for all data)
- ❌ Not suitable for very large datasets

---

## Strategy B: Progressive Chunking (TO IMPLEMENT)

### Architecture:
```
Client → A: StartRequest(query)
      ← A: SessionOpen(request_id="session-123")
      
Client → A: GetNext(request_id, next_index=0)
      ← A: NextChunkResp(chunk=data0, has_more=true)
      
Client → A: GetNext(request_id, next_index=1)
      ← A: NextChunkResp(chunk=data1, has_more=true)
      
... repeat until has_more=false
```

**OR using PollNext (non-blocking)**:
```
Client → A: StartRequest(query)
      ← A: SessionOpen(request_id="session-123")
      
Client → A: PollNext(request_id)
      ← A: PollResp(ready=false, has_more=true)
      
... wait a bit ...

Client → A: PollNext(request_id)
      ← A: PollResp(ready=true, chunk=data0, has_more=true)
```

**Advantages**:
- ✅ Lower memory usage (stream chunks)
- ✅ Faster time to first chunk
- ✅ Can handle very large datasets
- ✅ Client can cancel mid-stream

**Disadvantages**:
- ❌ More complex (session management)
- ❌ More RPC calls (higher overhead)
- ❌ Need to handle abandoned sessions

---

## Implementation Steps

### Step 1: Create SessionManager

Create `src/cpp/server/SessionManager.h`:
```cpp
class SessionManager {
public:
    // Create new session, return session ID
    std::string CreateSession(const mini2::Request& req);
    
    // Add chunk to session
    void AddChunk(const std::string& session_id, const mini2::WorkerResult& result);
    
    // Get next chunk (blocking until available)
    bool GetNextChunk(const std::string& session_id, uint32_t index, 
                      mini2::NextChunkResp* resp);
    
    // Poll for next chunk (non-blocking)
    bool PollNextChunk(const std::string& session_id, 
                       mini2::PollResp* resp);
    
    // Mark session complete
    void CompleteSession(const std::string& session_id);
    
    // Cleanup old sessions
    void CleanupSession(const std::string& session_id);

private:
    struct Session {
        std::string request_id;
        std::vector<mini2::WorkerResult> chunks;
        bool complete = false;
        uint32_t next_index = 0;
        std::chrono::steady_clock::time_point created_at;
        std::mutex mutex;
    };
    
    std::map<std::string, Session> sessions_;
    std::mutex sessions_mutex_;
};
```

### Step 2: Update ClientGatewayService

Modify `src/cpp/server/Handlers.cpp`:

```cpp
class ClientGatewayService final : public mini2::ClientGateway::Service {
private:
    std::shared_ptr<RequestProcessor> processor_;
    std::shared_ptr<SessionManager> session_manager_;
    
public:
    ClientGatewayService(std::shared_ptr<RequestProcessor> processor,
                         std::shared_ptr<SessionManager> session_mgr) 
        : processor_(processor), session_manager_(session_mgr) {}
    
    // Strategy A: All at once (already working)
    Status RequestOnce(ServerContext*, const Request* req, AggregatedResult* out) override {
        *out = processor_->ProcessRequestOnce(*req);
        return Status::OK;
    }
    
    // Strategy B: Start session
    Status StartRequest(ServerContext*, const Request* req, SessionOpen* out) override {
        std::string session_id = session_manager_->CreateSession(*req);
        out->set_request_id(session_id);
        
        // Start processing in background (thread)
        std::thread([this, session_id, req]() {
            auto result = processor_->ProcessRequestOnce(*req);
            // Add each chunk to session
            for (int i = 0; i < result.chunks_size(); i++) {
                mini2::WorkerResult wr;
                wr.set_request_id(session_id);
                wr.set_part_index(i);
                wr.set_payload(result.chunks(i));
                session_manager_->AddChunk(session_id, wr);
            }
            session_manager_->CompleteSession(session_id);
        }).detach();
        
        return Status::OK;
    }
    
    // Strategy B: Get next chunk (blocking)
    Status GetNext(ServerContext*, const NextChunkReq* req, NextChunkResp* resp) override {
        bool has_chunk = session_manager_->GetNextChunk(
            req->request_id(), req->next_index(), resp);
        
        if (!has_chunk) {
            resp->set_has_more(false);
        }
        
        return Status::OK;
    }
    
    // Strategy B: Poll for next chunk (non-blocking)
    Status PollNext(ServerContext*, const PollReq* req, PollResp* resp) override {
        bool success = session_manager_->PollNextChunk(req->request_id(), resp);
        
        if (!success) {
            resp->set_ready(false);
            resp->set_has_more(false);
        }
        
        return Status::OK;
    }
};
```

### Step 3: Update Client for Strategy B

Create new test modes in `src/cpp/client/ClientMain.cpp`:

```cpp
// Test Strategy B with GetNext (sequential pull)
void testStrategyB_GetNext(const std::string& gateway) {
    auto channel = grpc::CreateChannel(gateway, grpc::InsecureChannelCredentials());
    auto stub = mini2::ClientGateway::NewStub(channel);
    
    // Start request
    grpc::ClientContext ctx1;
    mini2::Request req;
    req.set_request_id("test-strategyB-001");
    req.set_query("SELECT * FROM data");
    req.set_need_green(true);
    req.set_need_pink(true);
    
    mini2::SessionOpen session;
    auto status = stub->StartRequest(&ctx1, req, &session);
    
    if (!status.ok()) {
        std::cerr << "StartRequest failed" << std::endl;
        return;
    }
    
    std::cout << "Session started: " << session.request_id() << std::endl;
    
    // Get chunks one by one
    uint32_t index = 0;
    uint64_t total_bytes = 0;
    auto start = std::chrono::high_resolution_clock::now();
    
    while (true) {
        grpc::ClientContext ctx2;
        mini2::NextChunkReq next_req;
        next_req.set_request_id(session.request_id());
        next_req.set_next_index(index);
        
        mini2::NextChunkResp resp;
        status = stub->GetNext(&ctx2, next_req, &resp);
        
        if (!status.ok() || !resp.has_more()) {
            break;
        }
        
        total_bytes += resp.chunk().size();
        std::cout << "Received chunk " << index 
                  << " (" << resp.chunk().size() << " bytes)" << std::endl;
        index++;
    }
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    std::cout << "\nStrategy B (GetNext) Results:" << std::endl;
    std::cout << "  Total chunks: " << index << std::endl;
    std::cout << "  Total bytes: " << total_bytes << std::endl;
    std::cout << "  Total time: " << duration.count() << " ms" << std::endl;
}
```

---

## Testing Plan

### Test 1: Compare Strategies with Small Data
```bash
# Strategy A (already working)
./mini2_client --mode request

# Strategy B (to implement)
./mini2_client --mode strategy-b-getnext
```

**Expected**:
- Strategy A: ~14ms total, all chunks at once
- Strategy B: ~20ms total (more RPC calls), incremental chunks

### Test 2: Compare with Larger Data

Increase mock data size to 10KB per worker:
```cpp
// In GenerateMockData, increase loop from 100 to 10000
for (int i = 0; i < 10000; i++) {
    ss << i * part_index << ",";
}
```

**Expected**:
- Strategy A: Higher memory, longer initial wait
- Strategy B: Lower memory, faster time to first chunk

### Test 3: Concurrent Clients (Fairness)

Run 2 clients simultaneously:
- Client 1: Large request (both teams)
- Client 2: Small request (green only)

**Measure**: Does Client 2 get starved?

---

## Performance Metrics to Record

| Metric | Strategy A | Strategy B |
|--------|-----------|-----------|
| Time to First Chunk | N/A (all at once) | ? ms |
| Total Time | 14-21 ms | ? ms |
| Total RPC Calls | 1 | 1 + N (N=chunks) |
| Memory at Process A | High | Low |
| Memory at Client | High | Low |
| Suitable for Large Data | No | Yes |

---

## Next Steps

1. **Implement SessionManager** (Step 1)
2. **Update Handlers** (Step 2)
3. **Update Client** (Step 3)
4. **Test Both Strategies**
5. **Compare Performance**
6. **Document Findings**

---

**Ready to start?** I'll begin implementing SessionManager and Strategy B! 🚀
