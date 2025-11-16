#!/bin/bash
# Quick test with small dataset to verify row counting

DATASET_PATH="/Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/merged.csv"

echo "🧪 Testing with small dataset (merged.csv)"
echo "==========================================================="
echo ""

# Count actual rows
ACTUAL_ROWS=$(tail -n +2 "$DATASET_PATH" | wc -l | tr -d ' ')
echo "📊 Actual rows in file: $ACTUAL_ROWS"
echo ""

cd /Users/spartan/Desktop/CMPE275/mini_2/build/src/cpp

echo "Testing with small dataset..."
./mini2_client --mode request --dataset "$DATASET_PATH"

echo ""
echo "Expected: ~$ACTUAL_ROWS rows total"
echo "Check if reported rows match actual!"
