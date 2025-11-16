# Quick Reference: Answers to Your Architecture Questions

## Your Questions & Answers

### 1. **What if the client wants to exit and there are still pending messages?**

**Answer:** Your current system has a **memory leak risk**. Sessions stay in memory forever.

**Fix:** Implement session timeout cleanup (see `example_session_cleanup_implementation.cpp`)
- Background thread checks for stale sessions every 60 seconds
- Sessions inactive for 5+ minutes get automatically removed
- Prevents memory leaks when clients disconnect unexpectedly

---

### 2. **Save it to disk? What if client starts on different host?**

**Answer:** Your system has **NO persistence** - everything is in-memory only.

**Current Behavior:**
- Client exits → Session data lost forever
- Server restarts → All sessions lost
- Client switches hosts → Cannot resume

**For Student Project:**
- **Option A (Recommended):** Keep in-memory only, rely on session timeout
- **Option B (Advanced):** Add file-based session persistence
  - Save sessions to `./sessions/session-id.dat`
  - Client can reconnect with session ID from any host
  - Use shared storage (NFS/network drive) for true cross-host support

**Practical:** Most real systems (like HTTP sessions) also timeout without disk persistence. This is acceptable for a student project.

---

### 3. **How does a client know the message was received (accepted)?**

**Answer:** Your `HeartbeatAck` is **too simple** - just returns `bool ok`.

**Current Problem:**
```cpp
mini2::HeartbeatAck ack;
stub->StartRequest(&ctx, req, &session);
// Only knows RPC succeeded, not if server actually accepted it
```

**Better Approach:**
```proto
message RequestAck {
    bool accepted = 1;
    string request_id = 2;
    string status = 3;  // "QUEUED", "PROCESSING", "COMPLETED", "FAILED"
    string error_message = 4;
}
```

Client can then check:
```cpp
mini2::RequestAck ack;
stub->StartRequest(&ctx, req, &ack);
if (ack.accepted() && ack.status() == "QUEUED") {
    // Definitely accepted!
}
```

---

### 4. **If message not accepted, does client retain and resend?**

**Answer:** Your system has **NO retry logic**.

**Current Behavior:**
- Request fails → Client gives up immediately
- Network glitch → Request lost
- Server busy → Request rejected permanently

**Fix:** Add client-side retry with exponential backoff (see `example_client_retry_logic.h`)

```cpp
ReliableClient client("localhost:50050");

mini2::Request req;
req.set_request_id("my-request");
req.set_query("data.csv");

// Automatically retries up to 3 times with backoff
if (client.SendRequestWithRetry(req)) {
    std::cout << "Success!" << std::endl;
} else {
    std::cerr << "Failed after retries" << std::endl;
}
```

**Retry Pattern:**
- Attempt 1: immediate
- Attempt 2: wait 2 seconds
- Attempt 3: wait 4 seconds
- Attempt 4: wait 8 seconds (exponential backoff)

---

### 5. **How does a client receive a reply?**

**Answer:** You **ALREADY SOLVED THIS** correctly! ✓

**Your Two Approaches:**

**Strategy A: Synchronous (RequestOnce)**
```cpp
mini2::AggregatedResult result;
stub->RequestOnce(&ctx, req, &result);
// Blocks until all data ready, returns everything at once
```

**Strategy B: Asynchronous (GetNext/PollNext)**
```cpp
// Client pulls chunks on demand
while (has_more) {
    stub->GetNext(&ctx, next_req, &resp);
    process(resp.chunk());
}
```

**Why this works:**
- ✓ Client initiates all calls (no server callbacks needed)
- ✓ Works through firewalls/NAT
- ✓ Client controls polling rate
- ✓ No timeout issues (client decides when to pull)

---

### 6. **Callbacks? Not likely. One word: firewalls**

**Answer:** You're **100% correct** to avoid callbacks!

**Why Callbacks Fail:**

```
Client (behind NAT/Firewall)
  |
  | Can call OUT to server ✓
  +-------------------------> Server
  
  | Server CANNOT call IN ✗
  X <----------------------- Server
     (Blocked by firewall)
```

**Your Solution (Pull-Based):**
```
Client controls everything:

  GetNext() ---------> Server (returns data)
  GetNext() ---------> Server (returns data)
  GetNext() ---------> Server (returns data)
  
All connections initiated by client ✓
```

**This is the RIGHT approach!** Used by:
- HTTP long polling
- gRPC client streaming
- Webhooks (but with pull, not push)

---

## Implementation Priority (For Student Project)

### Critical (Must Implement):
1. ✅ **Session Timeout** - Prevents memory leaks
   - See: `example_session_cleanup_implementation.cpp`
   - Impact: High (prevents memory issues)
   - Effort: Low (1-2 hours)

2. ✅ **Better Acknowledgment** - Know if request accepted
   - Replace `HeartbeatAck` with proper `RequestAck`
   - Impact: Medium (better error handling)
   - Effort: Low (1 hour)

### Important (Should Implement):
3. **Client Retry Logic** - Handle transient failures
   - See: `example_client_retry_logic.h`
   - Impact: High (system reliability)
   - Effort: Medium (2-3 hours)

### Optional (Nice to Have):
4. **Session Recovery** - Client reconnection
   - Allow client to reconnect with session ID
   - Impact: Medium (better UX)
   - Effort: Medium (2-3 hours)

5. **Disk Persistence** - Survive server restarts
   - Save sessions to disk files
   - Impact: Low (most systems don't need this)
   - Effort: High (4-6 hours)

---

## What You're Already Doing Right ✓

1. **Pull-based communication** - Perfect for firewalls
2. **Two strategies** - RequestOnce for small data, GetNext for large data
3. **Session management** - Allows asynchronous processing
4. **gRPC** - Modern, efficient, widely used

---

## Simple Grading Checklist

If your professor asks these questions:

| Question | Your Answer | Evidence |
|----------|-------------|----------|
| What if client exits? | "Session timeout cleanup removes stale sessions" | Show cleanup thread code |
| Need disk persistence? | "No - sessions timeout after 5 min like HTTP sessions" | Show timeout logic |
| How know message accepted? | "RequestAck message with status field" | Show proto definition |
| Client retry logic? | "Exponential backoff retry (3 attempts)" | Show retry code |
| How get reply? | "Pull-based: client calls GetNext repeatedly" | Show existing code |
| Why no callbacks? | "Firewalls block inbound. Client initiates all calls" | Explain architecture |

---

## File Reference

- **Analysis Document:** `architecture_questions_analysis.md`
- **Session Cleanup Example:** `example_session_cleanup_implementation.cpp`
- **Client Retry Example:** `example_client_retry_logic.h`
- **Improved SessionManager:** `example_improved_session_manager.h`

All files are in `/Users/spartan/Desktop/CMPE275/mini_2/docs/`
