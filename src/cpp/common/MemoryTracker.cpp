#include "MemoryTracker.h"
#include <sstream>
#include <iomanip>

// Platform-specific includes for memory measurement
#ifdef _WIN32
#include <windows.h>
#include <psapi.h>
#elif defined(__APPLE__)
#include <mach/mach.h>
#else
#include <unistd.h>
#include <fstream>
#endif

// Get current process memory usage (cross-platform)
uint64_t GetProcessMemory() {
#ifdef _WIN32
    // Windows
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
        return pmc.WorkingSetSize;
    }
    return 0;
    
#elif defined(__APPLE__)
    // macOS
    struct mach_task_basic_info info;
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
    if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO,
                  (task_info_t)&info, &count) == KERN_SUCCESS) {
        return info.resident_size;
    }
    return 0;
    
#else
    // Linux - read from /proc/self/stat
    std::ifstream stat_file("/proc/self/stat");
    if (!stat_file.is_open()) {
        return 0;
    }
    
    // Skip to RSS field (field 24)
    std::string ignore;
    uint64_t rss;
    for (int i = 0; i < 23; i++) {
        stat_file >> ignore;
    }
    stat_file >> rss;
    stat_file.close();
    
    // RSS is in pages, convert to bytes
    long page_size = sysconf(_SC_PAGESIZE);
    return rss * page_size;
#endif
}

// Format bytes as MB string
std::string FormatMemoryMB(uint64_t bytes) {
    std::stringstream ss;
    ss << std::fixed << std::setprecision(2);
    ss << (bytes / (1024.0 * 1024.0)) << "MB";
    return ss.str();
}

// Calculate total memory from all nodes (simple sum)
uint64_t CalculateTotalMemory(const std::vector<MemoryInfo>& nodes) {
    uint64_t total = 0;
    for (const auto& node : nodes) {
        total += node.rss_bytes;
    }
    return total;
}
