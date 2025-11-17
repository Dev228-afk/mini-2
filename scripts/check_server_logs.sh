#!/bin/bash

echo "=========================================="
echo "CHECK SERVER LOGS FOR ERRORS"
echo "=========================================="
echo ""

cd ~/mini-2 || cd /home/*/dev/mini-2 || cd /mnt/c/Users/*/mini-2 || {
    echo "Cannot find mini-2 directory"
    exit 1
}

echo "Checking server logs..."
echo ""

for log in logs/server_*.log; do
    if [ -f "$log" ]; then
        echo "=========================================="
        echo "$(basename $log)"
        echo "=========================================="
        tail -50 "$log"
        echo ""
    fi
done

echo "=========================================="
echo "CHECK IF SERVERS ARE ACTUALLY ALIVE"
echo "=========================================="
ps aux | grep mini2_server | grep -v grep

echo ""
echo "If servers show above but ports don't work,"
echo "the servers likely crashed during startup."
echo ""
echo "Common issues:"
echo "  1. Config file has errors"
echo "  2. Servers can't bind to ports (already in use)"
echo "  3. Shared memory errors"
echo ""
