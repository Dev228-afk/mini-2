#include "src/cpp/server/DataProcessor.h"
#include <iostream>

int main() {
    std::string dataset_path = "/Users/spartan/Desktop/CMPE275/mini_1/Data/2020-fire/merged.csv";
    
    std::cout << "Testing DataProcessor with: " << dataset_path << std::endl;
    
    DataProcessor processor(dataset_path);
    
    std::cout << "Loading dataset..." << std::endl;
    if (!processor.LoadDataset()) {
        std::cerr << "Failed to load dataset!" << std::endl;
        return 1;
    }
    
    std::cout << "Total rows loaded: " << processor.GetTotalRows() << std::endl;
    std::cout << "Header: " << processor.GetHeader().substr(0, 100) << "..." << std::endl;
    
    // Test getting a small chunk
    auto chunk = processor.GetChunk(0, 10);
    std::cout << "Got chunk of " << chunk.size() << " rows" << std::endl;
    if (!chunk.empty()) {
        std::cout << "First row: " << chunk[0].GetRaw().substr(0, 100) << "..." << std::endl;
    }
    
    return 0;
}
