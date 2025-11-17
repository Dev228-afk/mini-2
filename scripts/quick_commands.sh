#!/bin/bash

################################################################################
# QUICK COMMAND REFERENCE
# All essential commands for testing and troubleshooting
################################################################################

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    MINI-2 QUICK COMMAND REFERENCE                            ║
║                  Cross-Computer Distributed System Testing                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

🏗️  SETUP & DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Build Project (on macOS/Computer 2):
   cd build && make -j4

2. Deploy to Computer 1:
   scp build/src/cpp/mini2_server USER@192.168.137.169:/home/meghpatel/dev/mini-2/build/src/cpp/

3. Restart Servers (Computer 1):
   ps aux | grep mini2_server | grep -v grep | awk '{print $2}' | xargs kill
   ./scripts/start_all_servers.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍  DIAGNOSTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Check System Health:
   ./scripts/diagnose_and_fix.sh

Check Server Logs for Errors:
   grep ERROR logs/*.log

View Specific Server Log:
   tail -50 logs/server_A.log

Monitor Live Logs:
   tail -f logs/server_*.log

Check Network Connectivity:
   ping -c 10 192.168.137.1          # Computer 2
   ping -c 10 192.168.137.169        # Computer 1 WSL

Verify Servers Running:
   ps aux | grep mini2_server

Check Port Listening:
   lsof -i :50050-50055              # Requires sudo on some systems

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪  TESTING COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Quick Tests (Manual):

1. Ping Single Node:
   ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode ping

2. Ping All Nodes:
   ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode all

3. Simple Request:
   ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode request --query "test"

4. Session Mode (Chunked):
   ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode session --query "test_data/data_10k.csv"

Automated Test Suites:

1. Comprehensive Tests (Recommended):
   ./scripts/comprehensive_test_with_metrics.sh
   
   Output: test_results_*/PERFORMANCE_REPORT.md

2. Performance Deep Dive (Advanced):
   ./scripts/performance_deep_dive.sh
   
   Output: performance_analysis_*/DETAILED_PERFORMANCE_ANALYSIS.md

3. Original Comprehensive Test:
   ./scripts/comprehensive_test.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧  TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Connection Refused:
   1. Check firewall: ./scripts/diagnose_and_fix.sh
   2. Verify servers running: ps aux | grep mini2_server
   3. Check port forwarding (Computer 1 Windows):
      netsh interface portproxy show all

Servers Not Starting:
   1. Check if ports in use: lsof -i :50050-50055
   2. Kill old processes: pkill mini2_server
   3. Check logs: cat logs/server_*.log

"Cannot open dataset" Errors:
   ✅ FIXED in latest build (RequestProcessor.cpp)
   - Redeploy updated binary
   - Restart servers

WSL IP Changed:
   1. Check current IP: ip addr show eth0
   2. Update port forwarding: ./scripts/diagnose_and_fix.sh (shows commands)
   3. Update config if needed: config/network_setup.json

Firewall Issues:
   Windows: Run scripts/WINDOWS_FIREWALL_FIX.ps1 (as Admin)
   Linux:   sudo ufw allow 50050:50055/tcp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔬  SHARED MEMORY TOOLS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

List Shared Memory Segments:
   ipcs -m

Show Distributed Memory (All Nodes):
   ./build/src/cpp/show_distributed_memory

Get Memory from Specific Node:
   ./build/src/cpp/get_distributed_memory 192.168.137.169:50050

Inspect Local Shared Memory:
   ./build/src/cpp/inspect_shm              # macOS: may not work (librt)

Clean Up Shared Memory:
   ipcrm -M $(ipcs -m | grep shm_host | awk '{print $1}')

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊  PERFORMANCE METRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Network RTT:
   ping -c 100 192.168.137.1 | tail -1

Request Latency (10 sequential):
   time for i in {1..10}; do ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode request --query "test_$i"; done

Parallel Performance (10 concurrent):
   time (for i in {1..10}; do ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode request --query "test_$i" & done; wait)

Memory Usage:
   ps aux | grep mini2_server | awk '{print $2, $4, $11}'

CPU Usage (live):
   top | grep mini2_server

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁  FILE LOCATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration:
   config/network_setup.json            # Network topology

Binaries:
   build/src/cpp/mini2_server           # Server binary
   build/src/cpp/mini2_client           # Client binary
   build/src/cpp/show_distributed_memory
   build/src/cpp/get_distributed_memory

Scripts:
   scripts/comprehensive_test_with_metrics.sh    # Main test suite
   scripts/performance_deep_dive.sh              # Advanced metrics
   scripts/diagnose_and_fix.sh                   # Health check
   scripts/start_all_servers.sh                  # Server startup
   scripts/WINDOWS_FIREWALL_FIX.ps1              # Windows config

Logs:
   logs/server_A.log through server_F.log

Test Results:
   test_results_*/                      # Timestamped test outputs
   performance_analysis_*/              # Detailed metrics

Documentation:
   READY_FOR_FINAL_TESTING.md           # Deployment guide
   EXECUTIVE_SUMMARY_FOR_PROFESSOR.md   # Report template
   QUICK_START_TESTING.md               # Quick start guide

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯  COMMON WORKFLOWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Full Test Run (Computer 1):
   cd /home/meghpatel/dev/mini-2
   ps aux | grep mini2_server | grep -v grep | awk '{print $2}' | xargs kill
   ./scripts/start_all_servers.sh
   sleep 5
   ./scripts/comprehensive_test_with_metrics.sh
   cat test_results_*/PERFORMANCE_REPORT.md

Debug Connection Issues:
   ./scripts/diagnose_and_fix.sh
   # Follow suggested fixes
   grep ERROR logs/*.log

Quick Validation:
   ./build/src/cpp/mini2_client --server 192.168.137.169:50050 --mode all
   # Should see responses from all 6 nodes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨  EMERGENCY PROCEDURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

System Not Responding:
   1. Kill all servers: pkill -9 mini2_server
   2. Clean shared memory: ipcrm -M $(ipcs -m | grep shm_host | awk '{print $1}')
   3. Clear logs: rm logs/*.log
   4. Restart: ./scripts/start_all_servers.sh

Complete Rebuild:
   cd build
   rm -rf *
   cmake ..
   make -j4

Network Reset (Windows - PowerShell as Admin):
   netsh interface portproxy reset
   # Then re-run WINDOWS_FIREWALL_FIX.ps1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 TIP: Save this output for quick reference during testing!
    ./scripts/quick_commands.sh > COMMANDS.txt

EOF
