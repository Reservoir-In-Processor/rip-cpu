#include <map>
#include <string>

#include "test_inst.hpp"
#include "Vdecode.h"

class VdecodeForTest : public Vdecode {
   public:
    VdecodeForTest() : Vdecode() {}
    ~VdecodeForTest() {}

    Inst _inst;
    inst_bit_t _inst_bit;
    void set_inst_code(uint32_t);
    std::string get_inst_name();
    bool get_ctrl_signal(std::string);
};