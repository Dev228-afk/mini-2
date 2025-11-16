// Example: Adding Session Timeout and Cleanup to SessionManager
// This prevents memory leaks when clients exit unexpectedly

#pragma once

#include "minitwo.grpc.pb.h"
#include <string>
#include <vector>
#include <map>
#include <mutex>
#include <chrono>
#include <condition_variable>
#include <thread>

class SessionManager {
public:
    SessionManager();
    ~SessionManager();
    
    // Existing methods
    std::string CreateSession(const mini2::Request& req);
    void AddChunk(const std::string& session_id, const mini2::WorkerResult& result);
    bool GetNextChunk(const std::string& session_id, uint32_t index, 
                      mini2::NextChunkResp* resp);
    bool PollNextChunk(const std::string& session_id, mini2::PollResp* resp);
    void CompleteSession(const std::string& session_id);
    void CleanupSession(const std::string& session_id);
    
    // NEW: Automatic cleanup of stale sessions
    void StartCleanupThread();
    void StopCleanupThread();

private:
    struct Session {
        std::string request_id;
        std::vector<mini2::WorkerResult> chunks;
        bool complete = false;
        uint32_t next_poll_index = 0;
        std::chrono::steady_clock::time_point created_at;
        std::chrono::steady_clock::time_point last_access;  // NEW: Track last access
        std::mutex mutex;
        std::condition_variable cv;
    };
    
    std::map<std::string, Session> sessions_;
    std::mutex sessions_mutex_;
    
    // NEW: Cleanup thread
    std::thread cleanup_thread_;
    bool cleanup_running_ = false;
    std::chrono::seconds session_timeout_{300};  // 5 minutes default
    
    void CleanupThreadFunc();
    void CleanupStaleSessions();
    std::string GenerateSessionId();
};
