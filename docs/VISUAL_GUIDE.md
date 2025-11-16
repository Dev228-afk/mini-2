# Visual Architecture Guide

## Current vs Improved Architecture

### Problem 1: Client Exit with Pending Data

**BEFORE (Current):**
```
Client                    Server
  |                         |
  | StartRequest()          |
  +-----------------------> | Creates session in memory
  |                         | Session{chunks: [], complete: false}
  |                         |
  | <Client Exits>          |
  X                         | Session still in memory!
                            | Chunks keep arriving...
                            | Memory leak! ❌
```

**AFTER (With Timeout):**
```
Client                    Server (with cleanup thread)
  |                         |
  | StartRequest()          |
  +-----------------------> | Creates session
  |                         | last_access = now
  |                         |
  | <Client Exits>          |
  X                         |
                            | [Background thread runs every 60s]
                            | if (now - last_access > 5 min)
                            |   remove session ✓
                            | Memory freed! ✓
```

---

### Problem 2: Message Acknowledgment

**BEFORE (Weak):**
```
Client                    Server
  |                         |
  | StartRequest()          |
  +-----------------------> | (process)
  |                         |
  | HeartbeatAck{ok=true}   |
  | <---------------------- |
  |                         |
  | ❓ Was it really accepted?
  | ❓ Is it queued or processing?
  | ❓ What if server is overloaded?
```

**AFTER (Strong):**
```
Client                    Server
  |                         |
  | StartRequest()          |
  +-----------------------> | (validate & queue)
  |                         |
  | RequestAck{             |
  |   accepted: true,       |
  |   request_id: "123",    |
  |   status: "QUEUED",     |
  |   timestamp: 1699...    |
  | }                       |
  | <---------------------- |
  |                         |
  ✓ Definitely accepted!
  ✓ Know it's queued
  ✓ Can track progress
```

---

### Problem 3: Request Retry

**BEFORE (No Retry):**
```
Client                    Server
  |                         |
  | StartRequest()          |
  +--------X  (network glitch)
  |
  ❌ Request lost forever
```

**AFTER (With Retry):**
```
Client                    Server
  |                         |
  | StartRequest()          |
  +--------X  (fail)        |
  |                         |
  | [wait 2 sec]            |
  |                         |
  | StartRequest() (retry)  |
  +--------X  (fail)        |
  |                         |
  | [wait 4 sec]            |
  |                         |
  | StartRequest() (retry)  |
  +-----------------------> |
  |                         |
  | SessionOpen{id: "xyz"}  |
  | <---------------------- |
  |                         |
  ✓ Success on retry #3!
```

---

### Problem 4: Firewall Traversal (Why No Callbacks)

**WRONG APPROACH (Callbacks):**
```
Client (behind NAT/Firewall)        Server (public)
[192.168.1.100]                     [public IP]
        |                               |
        | StartRequest()                |
        +-----------------------------> |
        |                               |
        | "I'll call you back at        |
        | 192.168.1.100:8080"           |
        | <---------------------------- |
        |                               |
        |        X                      |
        |   (Firewall blocks inbound)   |
        | <---X------------------------ |
        |                               |
        ❌ Callback fails!
```

**CORRECT APPROACH (Pull-Based):**
```
Client (behind NAT/Firewall)        Server (public)
[192.168.1.100]                     [public IP]
        |                               |
        | StartRequest()                |
        +-----------------------------> |
        |   Session created             |
        | <---------------------------- |
        |                               |
        | GetNext(index=0)              |
        +-----------------------------> |
        |   Chunk 0                     |
        | <---------------------------- |
        |                               |
        | GetNext(index=1)              |
        +-----------------------------> |
        |   Chunk 1                     |
        | <---------------------------- |
        |                               |
        ✓ All connections client-initiated!
        ✓ Firewall allows outbound!
```

---

## Session Lifecycle

```
+------------------+
| Client           |
+------------------+
        |
        | 1. StartRequest()
        v
+------------------+
| Server:          |
| Create Session   |
| session-123456   |
+------------------+
        |
        | 2. Process data
        | (async workers)
        v
+------------------+
| Server:          |
| Session          |
|   chunks: [...]  |
|   complete: F    |
+------------------+
        ^
        | 3. Client polls
        |    GetNext(index=0)
        |    GetNext(index=1)
        |    ...
        |
+------------------+
| Client           |
| Retrieving...    |
+------------------+

TWO PATHS:

Path A: Normal Completion
        |
        v
+------------------+
| All chunks       |
| retrieved        |
| complete: true   |
+------------------+
        |
        v
+------------------+
| Client calls     |
| CloseSession()   |
| OR session       |
| times out        |
+------------------+

Path B: Client Crashes
        |
        v
+------------------+
| Client exits     |
| (no more polls)  |
+------------------+
        |
        | [5 minutes pass]
        v
+------------------+
| Cleanup thread   |
| detects stale    |
| session          |
+------------------+
        |
        v
+------------------+
| Session removed  |
| Memory freed ✓   |
+------------------+
```

---

## Request Tracking State Machine

```
Client Side:

    [New Request]
          |
          v
    +-------------+
    | TRACKING    |
    | ack: false  |
    | retry: 0    |
    +-------------+
          |
          | Send()
          v
    +-------------+      Success
    | SENT        | ----------------> [ACKNOWLEDGED]
    | ack: false  |                   (Done!)
    | retry: 0    |
    +-------------+
          |
          | Failure
          v
    +-------------+
    | RETRY       |
    | ack: false  |
    | retry: 1    |
    +-------------+
          |
          | Wait + Send()
          v
    +-------------+      Success
    | SENT        | ----------------> [ACKNOWLEDGED]
    | retry: 1    |
    +-------------+
          |
          | Failure
          v
    +-------------+
    | RETRY       |
    | retry: 2    |
    +-------------+
          |
          | Wait + Send()
          v
          .
          .
          . (max 3 attempts)
          .
          v
    +-------------+
    | FAILED      |
    | retry: 3    |
    +-------------+
       (Give up)
```

---

## Data Flow: Strategy B (GetNext)

```
Timeline View:

Client                          Gateway (A)                Workers (B,C,D,E,F)
  |                                |                              |
  | StartRequest(need_green,       |                              |
  |              need_pink)        |                              |
  +------------------------------> |                              |
  |                                | Distribute work              |
  |                                +----------------------------> |
  |                                |                              | Process
  |     SessionOpen{id}            |                              | chunks
  | <------------------------------+                              |
  |                                |                              |
  | [Client can do other work]     |      WorkerResult            |
  |                                | <----------------------------+
  |                                | Store in session             |
  |                                |                              |
  | GetNext(index=0)               |                              |
  +------------------------------> |                              |
  |     Chunk 0                    |                              |
  | <------------------------------+                              |
  |                                |      WorkerResult            |
  |                                | <----------------------------+
  | [Process chunk 0]              | Store in session             |
  |                                |                              |
  | GetNext(index=1)               |                              |
  +------------------------------> |                              |
  |     Chunk 1                    |                              |
  | <------------------------------+                              |
  |                                |      WorkerResult            |
  | [Process chunk 1]              | <----------------------------+
  |                                |                              |
  | GetNext(index=2)               |                              |
  +------------------------------> |                              |
  |     Chunk 2 + has_more=false   |                              |
  | <------------------------------+                              |
  |                                |                              |
  | [All done!]                    | [Session ready for cleanup]  |
  |                                |                              |

Key Points:
- Client controls polling rate
- Server buffers chunks in session
- No callbacks needed
- Firewall-friendly (all outbound)
```

---

## Memory Management: Before vs After

**BEFORE:**
```
Server Memory:

Session Map: {
  "session-001": Session{chunks: [50MB], last_access: 2 hours ago},
  "session-002": Session{chunks: [100MB], last_access: 5 hours ago},
  "session-003": Session{chunks: [75MB], last_access: 10 hours ago},
  ...
}

Total: 225MB of stale data ❌
```

**AFTER (With Cleanup):**
```
Server Memory:

Session Map: {
  "session-042": Session{chunks: [30MB], last_access: 2 min ago},  ✓ Active
  "session-043": Session{chunks: [45MB], last_access: 30 sec ago}, ✓ Active
}

[Cleanup thread runs]
- session-001: 2 hours > 5 min → REMOVE
- session-002: 5 hours > 5 min → REMOVE
- session-003: 10 hours > 5 min → REMOVE

Total: 75MB (only active sessions) ✓
Memory savings: 150MB freed!
```

---

## Summary: Key Architectural Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **Pull-based (GetNext)** | Works through firewalls | Client must poll |
| **Session timeout** | Prevents memory leaks | May lose data if client slow |
| **Client-side retry** | Handle transient failures | Duplicate detection needed |
| **No disk persistence** | Simpler, faster | Lost on server restart |
| **In-memory sessions** | Low latency | Limited by RAM |

All decisions appropriate for a **student distributed systems project**! ✓
