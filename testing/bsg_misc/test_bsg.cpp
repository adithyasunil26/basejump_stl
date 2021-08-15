#include <verilated.h>

#include "Vtest_bsg.h"
#include "bsg_nonsynth_dpi_clock_gen.hpp"
using namespace bsg_nonsynth_dpi;

int main(int argc, char** argv, char** env) {
  Vtest_bsg* tb=new Vtest_bsg;
  tb->eval();
  
  while (!Verilated::gotFinish()) {
    bsg_timekeeper::next();
    tb->eval();
  }

  Verilated::coveragep()->write("coverage.dat");

  printf("Executing final\n");
  tb->final();

  printf("Exiting\n");
  exit(EXIT_SUCCESS);
}
