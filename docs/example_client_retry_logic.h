// Example: Client-Side Request Tracking and Retry Logic
// Student-friendly implementation for handling failures

#pragma once
#include <string>
#include <map>
#include <vector>
#include <mutex>
#include <chrono>
#include "minitwo.grpc.pb.h"

// Track pending requests on the client side
struct PendingRequest {
    std::string request_id;
    mini2::Request original_request;
    bool acknowledged = false;
    std::chrono::steady_clock::time_point sent_at;
    int retry_count = 0;
    int max_retries = 3;
};

// Simple client-side tracker to manage pending requests
class ClientRequestTracker {
public:
    // Add a request to track
    void TrackRequest(const std::string& request_id, const mini2::Request& req) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        PendingRequest pr;
        pr.request_id = request_id;
        pr.original_request = req;
        pr.sent_at = std::chrono::steady_clock::now();
        pr.acknowledged = false;
        pr.retry_count = 0;
        
        pending_[request_id] = pr;
        
        std::cout << "[Tracker] Tracking request: " << request_id << std::endl;
    }
    
    // Mark request as successfully acknowledged
    void MarkAcknowledged(const std::string& request_id) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (pending_.count(request_id)) {
            pending_[request_id].acknowledged = true;
            std::cout << "[Tracker] Request acknowledged: " << request_id << std::endl;
        }
    }
    
    // Remove request from tracking (completed or failed)
    void RemoveRequest(const std::string& request_id) {
        std::lock_guard<std::mutex> lock(mutex_);
        pending_.erase(request_id);
        std::cout << "[Tracker] Removed request: " << request_id << std::endl;
    }
    
    // Get all unacknowledged requests
    std::vector<PendingRequest> GetUnacknowledged() {
        std::lock_guard<std::mutex> lock(mutex_);
        
        std::vector<PendingRequest> unacked;
        for (const auto& pair : pending_) {
            if (!pair.second.acknowledged) {
                unacked.push_back(pair.second);
            }
        }
        return unacked;
    }
    
    // Increment retry count
    void IncrementRetry(const std::string& request_id) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (pending_.count(request_id)) {
            pending_[request_id].retry_count++;
        }
    }
    
    // Check if request can be retried
    bool CanRetry(const std::string& request_id) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (!pending_.count(request_id)) return false;
        
        return pending_[request_id].retry_count < pending_[request_id].max_retries;
    }
    
    // Get statistics
    void PrintStats() {
        std::lock_guard<std::mutex> lock(mutex_);
        
        int total = pending_.size();
        int acked = 0;
        int unacked = 0;
        
        for (const auto& pair : pending_) {
            if (pair.second.acknowledged) {
                acked++;
            } else {
                unacked++;
            }
        }
        
        std::cout << "\n=== Request Tracker Stats ===" << std::endl;
        std::cout << "Total: " << total << std::endl;
        std::cout << "Acknowledged: " << acked << std::endl;
        std::cout << "Pending: " << unacked << std::endl;
        std::cout << "============================\n" << std::endl;
    }

private:
    std::map<std::string, PendingRequest> pending_;
    std::mutex mutex_;
};

// Example: Client with retry logic
class ReliableClient {
public:
    ReliableClient(const std::string& gateway_addr) 
        : gateway_addr_(gateway_addr) {
        auto channel = grpc::CreateChannel(gateway_addr_, grpc::InsecureChannelCredentials());
        stub_ = mini2::ClientGateway::NewStub(channel);
    }
    
    // Send request with automatic retry
    bool SendRequestWithRetry(mini2::Request& req) {
        std::string req_id = req.request_id();
        tracker_.TrackRequest(req_id, req);
        
        int max_attempts = 3;
        
        for (int attempt = 0; attempt < max_attempts; attempt++) {
            std::cout << "\n[Client] Attempt " << (attempt + 1) << "/" << max_attempts 
                      << " for request: " << req_id << std::endl;
            
            grpc::ClientContext ctx;
            mini2::SessionOpen session;
            
            // Try to start the request
            auto status = stub_->StartRequest(&ctx, req, &session);
            
            if (status.ok()) {
                std::cout << "[Client] Request accepted! Session: " << session.request_id() << std::endl;
                tracker_.MarkAcknowledged(req_id);
                return true;
            }
            
            // Request failed
            std::cerr << "[Client] Request failed: " << status.error_message() << std::endl;
            tracker_.IncrementRetry(req_id);
            
            // Wait before retry (exponential backoff)
            if (attempt < max_attempts - 1) {
                int delay_sec = 2 << attempt;  // 2, 4, 8 seconds
                std::cout << "[Client] Retrying in " << delay_sec << " seconds..." << std::endl;
                std::this_thread::sleep_for(std::chrono::seconds(delay_sec));
            }
        }
        
        // Failed after all retries
        std::cerr << "[Client] Request " << req_id << " FAILED after " 
                  << max_attempts << " attempts" << std::endl;
        tracker_.RemoveRequest(req_id);
        return false;
    }
    
    // Get results using GetNext
    bool RetrieveResults(const std::string& session_id, std::vector<std::string>& chunks) {
        uint32_t index = 0;
        
        while (true) {
            grpc::ClientContext ctx;
            mini2::NextChunkReq req;
            req.set_request_id(session_id);
            req.set_next_index(index);
            
            mini2::NextChunkResp resp;
            auto status = stub_->GetNext(&ctx, req, &resp);
            
            if (!status.ok()) {
                std::cerr << "[Client] GetNext failed: " << status.error_message() << std::endl;
                return false;
            }
            
            if (!resp.chunk().empty()) {
                chunks.push_back(resp.chunk());
                std::cout << "[Client] Retrieved chunk " << index 
                          << " (" << resp.chunk().size() << " bytes)" << std::endl;
            }
            
            if (!resp.has_more()) {
                std::cout << "[Client] All chunks retrieved!" << std::endl;
                break;
            }
            
            index++;
        }
        
        return true;
    }
    
    void PrintStats() {
        tracker_.PrintStats();
    }

private:
    std::string gateway_addr_;
    std::unique_ptr<mini2::ClientGateway::Stub> stub_;
    ClientRequestTracker tracker_;
};
