
#define PATH_TO_TESQF Tesqf##\

#include "tesqf_macro.hpp"

TGVAR(LogLevel) = TLOG_LEVEL_DEBUG;

TESQF_COMPILE_FUNCTION(fnc_TestSuite);
TESQF_COMPILE_FUNCTION(fnc_Runner);
TESQF_COMPILE_FUNCTION(fnc_Reporter);

Tesqfy = TFUNC(Runner);
