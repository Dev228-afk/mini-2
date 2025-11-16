
#!/usr/bin/env bash
set -euo pipefail
CONFIG="config/network_setup.json"
mode="${1:-local}"

declare -a pids=()
for node in A B C D E F; do
  ./build/src/cpp/mini2_server --config "$CONFIG" --node "$node" &
  pids+=($!)
done
echo "PIDs: ${pids[*]}"
echo "All servers started. Press Ctrl+C to stop."
wait
