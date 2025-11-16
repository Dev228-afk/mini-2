# Project Summary and File Guide

## What You Have Now

This project structure has been set up with everything you need to implement a distributed multi-process system with chunked responses. Here's what each file does and how they work together.

---

## 📁 File Structure Overview

### New Documentation (Read These!)

1. **CRITICAL_REQUIREMENTS.md** ⚠️ **READ FIRST!**
   - Grading requirements that affect your score
   - Data structure requirements (VERY IMPORTANT!)
   - Must-follow constraints
   - This is essential - these requirements affect your grade!

2. **PROJECT_SUMMARY.md** - Your roadmap (what everything is)
3. **QUICKSTART.md** - Build and run in 5 minutes
4. **TODO.md** - Complete checklist for all 4 phases
5. **docs/IMPLEMENTATION_GUIDE.md** - 600+ lines of detailed guidance
6. **docs/ARCHITECTURE_DIAGRAMS.md** - Visual diagrams
7. **START_HERE.md** - Quick starting point

### Source Code Files

#### C++ Implementation

**Server Code:**
- `src/cpp/server/ServerMain.cpp` - Main server entry point
- `src/cpp/server/Handlers.cpp` - gRPC service implementations (stub)
  - ✅ Bug already fixed: `False` → `false` on line 39

**Client Code:**
- `src/cpp/client/ClientMain.cpp` - Test client implementation (basic stub)

**Common Code:**
- `src/cpp/common/config.h` - Configuration structure definitions
- `src/cpp/common/config.cpp` - JSON config file parser
- Generated files will go here: `minitwo.pb.h`, `minitwo.grpc.pb.h`, etc.

**CMake Files:**
- `CMakeLists.txt` (root) - Main build configuration
- `src/cpp/CMakeLists.txt` - C++ build targets

#### Python Implementation

**Server Code:**
- `src/python/server/server.py` - Python server implementation (stub)

**Common Code:**
- Generated files will go here: `minitwo_pb2.py`, `minitwo_pb2_grpc.py`

### Configuration and Protocol Files

**Protocol Definition:**
- `protos/minitwo.proto` - gRPC service and message definitions
  - Defines all RPCs and data structures
  - Single source of truth for communication

**Network Configuration:**
- `config/network_setup.json` - Process topology and settings
  - Defines 6 processes (A-F)
  - Roles, hosts, ports, teams
  - Overlay connections
  - Shared memory segments

### Build and Deployment Scripts

- `scripts/gen_proto.sh` - Generate C++ and Python code from .proto
- `scripts/build.sh` - Compile C++ code with CMake
- `scripts/run_cluster.sh` - Start all 6 servers at once

### Results and Data

- `results/phase1_baseline.csv` - Baseline performance metrics
- `results/phase3_comparison.csv` - Strategy comparison data
- *(You'll create more CSV files as needed)*

### Testing

- `tests/cpp_unit_tests.cpp` - C++ unit tests (placeholder)
- `tests/python_unit_tests.py` - Python unit tests (placeholder)

---

## 🎯 How to Use This Project

### Phase 1: Get It Running (Week 1)

1. **Read**: `QUICKSTART.md` (15 minutes)
2. **Do**: Follow build instructions
3. **Test**: Get 6 servers + client working locally
4. **Checklist**: Mark items in `TODO.md` Phase 1 section
5. **Measure**: Collect baseline data → `results/phase1_baseline.csv`
6. **Document**: Fill in Phase 1 section of `docs/research_notes.md`

### Phase 2: Add Logic (Week 2)

1. **Read**: `docs/IMPLEMENTATION_GUIDE.md` Phase 2 section
2. **Code**: Implement request forwarding and aggregation
3. **Reference**: Use patterns from `Labs/loop-grpc/` and `Labs/leader-adv/`
4. **Test**: End-to-end request flow
5. **Checklist**: Mark items in `TODO.md` Phase 2 section
6. **Measure**: Collect performance data
7. **Document**: Fill in Phase 2 section of `docs/research_notes.md`

### Phase 3: Implement Chunking (Week 3)

1. **Read**: `docs/IMPLEMENTATION_GUIDE.md` Phase 3 section
2. **Code**: Implement Strategy A and Strategy B
3. **Test**: Both strategies with different data sizes
4. **Test**: Fairness with concurrent clients
5. **Checklist**: Mark items in `TODO.md` Phase 3 section
6. **Measure**: Compare strategies → `results/phase3_comparison.csv`
7. **Document**: Analysis and comparison in `docs/research_notes.md`

### Phase 4: Optimize (Week 4)

1. **Read**: `docs/IMPLEMENTATION_GUIDE.md` Phase 4 section
2. **Code**: Add shared memory coordination
3. **Test**: Compare with/without shared memory
4. **Checklist**: Mark items in `TODO.md` Phase 4 section
5. **Measure**: Performance improvements
6. **Document**: Final analysis in `docs/research_notes.md`

### Final Week: Polish and Demo

1. **Review**: All TODO items checked?
2. **Test**: Clean deployment on two machines
3. **Document**: Complete `docs/research_notes.md`
4. **Prepare**: Demo script and talking points
5. **Answer**: The 5 key questions (see below)

---

## 🎓 What You Need to Answer (Final Deliverable)

Your final documentation should answer these questions:

### 1. Creating Distributed Processes
- How did you structure the 6-process overlay?
- How do processes discover and communicate with peers?
- What challenges did you face in coordination?
- How did you handle the 2-host deployment?

### 2. Streaming (Chunking)
- How do the two chunking strategies work?
- Which strategy is better and why?
- What trade-offs did you discover?
- How did you determine chunk size?

### 3. Coordination
- How do team leaders coordinate their workers?
- How does Process A aggregate results?
- How does shared memory improve coordination?
- What synchronization issues did you encounter?

### 4. Testing
- How did you test the distributed system?
- What unit tests did you create?
- How did you test fairness?
- How did you reproduce bugs?

### 5. Network Measurement Tools
- What tools did you use to measure performance?
- How did you measure RTT, CPU, memory?
- What metrics were most important?
- How did you ensure accurate measurements?

**Special Findings**: Any unexpected discoveries, optimizations, or insights.

---

## 🔧 Key Implementation Areas

### What You MUST Implement

#### Phase 1 (Basecamp):
- ✅ gRPC service handlers (expand stubs in `Handlers.cpp`)
- ✅ Configuration loading (already in `config.cpp`)
- ✅ Process startup with correct identity
- ✅ Peer connection establishment
- ⚠️ Connectivity testing
- ⚠️ Performance measurement

#### Phase 2 (Forwarding):
- ❌ Request routing logic in Process A
- ❌ Team leader forwarding to workers
- ❌ Worker result generation (realistic data!)
- ❌ Result aggregation at team leaders
- ❌ Final aggregation at Process A
- ❌ End-to-end testing

#### Phase 3 (Chunking):
- ❌ Strategy A: Full-result storage + paging
- ❌ Strategy B: Session management + incremental
- ❌ Chunk management
- ❌ Client paging/polling logic
- ❌ Fairness testing setup
- ❌ Comparative measurement

#### Phase 4 (Shared Memory):
- ❌ Shared memory segment creation
- ❌ Process status structure
- ❌ Status update mechanism
- ❌ Load-aware routing
- ❌ Performance comparison

### What's Already Done ✅

- Project structure created
- Proto file defined with all necessary RPCs
- Configuration JSON with correct topology
- Basic C++ server that reads config
- Basic C++ client stub
- Basic Python server stub
- CMake build system
- Shell scripts for build/run
- Bug in Handlers.cpp fixed
- Comprehensive documentation created

### What You Need to Add ⚠️

- Actual logic in service handlers (currently just return OK)
- Request routing and forwarding
- Data generation and processing
- Chunking implementations
- Shared memory coordination
- Testing code
- Measurement collection
- Data analysis

---

## 🚀 Getting Started Right Now

### Option A: Dive Right In (30 seconds)
```bash
cd /Users/spartan/Desktop/CMPE275/mini_2
open QUICKSTART.md  # Read this first
./scripts/gen_proto.sh
./scripts/build.sh
./build/mini2_server --config config/network_setup.json --node A
```

### Option B: Study First (30 minutes)
1. Read `QUICKSTART.md` (10 min)
2. Skim `docs/IMPLEMENTATION_GUIDE.md` Phase 1 (10 min)
3. Review `protos/minitwo.proto` to understand RPCs (5 min)
4. Review `config/network_setup.json` to understand topology (5 min)
5. Then follow Option A

### Option C: Plan Everything (2 hours)
1. Read all documentation thoroughly
2. Review all code files
3. Read the lab examples: `Labs/loop-grpc/`, `Labs/leader-adv/`
4. Create a week-by-week plan
5. Set up your development environment
6. Start implementation

---

## 📊 Success Criteria

By the end, you should have:

✅ **Working System**
- 6 processes communicating via gRPC
- Deploys to 2+ machines
- Handles client requests end-to-end
- Two different chunking strategies
- Shared memory coordination

✅ **Measurements**
- Baseline: RTT, CPU, memory
- Phase 2: End-to-end latency
- Phase 3: Strategy comparison
- Phase 4: Shared memory impact
- All data in CSV files

✅ **Documentation**
- Complete `research_notes.md`
- All 5 questions answered
- Clear analysis and conclusions
- Trade-offs explained

✅ **Code Quality**
- No hardcoding
- Realistic data structures
- Organized in logical directories
- Proper error handling
- Follows constraints (no async gRPC, etc.)

---

## 🆘 When You Get Stuck

1. **Build errors?** → Check `QUICKSTART.md` Troubleshooting section
2. **Don't know what to implement?** → Read corresponding section in `IMPLEMENTATION_GUIDE.md`
3. **Lost track?** → Check `TODO.md` for next unchecked item
4. **Need examples?** → Look at lab code in `../Labs/loop-grpc/` and `../Labs/leader-adv/`
5. **Logic questions?** → Review `protos/minitwo.proto` and `mini2-chunks.md`

---

## 💡 Pro Tips

1. **Commit often**: Use git to track your progress
2. **Test incrementally**: Don't wait until everything is done
3. **Measure early**: Collect baseline data before adding features
4. **Document as you go**: Don't wait until the end
5. **Use the scripts**: `gen_proto.sh`, `build.sh`, `run_cluster.sh`
6. **Read the logs**: Add logging to understand what's happening
7. **Start simple**: Get Phase 1 perfect before moving on
8. **Ask questions**: If requirements are unclear, clarify early

---

## 📅 Suggested Timeline

- **Week 1**: Phase 1 complete, deployed to 2 machines
- **Week 2**: Phase 2 complete, requests flowing end-to-end
- **Week 3**: Phase 3 complete, both strategies working
- **Week 4**: Phase 4 complete, all measurements done
- **Final**: Documentation complete, demo ready

---

## 🎉 You're Ready!

Everything you need is here:
- ✅ Complete project structure
- ✅ Build system configured
- ✅ Documentation written
- ✅ Checklists created
- ✅ Bug fixed
- ✅ Clear roadmap

**Next command to run:**
```bash
open QUICKSTART.md
```

**Or jump straight in:**
```bash
./scripts/gen_proto.sh && ./scripts/build.sh
```

Good luck! You've got this! 🚀
