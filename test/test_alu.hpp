#include <map>
#include <string>

#include "Valu.h"
#include "test_inst.hpp"

class ValuForTest : public Valu {
public:
  ValuForTest() : Valu() {}
  ~ValuForTest() {}

  void exec(const inst_bit_t &_inst_bit, const int &_rs1, const int &_rs2,
            const int &_pc, const int &_csr, const int &_imm,
            const unsigned char &_zimm);
  int get_rslt();
};
