# Mini Project 2 - TODO Checklist

## Quick Start (Do This First!)

- [x] **CRITICAL**: Fix bug in `src/cpp/server/Handlers.cpp` line 39: Change `False` to `false` ✅ DONE
- [x] Read through `docs/IMPLEMENTATION_GUIDE.md` for detailed steps ✅
- [x] Review the project requirements in `mini2-chunks.md` ✅
- [x] Understand the network topology: A-B, B-C, B-D, A-E, E-F, E-D ✅

---

## Phase 1: Basecamp - Communication Infrastructure

### Setup and Configuration
- [x] Install required dependencies (gRPC, Protobuf, CMake) ✅
- [x] Review `config/network_setup.json` configuration ✅
- [x] Ensure no hardcoded values in source code ✅
- [x] Install nlohmann/json library for C++ config parsing ✅

### Protocol Buffers
- [x] Review `protos/minitwo.proto` service definitions ✅
- [x] Run `scripts/gen_proto.sh` to generate C++ and Python stubs ✅
- [x] Verify generated files in `src/cpp/common/` and `src/python/common/` ✅

### Build System
- [x] Review `CMakeLists.txt` files ✅
- [x] Run `scripts/build.sh` successfully ✅
- [x] Verify executables: `mini2_server` and `mini2_client` ✅

### Basic Connectivity (Local Testing)
- [x] Start Process A on localhost ✅
- [x] Test client connection to Process A ✅
- [x] Enhanced client with Ping testing modes ✅
- [x] Added logging to server handlers ✅
- [ ] **IN PROGRESS**: Start all 6 servers on localhost ⏳
  - [ ] Process A (Leader) - Port 50050
  - [ ] Process B (Team Leader Green) - Port 50051
  - [ ] Process C (Worker Green) - Port 50052
  - [ ] Process D (Team Leader Pink) - Port 50053
  - [ ] Process E (Team Leader Pink) - Port 50054
  - [ ] Process F (Worker Pink) - Port 50055
- [ ] Implement and test Ping/Heartbeat on all connections

### Topology Verification
- [ ] Test connections that SHOULD work (overlay edges):
  - [ ] A → B
  - [ ] B → C
  - [ ] B → D
  - [ ] A → E
  - [ ] E → F
  - [ ] E → D
- [ ] Verify connections that should NOT work are properly rejected

### Baseline Performance Measurement
- [ ] Measure Round-Trip Time (RTT) for each connection
  - [ ] Same-host connections (A-B, B-D, E-F)
  - [ ] Cross-host connections (B-C, A-E, E-D)
- [ ] Measure CPU usage at idle for each process
- [ ] Measure memory usage (RSS) at idle for each process
- [ ] Record results in `results/phase1_baseline.csv`

### Multi-Host Deployment
- [ ] Update `config/network_setup.json` with actual hostnames
- [ ] Deploy to 2-computer configuration:
  - [ ] Host1: Processes A, B, D
  - [ ] Host2: Processes C, E, F
- [ ] Test cross-host connectivity
- [ ] Run client from a third machine or Host1

### Documentation
- [ ] Document Phase 1 findings in `docs/research_notes.md`
- [ ] Include RTT measurements
- [ ] Include resource usage statistics
- [ ] Note any challenges encountered

---

## Phase 2: Request Forwarding and Data Aggregation

### Request Routing Implementation
- [x] Implement request forwarding in Process A ✅
  - [x] Parse request to determine teams needed (Green/Pink/Both) ✅
  - [x] Create gRPC client stubs for team leaders ✅
  - [x] Forward request to appropriate team(s) ✅
- [x] Implement request forwarding in Team Leaders (B, E) ✅
  - [x] Receive request from A ✅
  - [x] Forward to team workers ✅
  - [x] Track which workers received requests ✅

### Worker Data Generation
- [x] Implement realistic data structure for results ✅
  - [x] Use proper types: `int`, `double`, `bool`, `string` ✅
  - [x] Mock data generation (Phase 2 MVP) ✅
  - [ ] Real data processing from mini1 fire data (Phase 3)
- [x] Implement WorkerResult generation ✅
  - [x] Set request_id ✅
  - [x] Set part_index ✅
  - [x] Serialize data to payload bytes ✅

### Result Aggregation
- [x] Implement result collection at Team Leaders ✅
  - [x] Collect results from all team workers ✅
  - [x] Aggregate/combine team results ✅
  - [x] Forward to Process A ✅
- [x] Implement result collection at Process A ✅
  - [x] Collect results from all teams ✅
  - [x] Combine into AggregatedResult ✅
  - [x] Calculate total_rows and total_bytes ✅

### End-to-End Testing
- [x] **COMPLETE**: Test Phase 2 implementation ✅
  - [x] Test request for Green team only ✅ (200 rows, 528 bytes, 21ms)
  - [x] Test request for Pink team only ✅ (200 rows, 528 bytes, 17ms)
  - [x] Test request for both teams ✅ (400 rows, 1056 bytes, 14ms)
  - [x] Verify client receives correct combined results ✅

### Performance Measurement
- [x] Measure end-to-end latency ✅
  - [x] Small requests (mock data ~500 bytes) ✅ 14-21ms
  - [ ] Medium requests (real data ~10KB)
  - [ ] Large requests (real data ~100KB+)
- [ ] Measure memory usage at Process A
  - [ ] While holding complete result
  - [ ] Peak memory consumption
- [ ] Count total network messages per request
- [ ] Record results in `results/phase2_aggregation.csv`

### Documentation
- [ ] Document Phase 2 findings in `docs/research_notes.md`
- [ ] Include latency measurements
- [ ] Include memory usage data
- [ ] Identify bottlenecks

---

## Phase 3: Multi-Chunk Response Strategies

### Strategy A: Client-Controlled Paging

#### Implementation
- [ ] Modify `ClientGatewayService::RequestOnce`
  - [ ] Collect complete result
  - [ ] Store in memory (with mutex protection)
  - [ ] Break into chunks
  - [ ] Return AggregatedResult with all chunks
- [ ] Implement `ClientGatewayService::GetNext`
  - [ ] Retrieve stored result by request_id
  - [ ] Return specific chunk by index
  - [ ] Indicate if more chunks available
- [ ] Update client to request chunks sequentially

#### Testing & Measurement
- [ ] Test with small dataset (few chunks)
- [ ] Test with large dataset (many chunks)
- [ ] Measure memory usage at Process A
- [ ] Measure time to first chunk
- [ ] Measure total completion time
- [ ] Count total RPC calls

### Strategy B: Server-Managed Sessions

#### Implementation
- [ ] Create SessionManager class
  - [ ] Track active sessions
  - [ ] Queue chunks as they arrive
  - [ ] Handle concurrent access (mutexes)
- [ ] Implement `ClientGatewayService::StartRequest`
  - [ ] Create session immediately
  - [ ] Return session ID
  - [ ] Start background data gathering
- [ ] Implement `ClientGatewayService::PollNext`
  - [ ] Check if chunk is ready
  - [ ] Return chunk if available
  - [ ] Indicate if more chunks coming
- [ ] Implement incremental data gathering
  - [ ] Don't store complete result
  - [ ] Stream chunks as they arrive from workers
- [ ] Update client for polling pattern

#### Testing & Measurement
- [ ] Test with small dataset
- [ ] Test with large dataset
- [ ] Measure memory usage at Process A (should be lower!)
- [ ] Measure time to first chunk (should be faster!)
- [ ] Measure total completion time
- [ ] Count total RPC calls (may be higher due to polling)

### Fairness Testing
- [ ] Create test with two concurrent clients
  - [ ] Client 1: Large request (many chunks)
  - [ ] Client 2: Small request (few chunks)
- [ ] Test Strategy A fairness
  - [ ] Does small request get blocked?
  - [ ] Measure wait times for both clients
- [ ] Test Strategy B fairness
  - [ ] Does small request get blocked?
  - [ ] Measure wait times for both clients

### Comparative Analysis
- [ ] Complete comparison table in `results/phase3_comparison.csv`
  - [ ] Memory efficiency (avg and peak)
  - [ ] Latency (first chunk and total)
  - [ ] Fairness (small request behavior)
  - [ ] Throughput (requests per second)
- [ ] Analyze trade-offs
  - [ ] When is Strategy A better?
  - [ ] When is Strategy B better?
  - [ ] What are the costs of each approach?

### Documentation
- [ ] Document Phase 3 findings in `docs/research_notes.md`
- [ ] Include comparison tables
- [ ] Explain which strategy is better and why
- [ ] Discuss trade-offs discovered

---

## Phase 4: Advanced Coordination with Shared Memory

### Shared Memory Implementation
- [ ] Review POSIX shared memory APIs
  - [ ] `shm_open()`, `mmap()`, `munmap()`, `shm_unlink()`
- [ ] Design ProcessStatus structure
  - [ ] Process ID
  - [ ] State (IDLE/BUSY)
  - [ ] Queue size
  - [ ] Last update timestamp
- [ ] Create SharedMemoryCoordinator class
  - [ ] Initialize shared memory segments
  - [ ] Update status method
  - [ ] Read status method
  - [ ] Proper cleanup in destructor

### Segment Configuration
- [ ] Implement Segment 1 for Host1 processes
  - [ ] Processes: A, B, D
  - [ ] Segment name: `/mini2_host1`
- [ ] Implement Segment 2 for Host2 processes
  - [ ] Processes: C, E, F
  - [ ] Segment name: `/mini2_host2`
- [ ] Each process updates its own status regularly

### Load-Aware Routing
- [ ] Implement LoadAwareRouter class
  - [ ] Check shared memory before routing
  - [ ] Select least-busy team leader
  - [ ] Prefer IDLE over BUSY processes
- [ ] Integrate with Process A request forwarding
  - [ ] Query shared memory for team leader status
  - [ ] Route to best available team leader
  - [ ] Fall back gracefully if SHM unavailable

### Testing
- [ ] Test shared memory creation and access
- [ ] Test status updates from all processes
- [ ] Test status reads from Process A
- [ ] Test load-aware routing under different loads
- [ ] Compare with and without shared memory

### Performance Measurement
- [ ] Run tests WITHOUT shared memory coordination
  - [ ] Measure throughput
  - [ ] Measure average response time
  - [ ] Count "wrong" routing decisions
- [ ] Run tests WITH shared memory coordination
  - [ ] Measure throughput
  - [ ] Measure average response time
  - [ ] Count "wrong" routing decisions
- [ ] Calculate improvements
- [ ] Record results in `results/phase4_shm_comparison.csv`

### Documentation
- [ ] Document Phase 4 findings in `docs/research_notes.md`
- [ ] Include before/after comparison
- [ ] Explain when shared memory helps
- [ ] Discuss overhead of shared memory access
- [ ] Note any synchronization issues encountered

---

## Testing and Quality Assurance

### Unit Tests
- [ ] Create C++ unit tests (`tests/cpp_unit_tests.cpp`)
  - [ ] Configuration parsing tests
  - [ ] Request routing logic tests
  - [ ] Chunk management tests
  - [ ] Shared memory tests
- [ ] Create Python unit tests (`tests/python_unit_tests.py`)
  - [ ] Server startup tests
  - [ ] gRPC service tests

### Integration Tests
- [ ] Full end-to-end request flow
- [ ] Multi-team coordination
- [ ] Error handling (disconnections, timeouts)
- [ ] Concurrent client handling

### Stress Tests
- [ ] Many concurrent clients
- [ ] Very large result sets
- [ ] Rapid-fire small requests
- [ ] Mix of large and small requests

---

## Final Deliverables

### Code Quality
- [ ] No hardcoded values (identities, roles, hostnames)
- [ ] Realistic data structures (not all strings)
- [ ] Proper error handling
- [ ] Code organized in logical subdirectories
- [ ] Comments for complex sections
- [ ] No dead/incomplete code in main codebase

### Documentation
- [ ] README.md complete with build/run instructions
- [ ] IMPLEMENTATION_GUIDE.md used throughout development
- [ ] research_notes.md filled with all measurements
- [ ] All CSV files in results/ directory complete
- [ ] Clear explanation of findings

### Measurements and Analysis
- [ ] Phase 1: Baseline metrics (RTT, CPU, Memory)
- [ ] Phase 2: End-to-end performance
- [ ] Phase 3: Strategy comparison with fairness analysis
- [ ] Phase 4: Shared memory coordination benefits
- [ ] Answer the key questions:
  - [ ] Creating distributed processes
  - [ ] Streaming (chunking) strategies
  - [ ] Coordination mechanisms
  - [ ] Testing approaches
  - [ ] Network measurement tools used
  - [ ] Special findings

### Demo Preparation
- [ ] Prepare scripts to easily demonstrate each phase
- [ ] Test demo on clean environment
- [ ] Prepare to explain design decisions
- [ ] Be ready to discuss trade-offs and findings

---

## Tips for Success

1. **Start Early**: This project has more work than mini1
2. **Test Incrementally**: Don't wait until all phases are done
3. **Measure Continuously**: Collect data as you implement
4. **Document as You Go**: Don't wait until the end
5. **Use Version Control**: Commit frequently with clear messages
6. **Follow the Rules**: No async gRPC, no UI, proper data structures
7. **Ask Questions**: If something is unclear, clarify early
8. **Review Examples**: Loop-grpc, leader-adv labs provide inspiration

---

## Common Mistakes to Avoid

- ❌ Using gRPC async APIs
- ❌ Hardcoding process identities or roles
- ❌ Using strings for all data types
- ❌ Storing requests/results in shared memory
- ❌ Creating a flat (spoke-hub) topology
- ❌ Running servers from IDE
- ❌ Waiting until last week to start
- ❌ Not measuring performance

---

## Status Tracking

**Current Phase**: _________

**Last Updated**: _________

**Blockers**: _________

**Next Steps**: _________
