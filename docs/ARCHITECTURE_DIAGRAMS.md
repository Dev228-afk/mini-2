# Network Architecture Diagrams

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENT                               │
│                    (mini2_client)                            │
└──────────────────────────┬──────────────────────────────────┘
                           │ gRPC
                           │ (ClientGateway service)
                           ↓
                    ┌──────────────┐
                    │   Process A  │ ← LEADER (Only process that talks to client)
                    │  (LEADER)    │
                    └──────┬───┬───┘
                           │   │
            ┌──────────────┘   └──────────────┐
            │ gRPC                             │ gRPC
            │ (TeamIngress)                    │ (TeamIngress)
            ↓                                  ↓
    ┌──────────────┐                  ┌──────────────┐
    │  Process B   │                  │  Process E   │
    │(TEAM_LEADER) │                  │(TEAM_LEADER) │
    │  Team Green  │                  │  Team Pink   │
    └──────┬───┬───┘                  └──────┬───┬───┘
           │   │                             │   │
           │   └─────────────────┐           │   │
           │                     │           │   │
           ↓                     ↓           ↓   ↓
    ┌──────────┐          ┌──────────┐  ┌──────────┐
    │Process C │          │Process D │  │Process F │
    │ (WORKER) │          │(TEAM_LDR)│  │ (WORKER) │
    │  Green   │          │  Pink    │  │  Pink    │
    └──────────┘          └──────────┘  └──────────┘
```

## Overlay Connections (Fixed Topology)

```
Allowed Connections:
    A ←→ B
    A ←→ E
    B ←→ C
    B ←→ D
    E ←→ D
    E ←→ F

Teams:
    Green: {A, B, C}
    Pink:  {D, E, F}
```

## Two-Host Deployment

```
┌─────────────────────────────────────┐
│          HOST 1                     │
│  (e.g., 192.168.1.100)             │
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │Process A │  │Process B │       │
│  │ :50050   │  │ :50051   │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐                      │
│  │Process D │                      │
│  │ :50053   │                      │
│  └──────────┘                      │
│                                     │
│  Shared Memory: /mini2_host1       │
│  {A, B, D}                         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│          HOST 2                     │
│  (e.g., 192.168.1.101)             │
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │Process C │  │Process E │       │
│  │ :50052   │  │ :50054   │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  ┌──────────┐                      │
│  │Process F │                      │
│  │ :50055   │                      │
│  └──────────┘                      │
│                                     │
│  Shared Memory: /mini2_host2       │
│  {C, E, F}                         │
└─────────────────────────────────────┘

        ↑              ↑
        │   Network   │
        │    gRPC     │
        └──────┬──────┘
               │
        ┌──────────────┐
        │   CLIENT     │
        └──────────────┘
```

## Request Flow (Phase 2)

```
1. Client sends request to A
   ┌────────┐
   │ Client │──Request(need_green=true, need_pink=true)──→ A
   └────────┘

2. A determines which teams are needed and forwards
   
   If need_green:
      A ──HandleRequest──→ B (Team Leader Green)
   
   If need_pink:
      A ──HandleRequest──→ E (Team Leader Pink)

3. Team leaders forward to their workers
   
   B ──HandleRequest──→ C (Worker)
   E ──HandleRequest──→ F (Worker)
   E ──HandleRequest──→ D (also a team leader, but acts as worker)

4. Workers process and generate results
   
   C: Process data → Generate WorkerResult
   F: Process data → Generate WorkerResult
   D: Process data → Generate WorkerResult

5. Workers return results to their team leaders
   
   C ──PushWorkerResult──→ B
   F ──PushWorkerResult──→ E
   D ──PushWorkerResult──→ E

6. Team leaders aggregate and send to A
   
   B: Aggregate Green team results ──PushWorkerResult──→ A
   E: Aggregate Pink team results ──PushWorkerResult──→ A

7. A aggregates all results and sends to client
   
   A: Combine all results
   A ──AggregatedResult──→ Client
```

## Chunking Strategy A: Client-Controlled Paging (Phase 3)

```
┌────────┐                          ┌────────┐
│ Client │                          │   A    │
└───┬────┘                          └───┬────┘
    │                                   │
    │ 1. RequestOnce(request)           │
    │─────────────────────────────────→ │
    │                                   │ A collects ALL data
    │                                   │ from teams, stores
    │                                   │ complete result in
    │                                   │ memory
    │                                   │
    │ 2. AggregatedResult (with chunks) │
    │ ←─────────────────────────────────│
    │                                   │
    │ 3. GetNext(request_id, index=0)   │
    │─────────────────────────────────→ │
    │                                   │ A retrieves chunk 0
    │ 4. NextChunkResp (chunk 0)        │ from stored result
    │ ←─────────────────────────────────│
    │                                   │
    │ 5. GetNext(request_id, index=1)   │
    │─────────────────────────────────→ │
    │                                   │ A retrieves chunk 1
    │ 6. NextChunkResp (chunk 1)        │ from stored result
    │ ←─────────────────────────────────│
    │                                   │
    │ ... continue for all chunks ...   │
    │                                   │
    
Memory at A: HIGH (stores complete result)
Time to first chunk: SLOW (must collect everything first)
Fairness: POOR (new requests blocked until storage clears)
```

## Chunking Strategy B: Server-Managed Sessions (Phase 3)

```
┌────────┐                          ┌────────┐
│ Client │                          │   A    │
└───┬────┘                          └───┬────┘
    │                                   │
    │ 1. StartRequest(request)          │
    │─────────────────────────────────→ │
    │                                   │ A creates session
    │                                   │ immediately, starts
    │ 2. SessionOpen(request_id)        │ background gather
    │ ←─────────────────────────────────│
    │                                   │ (Background thread
    │                                   │  gathering data)
    │ 3. PollNext(request_id)           │
    │─────────────────────────────────→ │
    │                                   │ Check if chunk ready
    │ 4. PollResp(ready=false)          │
    │ ←─────────────────────────────────│ (Not ready yet)
    │                                   │
    │ ... wait a bit ...                │
    │                                   │
    │ 5. PollNext(request_id)           │
    │─────────────────────────────────→ │
    │                                   │ Chunk is ready!
    │ 6. PollResp(ready=true, chunk)    │
    │ ←─────────────────────────────────│
    │                                   │
    │ 7. PollNext(request_id)           │
    │─────────────────────────────────→ │
    │                                   │ Next chunk ready
    │ 8. PollResp(ready=true, chunk)    │
    │ ←─────────────────────────────────│
    │                                   │
    │ ... continue until has_more=false │
    │                                   │

Memory at A: LOW (streams chunks, doesn't store complete result)
Time to first chunk: FAST (returns as soon as first chunk arrives)
Fairness: GOOD (multiple sessions can be active)
```

## Shared Memory Coordination (Phase 4)

```
Host 1: Shared Memory Segment /mini2_host1
┌─────────────────────────────────────────────┐
│  struct SharedSegment {                     │
│    ProcessStatus processes[3];              │
│    uint32_t count;                          │
│  }                                           │
│                                              │
│  processes[0]: {                            │
│    process_id: "A"                          │
│    state: IDLE                              │
│    queue_size: 0                            │
│    last_update_ms: 1699563421234           │
│  }                                           │
│                                              │
│  processes[1]: {                            │
│    process_id: "B"                          │
│    state: BUSY                              │
│    queue_size: 5                            │
│    last_update_ms: 1699563421235           │
│  }                                           │
│                                              │
│  processes[2]: {                            │
│    process_id: "D"                          │
│    state: IDLE                              │
│    queue_size: 0                            │
│    last_update_ms: 1699563421236           │
│  }                                           │
└─────────────────────────────────────────────┘
         ↑           ↑           ↑
         │           │           │
    ┌────┴───┐  ┌───┴────┐  ┌───┴────┐
    │   A    │  │   B    │  │   D    │
    │ (read) │  │(write) │  │(write) │
    └────────┘  └────────┘  └────────┘
```

## Load-Aware Routing (Phase 4)

```
WITHOUT Shared Memory:
    Client Request → A
                     ↓
                   Always route to B (Green) or E (Pink)
                   based on data requirements only
                     ↓
                   Might overload one team leader!

WITH Shared Memory:
    Client Request → A
                     ↓
                   Check shared memory for status
                     ↓
                   ┌─────────────────────────────┐
                   │ B: queue_size=10, BUSY      │
                   │ E: queue_size=2,  IDLE      │
                   └─────────────────────────────┘
                     ↓
                   Route to E (less busy)
                   even if both teams could handle it
                     ↓
                   Better load balancing!
```

## Data Structures (Use Realistic Types!)

```
❌ BAD - Everything as strings:
    message BadResult {
        string int_value = 1;      // "123"
        string double_value = 2;    // "45.67"
        string bool_value = 3;      // "true"
    }

✅ GOOD - Proper types:
    message GoodResult {
        int32 int_value = 1;        // 123
        double double_value = 2;     // 45.67
        bool bool_value = 3;         // true
        string label = 4;            // "actual string"
    }

Example from Mini1 fire data:
    message FireRecord {
        int32 year = 1;              // 2020
        string state = 2;            // "California"
        double acres_burned = 3;     // 123456.78
        int32 num_fires = 4;         // 8950
        bool is_significant = 5;     // true
    }
```

## Performance Measurement Points

```
Client                     A                    B/E                Workers
  │                        │                     │                   │
  │───── Request ────────→ │                     │                   │
  ├─ T0                    │                     │                   │
  │                        │─── Forward ───────→ │                   │
  │                        ├─ T1                 │                   │
  │                        │                     │─── Forward ─────→ │
  │                        │                     ├─ T2               │
  │                        │                     │                   │ Process
  │                        │                     │                   ├─ T3
  │                        │                     │ ←─── Result ──────│
  │                        │                     ├─ T4               │
  │                        │ ←─── Result ────────│                   │
  │                        ├─ T5                 │                   │
  │ ←─── Response ─────────│                     │                   │
  ├─ T6                    │                     │                   │

Metrics:
- End-to-end latency: T6 - T0
- Forwarding overhead: (T1 - T0) + (T2 - T1)
- Processing time: T3
- Aggregation time: (T5 - T4) + (T6 - T5)
```

## Complete Communication Matrix

```
From ↓ / To →  │  A  │  B  │  C  │  D  │  E  │  F  │
───────────────┼─────┼─────┼─────┼─────┼─────┼─────┤
      A        │  -  │  ✓  │  ✗  │  ✗  │  ✓  │  ✗  │
      B        │  ✓  │  -  │  ✓  │  ✓  │  ✗  │  ✗  │
      C        │  ✗  │  ✓  │  -  │  ✗  │  ✗  │  ✗  │
      D        │  ✗  │  ✓  │  ✗  │  -  │  ✓  │  ✗  │
      E        │  ✓  │  ✗  │  ✗  │  ✓  │  -  │  ✓  │
      F        │  ✗  │  ✗  │  ✗  │  ✗  │  ✓  │  -  │

✓ = Allowed by overlay
✗ = NOT allowed
- = Self (N/A)
```

## State Machine (Strategy B Session)

```
Session States:

    CREATED
       │
       │ StartRequest()
       ↓
    GATHERING ←──┐
       │          │
       │ Data     │ PollNext()
       │ Arrives  │ (not ready yet)
       │          │
       ↓          │
    READY ───────┘
       │
       │ PollNext()
       │ (last chunk)
       ↓
    COMPLETE
       │
       │ After timeout
       ↓
    CLEANED_UP
```

These diagrams should help visualize the architecture and data flows!
