#!/bin/bash
# Real Data Processing Test - All 6 nodes coordinate to process dataset

DATASET_PATH="/Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/merged.csv"

echo "Real Data Processing Test"
echo "=================================================="
echo ""
echo "Dataset: $DATASET_PATH"
echo ""
echo "Coordination:"
echo "  Process A (Leader) -> Forwards request to team leaders B and E"
echo "  Process B (Green Team Leader) -> Forwards to worker C"
echo "  Process C (Worker) -> Processes 1/3 of dataset, sends to B"
echo "  Process E (Pink Team Leader) -> Forwards to workers D and F"
echo "  Process D (Worker) -> Processes 1/3 of dataset, sends to E"
echo "  Process F (Worker) -> Processes 1/3 of dataset, sends to E"
echo "  Team leaders aggregate and send back to A"
echo "  Process A aggregates all results and returns to client"
echo ""
echo "=================================================="
echo ""

cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp

echo "Running request with BOTH teams (all 6 nodes active)"
echo ""
./mini2_client --mode request --dataset "$DATASET_PATH"

# echo ""
# echo "Test complete"
# echo ""
# echo "Server logs show:"
# echo "  - Dataset loading on-demand (when first request arrives)"
# echo "  - Request forwarding (A -> B and E)"
# echo "  - Worker coordination (B -> C, E -> D and F)"
# echo "  - Data processing (C, D, F processing their chunks)"
# echo "  - Result aggregation (all flowing back to A)"
# echo ""
# echo "To use a different dataset:"
# echo "  ./mini2_client --mode request --dataset /path/to/your/data.csv"

