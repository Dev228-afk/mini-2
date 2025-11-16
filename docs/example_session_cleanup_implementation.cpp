// Example: Implementation of Session Timeout and Cleanup
// Add these methods to your existing SessionManager.cpp

#include "SessionManager.h"
#include <iostream>

// Start background cleanup thread
void SessionManager::StartCleanupThread() {
    cleanup_running_ = true;
    cleanup_thread_ = std::thread(&SessionManager::CleanupThreadFunc, this);
    std::cout << "[SessionManager] Cleanup thread started" << std::endl;
}

// Stop cleanup thread
void SessionManager::StopCleanupThread() {
    cleanup_running_ = false;
    if (cleanup_thread_.joinable()) {
        cleanup_thread_.join();
    }
    std::cout << "[SessionManager] Cleanup thread stopped" << std::endl;
}

// Background thread that periodically cleans up stale sessions
void SessionManager::CleanupThreadFunc() {
    while (cleanup_running_) {
        // Sleep for 60 seconds between cleanup runs
        std::this_thread::sleep_for(std::chrono::seconds(60));
        
        if (!cleanup_running_) break;
        
        CleanupStaleSessions();
    }
}

// Clean up sessions that haven't been accessed for timeout duration
void SessionManager::CleanupStaleSessions() {
    auto now = std::chrono::steady_clock::now();
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    
    std::vector<std::string> to_remove;
    
    // Find stale sessions
    for (auto& pair : sessions_) {
        auto& session = pair.second;
        
        // Check if session is stale (no access for timeout duration)
        auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
            now - session.last_access);
        
        if (elapsed > session_timeout_) {
            to_remove.push_back(pair.first);
            std::cout << "[SessionManager] Session " << pair.first 
                      << " is stale (idle for " << elapsed.count() 
                      << " seconds), marking for removal" << std::endl;
        }
    }
    
    // Remove stale sessions
    for (const auto& session_id : to_remove) {
        sessions_.erase(session_id);
        std::cout << "[SessionManager] Removed stale session: " << session_id << std::endl;
    }
    
    if (!to_remove.empty()) {
        std::cout << "[SessionManager] Cleanup complete: removed " 
                  << to_remove.size() << " stale session(s)" << std::endl;
    }
}

// Update existing methods to track last access time

// Modified CreateSession - initialize last_access
std::string SessionManager::CreateSession(const mini2::Request& req) {
    std::string session_id = GenerateSessionId();
    
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    
    auto& session = sessions_[session_id];
    session.request_id = session_id;
    session.created_at = std::chrono::steady_clock::now();
    session.last_access = std::chrono::steady_clock::now();  // NEW
    session.complete = false;
    session.next_poll_index = 0;
    
    std::cout << "[SessionManager] Created session: " << session_id << std::endl;
    
    return session_id;
}

// Modified GetNextChunk - update last_access
bool SessionManager::GetNextChunk(const std::string& session_id, uint32_t index, 
                                   mini2::NextChunkResp* resp) {
    std::unique_lock<std::mutex> lock(sessions_mutex_);
    
    auto it = sessions_.find(session_id);
    if (it == sessions_.end()) {
        std::cerr << "[SessionManager] GetNext: Session not found: " << session_id << std::endl;
        return false;
    }
    
    Session& session = it->second;
    session.last_access = std::chrono::steady_clock::now();  // NEW: Update access time
    lock.unlock();
    
    std::unique_lock<std::mutex> session_lock(session.mutex);
    
    // Wait until chunk is available or session is complete
    while (index >= session.chunks.size() && !session.complete) {
        if (session.cv.wait_for(session_lock, std::chrono::seconds(30)) == std::cv_status::timeout) {
            std::cerr << "[SessionManager] GetNext: Timeout waiting for chunk" << std::endl;
            return false;
        }
    }
    
    // Check if chunk is available
    if (index < session.chunks.size()) {
        const auto& chunk = session.chunks[index];
        resp->set_request_id(session_id);
        resp->set_chunk(chunk.payload());
        resp->set_has_more(index + 1 < session.chunks.size() || !session.complete);
        return true;
    }
    
    // No more chunks and session is complete
    resp->set_request_id(session_id);
    resp->set_has_more(false);
    return true;
}

// Modified PollNextChunk - update last_access
bool SessionManager::PollNextChunk(const std::string& session_id, mini2::PollResp* resp) {
    std::lock_guard<std::mutex> lock(sessions_mutex_);
    
    auto it = sessions_.find(session_id);
    if (it == sessions_.end()) {
        std::cerr << "[SessionManager] PollNext: Session not found: " << session_id << std::endl;
        return false;
    }
    
    Session& session = it->second;
    session.last_access = std::chrono::steady_clock::now();  // NEW: Update access time
    
    std::lock_guard<std::mutex> session_lock(session.mutex);
    
    resp->set_request_id(session_id);
    
    // Check if next chunk is available
    if (session.next_poll_index < session.chunks.size()) {
        const auto& chunk = session.chunks[session.next_poll_index];
        resp->set_ready(true);
        resp->set_chunk(chunk.payload());
        resp->set_has_more(session.next_poll_index + 1 < session.chunks.size() || !session.complete);
        session.next_poll_index++;
        return true;
    }
    
    // No chunk available yet
    resp->set_ready(false);
    resp->set_has_more(!session.complete);
    return true;
}

// Update constructor/destructor to start/stop cleanup thread
SessionManager::SessionManager() {
    std::cout << "[SessionManager] Initialized" << std::endl;
    StartCleanupThread();  // NEW
}

SessionManager::~SessionManager() {
    StopCleanupThread();  // NEW
    std::cout << "[SessionManager] Destroyed" << std::endl;
}
