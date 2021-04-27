#include <verilated.h>
#include "systemc"

using namespace sc_core;

vluint64_t vl_time_stamp64() { return static_cast<vluint64_t>(sc_time_stamp().value()); }

