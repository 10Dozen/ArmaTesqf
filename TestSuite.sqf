// This is Test Suite example

// Include Tesfy macro (as specific include or as part of your other includes)
#include "Tesqf\tesqf_macro.hpp"

// Suite header with suite name (will be used in reporting)
__SUITE("My Test Suite")

// Optional Tags section
// Format: One tag per line, no separators
// If there is no any Suite's tags in Test's tags section - test will be skipped
__TAGS__
Common
__TAGS_ENDS__


// List of TestCases files included into TestSuite
// Format: Paths to test files, one file per line, no separators
__FILES__
tests\MyTest1.sqf
__FILES_ENDS__

// List of TestSuite execution options
// Format: key-value pairs, one pair per line, no separators
__OPTIONS__
output: rpt, diary, systemChat;
instant_fail: false;
__OPTIONS_ENDS__


// End ot test suite definition
// (this macro will return defined options to Tesqfy function on TestSuite creation)
__SUITE_ENDS__
