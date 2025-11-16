#ifndef MEMORY_TRACKER_H
#define MEMORY_TRACKER_H

#include <string>
#include <cstdint>
#include <vector>

// Simple memory info structure
struct MemoryInfo {
    uint64_t rss_bytes;      // Process memory from OS
    std::string node_id;
    
    double rss_mb() const { 
        return rss_bytes / (1024.0 * 1024.0); 
    }
};

// Simple function to get current process memory (cross-platform)
uint64_t GetProcessMemory();

// Format memory info for display
std::string FormatMemoryMB(uint64_t bytes);

// Calculate total memory across multiple nodes
uint64_t CalculateTotalMemory(const std::vector<MemoryInfo>& nodes);

#endif // MEMORY_TRACKER_H
