// COMPLETE EXAMPLE: Integrating All Improvements
// This shows how to use all the reliability features together

#include <grpcpp/grpcpp.h>
#include "minitwo.grpc.pb.h"
#include <iostream>
#include <vector>

// Example: Complete reliable client with all features
int main(int argc, char** argv) {
    
    std::cout << "=== Reliable Client Demo ===" << std::endl;
    
    // 1. Create client with retry capability
    std::string gateway = "localhost:50050";
    auto channel = grpc::CreateChannel(gateway, grpc::InsecureChannelCredentials());
    auto stub = mini2::ClientGateway::NewStub(channel);
    
    // 2. Prepare request
    mini2::Request req;
    req.set_request_id("demo-request-123");
    req.set_query("data_1m.csv");
    req.set_need_green(true);
    req.set_need_pink(true);
    
    // 3. Send request with retry logic
    std::cout << "\nStep 1: Sending request with retry..." << std::endl;
    
    mini2::SessionOpen session;
    bool request_accepted = false;
    int max_attempts = 3;
    
    for (int attempt = 0; attempt < max_attempts; attempt++) {
        std::cout << "  Attempt " << (attempt + 1) << "/" << max_attempts << std::endl;
        
        grpc::ClientContext ctx;
        auto status = stub->StartRequest(&ctx, req, &session);
        
        if (status.ok()) {
            std::cout << "  ✓ Request ACCEPTED! Session: " << session.request_id() << std::endl;
            request_accepted = true;
            break;
        }
        
        std::cerr << "  ✗ Request failed: " << status.error_message() << std::endl;
        
        if (attempt < max_attempts - 1) {
            int delay = 2 << attempt;  // 2, 4, 8 seconds
            std::cout << "  Retrying in " << delay << " seconds..." << std::endl;
            std::this_thread::sleep_for(std::chrono::seconds(delay));
        }
    }
    
    if (!request_accepted) {
        std::cerr << "Failed to send request after " << max_attempts << " attempts!" << std::endl;
        return 1;
    }
    
    // 4. Retrieve results using pull-based approach (firewall-friendly!)
    std::cout << "\nStep 2: Retrieving results (pull-based)..." << std::endl;
    
    std::vector<std::string> chunks;
    uint32_t index = 0;
    uint64_t total_bytes = 0;
    
    while (true) {
        grpc::ClientContext ctx;
        mini2::NextChunkReq next_req;
        next_req.set_request_id(session.request_id());
        next_req.set_next_index(index);
        
        mini2::NextChunkResp resp;
        auto status = stub->GetNext(&ctx, next_req, &resp);
        
        if (!status.ok()) {
            std::cerr << "  ✗ GetNext failed: " << status.error_message() << std::endl;
            
            // Could retry here too!
            std::cout << "  Retrying chunk " << index << "..." << std::endl;
            std::this_thread::sleep_for(std::chrono::seconds(1));
            continue;
        }
        
        if (!resp.chunk().empty()) {
            chunks.push_back(resp.chunk());
            total_bytes += resp.chunk().size();
            std::cout << "  ✓ Retrieved chunk " << index 
                      << " (" << resp.chunk().size() << " bytes)" << std::endl;
        }
        
        if (!resp.has_more()) {
            std::cout << "  ✓ All chunks received!" << std::endl;
            break;
        }
        
        index++;
    }
    
    // 5. Summary
    std::cout << "\n=== Summary ===" << std::endl;
    std::cout << "Session ID: " << session.request_id() << std::endl;
    std::cout << "Total chunks: " << chunks.size() << std::endl;
    std::cout << "Total bytes: " << total_bytes << std::endl;
    std::cout << "Status: SUCCESS ✓" << std::endl;
    
    std::cout << "\n=== Key Features Demonstrated ===" << std::endl;
    std::cout << "✓ Request retry with exponential backoff" << std::endl;
    std::cout << "✓ Pull-based result retrieval (firewall-friendly)" << std::endl;
    std::cout << "✓ Graceful error handling" << std::endl;
    std::cout << "✓ Client-initiated connections only (no callbacks)" << std::endl;
    std::cout << "✓ Session-based async processing" << std::endl;
    
    return 0;
}

/*
 * HOW THIS ADDRESSES THE QUESTIONS:
 * 
 * 1. Client exits with pending messages?
 *    - Server has session timeout (5 min) to clean up
 *    - No memory leaks from abandoned sessions
 * 
 * 2. Save to disk? Different host?
 *    - Session ID allows reconnection from any host
 *    - Client stores session ID, can resume later
 *    - (Optional: server persists sessions to disk)
 * 
 * 3. Know message was accepted?
 *    - Check status.ok() for RPC success
 *    - Session ID returned = definite acceptance
 *    - Could enhance with RequestAck message
 * 
 * 4. Retain and resend if not accepted?
 *    - YES! Retry loop with exponential backoff
 *    - Attempt 1: immediate
 *    - Attempt 2: 2 sec delay
 *    - Attempt 3: 4 sec delay
 * 
 * 5. How receive reply?
 *    - GetNext() pulls chunks one by one
 *    - Client controls polling rate
 *    - No blocking on server side
 * 
 * 6. Callbacks? Firewalls?
 *    - NO CALLBACKS! All client-initiated
 *    - Pull-based: client calls GetNext() repeatedly
 *    - Works through any firewall/NAT
 */
