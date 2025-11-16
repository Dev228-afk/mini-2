
#include <cassert>
#include "../src/cpp/common/config.h"

int main(){
    auto cfg = LoadConfig("config/network_setup.json");
    assert(cfg.nodes.size()==6);
    return 0;
}
