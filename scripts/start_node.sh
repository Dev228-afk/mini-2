#!/usr/bin/env bash
# Script to help you start each server process
# Run this in each of your 6 terminals

if [ $# -ne 1 ]; then
    echo "Usage: $0 <node_id>"
    echo "Example: $0 A"
    echo ""
    echo "Available nodes: A, B, C, D, E, F"
    exit 1
fi

NODE=$1

cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp

echo "========================================="
echo "Starting Process $NODE"
echo "========================================="
echo ""

case $NODE in
    A) echo "Role: LEADER (Team Green)" ;;
    B) echo "Role: TEAM_LEADER (Team Green)" ;;
    C) echo "Role: WORKER (Team Green)" ;;
    D) echo "Role: TEAM_LEADER (Team Pink)" ;;
    E) echo "Role: TEAM_LEADER (Team Pink)" ;;
    F) echo "Role: WORKER (Team Pink)" ;;
    *) echo "Unknown node: $NODE"; exit 1 ;;
esac

echo ""
./mini2_server --config ../../../config/network_setup.json --node $NODE
