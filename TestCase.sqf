// This is Test Case example

// Include Tesfy macro (as specific include or as part of your other includes)
#include "Tesqf\tesqf_macro.hpp"

// Test header with test name (will be used in reporting)
__TESTCASE("My Test")

// Optional Tags section
// Format: One tag per line, no separators
__TAGS__
Common
__TAGS_ENDS__

// Tags Validation directive:
// if test's tags doesn't match suite's tags - test will be skipped
__VALIDATE_TAGS


// From here - any code may be written and then used inside __BEFORE__, __TEST__ or __AFTER__ blocks
_my_func = { false };


// Before section is mostly for adding some structured view to test,
// but it is try {} catch {} block that may stop test execution if exception was thrown,
// test will be marked as crashed
// This block may be used as some pre-validation for test conditions
__BEFORE__
	player setDamage 0.5;
	if (damage player == 1) throw "Damage precondition is not set";
__BEFORE_ENDS__


// Test section is the place where ASSERT_ macro should be used
// It is also try-catch block that handle exception and mark test as crashed
// Note that there may be several __TEST__ blocks, but whole test will be failed
//  if any __TEST__ block fails
__TEST__
	[player] call _my_func;
	// Assertions may raise TestFailed event (which will mark test as failed)
	// and stop __TEST__ block execution
	ASSERT_EQUALS("Not healed!",damage player,0);
__TEST_ENDS__


// After section is for adding some structured view for test.
// Some post-condition code may be stored here and executed after all __TEST__ sections
__AFTER__
	player setDamage 0;
__AFTER_ENDS__
