#include <map>
#include <string>

#include "test_inst.hpp"
#include "Vdecode.h"

class VdecodeForTest : public Vdecode {
   public:
    VdecodeForTest() : Vdecode() {}
    ~VdecodeForTest() {}

    INST_BIT inst_bit;
    Inst inst;
    void set_inst_code(uint32_t inst_code);
};