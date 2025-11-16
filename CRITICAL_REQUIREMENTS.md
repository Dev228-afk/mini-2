# Critical Project Requirements - Quick Reference

## ⚠️ MUST FOLLOW - Grading Impact

### Data Structures (VERY IMPORTANT - Affects Scoring!)
**Use realistic, type-correct data structures:**
- ✅ Use `int32` for integers (e.g., year, count)
- ✅ Use `double` for floating point (e.g., acres, coordinates)
- ✅ Use `bool` for true/false flags
- ✅ Use `string` only for actual text data
- ❌ **DO NOT** use strings for everything
- ❌ **DO NOT** use raw strings when proper types are needed

**Example - BAD:**
```protobuf
message BadData {
    string year = 1;           // "2020" ❌
    string acres = 2;          // "12345.67" ❌
    string is_active = 3;      // "true" ❌
}
```

**Example - GOOD:**
```protobuf
message GoodData {
    int32 year = 1;            // 2020 ✅
    double acres = 2;          // 12345.67 ✅
    bool is_active = 3;        // true ✅
    string state_name = 4;     // "California" ✅
}
```

**Why it matters:** 
- Reflects real-world application usage
- Developer/integrator would never use only raw strings
- **THIS WILL AFFECT YOUR SCORE**

---

## 🏗️ Architecture Requirements

### Network Topology (DO NOT CHANGE)
**Tree structure - NOT flat/spoke-hub:**
- ✅ Use the specified overlay: A-B, B-C, B-D, A-E, E-F, E-D
- ❌ **DO NOT** create flat (one-to-many) design
- ❌ **DO NOT** connect all nodes directly to A

**Why it matters:**
- Flat design ignores the challenges of:
  1. Configuring servers to know their edges
  2. Forwarding requests through multiple hops
  3. Matching requests to replies with context

### Edge Communication
- Edges are **asynchronous** (but use synchronous gRPC APIs!)
- Edges **do not have to be bi-directional**
- Your team decides the approach within the constraints

### Deployment Requirements
- ✅ **MUST run on at least TWO separate computers**
- ✅ Test with real cross-host communication
- ✅ In development, all servers on same host is OK for testing
- Final demo/submission must show multi-host deployment

**Allowed configurations:**
1. **Two computers:** Host1 {A,B,D}, Host2 {C,E,F}
2. **Three computers:** Host1 {A,C}, Host2 {B,D}, Host3 {E,F}

---

## 🎯 Development Best Practices

### Code Execution
- ❌ **DO NOT** run code from IDE
- ✅ Run each server from separate shell/terminal
- ✅ Test from command line

### Code Organization
- ✅ Organize code into logical sub-directories
- ✅ Remove or isolate dead/incomplete code
- ✅ Use professional organization and accepted style
- ❌ Don't leave commented-out or experimental code in main codebase

### Design Patterns to AVOID
- ❌ Fixed response (hardcoded data)
- ❌ Chat-like systems
- ❌ Spoke-hub (flat) topology
- ❌ String-only data structures

### Time Management
- ⚠️ **This is MORE work than mini1**
- ⚠️ **Do NOT wait until the last week to start**
- ✅ Start early, iterate continuously

---

## 📊 Performance Metrics to Measure

**Use MORE THAN ONE metric:**

### Required Measurements
1. **Performance Metrics:**
   - Response time (latency)
   - Throughput (requests/second)
   - Memory usage
   - CPU utilization

2. **Time Measurement (dt):**
   - End-to-end latency
   - Time to first chunk
   - Processing time per stage
   - **How do YOU measure time?** (document your method)

3. **System Characteristics:**
   - Lines of Code (LoC)
   - Cross-language integration (C++ ↔ Python)
   - Cross-OS compatibility
   - Scalability (weak and strong)

4. **Quality Indicators:**
   - Code organization
   - Test coverage
   - Error handling
   - Documentation completeness

### Realistic Expectations
- Set **realistic** performance goals
- Model system behavior appropriately
- Document assumptions and trade-offs
- Compare different approaches objectively

---

## 🔍 Details Matter

### Focus Areas
- ✅ Focus on **distributed process coordination**
- ✅ Focus on **communication transport layers**
- ✅ Focus on **request/response management**
- ❌ Don't focus on making an "application" with UI/UX

### What NOT to Include
- ❌ No UI/UX elements
- ❌ No text-based CLI menu systems
- ❌ No application features unrelated to distributed coordination
- ❌ No game-like or chat-like interactions

---

## 💡 Key Insights from Requirements

### Spirit of the Mini
> "There is a fine edge between innovation and gaming the system (mini). What is the short-term versus long-term advantage to you?"

**Translation:** 
- Goal is to **build skills**, not exploit loopholes
- Design for real-world applicability, not just passing tests
- Consider long-term learning value, not just quick solutions

### Configuration and Discovery
- Processes **do not discover each other dynamically**
- Use a **mapping/config file** for edges and connections
- ❌ **DO NOT hardcode** server identity, role, or hostname
- ✅ Read configuration at runtime

### Request Forwarding
**Challenges to address:**
1. How does one configure servers to know their edges?
2. How do you forward requests through the tree?
3. How do you provide context to match requests to replies?
4. How do you handle asynchronous edges?

---

## 📚 Resources and Examples

### Available Lab Examples
- **loop-grpc:** gRPC communication patterns
- **leader-adv:** Leader-worker coordination
- **shared memory:** Inter-process communication
- **gRPC source code on GitHub:** Many examples for design/code inspiration

### Don't Limit Yourself
- Use repos and source code (like gRPC GitHub)
- Research best practices
- Look beyond what's discussed in class/Canvas
- **But stay within the technical constraints!**

---

## ✅ Quick Compliance Checklist

Before submitting, verify:

- [ ] Using realistic data types (int, double, bool, string appropriately)
- [ ] Tree topology (NOT flat/spoke-hub)
- [ ] Runs on 2+ separate computers
- [ ] No hardcoded identities, roles, or hostnames
- [ ] Servers run from shell, not IDE
- [ ] No dead/incomplete code in main codebase
- [ ] Measuring multiple performance indicators
- [ ] Professional code organization
- [ ] Focused on distributed coordination (not application features)
- [ ] No UI/UX or CLI menu systems
- [ ] Using gRPC synchronous APIs (not async)

---

## 🎓 Remember

1. **Data structures affect your score** - Use proper types!
2. **Multi-computer deployment is required** - Test cross-host!
3. **Tree topology is mandatory** - No flat designs!
4. **Start early** - This is more work than mini1!
5. **Details matter** - Follow all constraints carefully!

---

## 📝 When in Doubt

Ask yourself:
- Is this realistic for a production system?
- Am I using the right data type for this value?
- Does my design follow the tree topology?
- Have I tested on multiple computers?
- Am I building skills or gaming the system?

**If unsure, refer back to:** `mini2-chunks.md` (original requirements)

---

This document supplements the main documentation (QUICKSTART, IMPLEMENTATION_GUIDE, etc.) with critical requirements that affect your grade. Keep this handy during development! 🎯
