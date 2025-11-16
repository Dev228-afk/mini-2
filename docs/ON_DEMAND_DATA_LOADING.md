# On-Demand Data Loading - Usage Guide

## Overview
The system now supports **flexible, on-demand dataset loading**. No dataset paths are hardcoded - the client specifies which CSV file to process via the `Request.query` field.

## How It Works

### 1. **Client Sends Dataset Path**
```bash
./mini2_client --mode request --dataset /path/to/your/data.csv
```

### 2. **Request.query Field Contains Path**
```cpp
mini2::Request req;
req.set_query("/path/to/data.csv");  // Dataset path
req.set_need_green(true);
req.set_need_pink(true);
```

### 3. **Servers Load On-Demand**
- When a request arrives, team leaders and workers check `req.query()`
- If dataset not loaded yet, they load it: `LoadDataset(req.query())`
- Dataset is cached for subsequent requests
- Supports **any CSV file** with proper format

## Usage Examples

### Test with Fire Dataset
```bash
# Use the fire dataset
./mini2_client --mode request \
  --dataset /Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/unique_2020_fire_data.csv
```

### Test with Mock Data (No Dataset)
```bash
# Empty query = use mock data (Phase 2 behavior)
./mini2_client --mode request
```

### Test with Custom CSV
```bash
# Any CSV file with proper format
./mini2_client --mode request --dataset /path/to/your/custom_data.csv
```

### Using the Test Script
```bash
# Script automatically uses fire dataset
./scripts/test_real_data.sh

# Or edit DATASET_PATH in the script for different data
```

## CSV Format Requirements

Your CSV file should have:
- **Header row** (will be skipped)
- **Data rows** with comma-separated values
- Minimum fields expected by DataProcessor:
  - Latitude, Longitude, UTC, Parameter, Concentration, Unit, etc.

Example:
```csv
Latitude,Longitude,UTC,Parameter,Concentration,Unit,RawConcentration,AQI,Category,SiteName,SiteAgency,AQSID,FullAQSID
35.0186,-106.651901,9/10/20 21:00,NO2,1.7,PPB,1.7,1.0,1.0,South Valley,Albuquerque Environmental Health Department,350010029,8.4035E+11
...
```

## Architecture

### Data Flow
```
Client (with --dataset path)
  ↓
  Request.query = "/path/to/data.csv"
  ↓
Process A (Leader) → Forwards request
  ↓
Team Leaders B & E
  ↓ Check req.query()
  ↓ LoadDataset() if not loaded
  ↓ Forward to workers
  ↓
Workers C, D, F
  ↓ Check req.query()
  ↓ LoadDataset() if not loaded
  ↓ Process their chunk
  ↓ Send results back
```

### Data Distribution
- **Green Team (B + C)**: Worker C processes rows 0-33
- **Pink Team (E + D + F)**: 
  - Worker D processes rows 34-66
  - Worker F processes rows 67-100

## Benefits

✅ **Flexible**: Works with any CSV file
✅ **No Hardcoding**: Dataset path comes from client request
✅ **On-Demand**: Loads only when needed, not at startup
✅ **Cached**: Once loaded, reused for subsequent requests
✅ **Scalable**: Easy to test different datasets without recompiling

## Testing Different Datasets

### Fire Dataset (100 rows)
```bash
./mini2_client --mode request \
  --dataset /Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/unique_2020_fire_data.csv
```
Expected: ~4.5MB combined, ~107ms latency

### Large Dataset (if you have one)
```bash
./mini2_client --mode request \
  --dataset /path/to/large_dataset.csv
```
Message size limit: 100MB (configurable in ServerMain.cpp and ClientMain.cpp)

### Phase 2 Mock Data
```bash
# No dataset = use mock data generator
./mini2_client --mode request
```
Expected: ~1KB mock data, ~14-20ms latency

## Configuration

### Adjust Message Size Limits
If your dataset produces messages > 100MB:

**ServerMain.cpp:**
```cpp
b.SetMaxReceiveMessageSize(500 * 1024 * 1024); // 500MB
b.SetMaxSendMessageSize(500 * 1024 * 1024);
```

**ClientMain.cpp:**
```cpp
args.SetMaxReceiveMessageSize(500 * 1024 * 1024); // 500MB
args.SetMaxSendMessageSize(500 * 1024 * 1024);
```

Then rebuild: `./scripts/build.sh`

## Troubleshooting

### "Cannot open dataset" Error
- Check file path is absolute (not relative)
- Verify file exists: `ls -l /path/to/data.csv`
- Check file permissions: `chmod 644 /path/to/data.csv`

### "Message larger than max" Error
- Increase message size limits (see Configuration above)
- Or use smaller dataset chunks

### Mock Data Instead of Real Data
- Verify `--dataset` parameter is passed
- Check server logs for "Loading dataset from query: ..."
- Ensure Request.query field is set properly

## Summary

**Key Point**: The system is now **completely flexible** - no hardcoded paths, dataset specified per-request via `--dataset` parameter, loaded on-demand by workers and team leaders.
