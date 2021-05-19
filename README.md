# ArmaTesqf
Arma 3 in-game SQF testing framework.
Tesqf allows creation of Test Suite with number of Test Cases to run. Each test case result will be then reported and some basic run statistics will be gathered. 

### Requirements:
CBA_A3


### Installation
Put `Tesqf` folder to mission folder and execute file via (e.g. at the first line of `init.sqf`):
```sqf
call compile preProcessFileLineNumbers "Tesqf\initTesqf.sqf";
```

### Usage
There are 3 basic steps to use Tesqf:
1. Create TestCases
2. Create TestSuite and include TestCases in it 
3. Start Arma 3 mission and execute TestSuite 

## Test Case
Test Case (TC) is the script file of specific structure. TC code will be executed in scheduled environemnt (`uiSleep`/`sleep` commands are allowed in code).

### Test case structure
Test Case is normal SQF file which will be executed as is. Bunch of macroses are used to make TC file more structured and to hide some framework related logic. Ensure that all mandatory macroses are present in your TC and not malformed. From other side - it's normal sqf - you can put some function/variable definitions inside, access global variables of your code and so on.

See `TestCase.sqf` for example.


(M) - mandatory - this piece of code should always present in TC file in the specific position.<br>
(O) - optional - macro may be not used, but if used - it should be in the specific position.


#### Imports (M)
TC should always include Tesqf Macro file as separate include or as part of other includes. 
```sqf
#include "Tesqf\tesqf_macro.hpp"
```

#### Section: Name (M)
TC should always start from `__TESTCASE()` macro which declares test case's name for futher use in framework.
```sqf
__TESTCASE("My Test")
```
Test name will be available under `_TEST_NAME` macro.

#### Section: Tags (O)
TC may contain `__TAGS__` section and `__VALIDATE_TAGS` directive.
Tags are used to mark test as related to some group (e.g. ACE-related). When used with `__VALIDATE_TAGS` directive (optional) - test will skipped if test has no tags declared in running Test Suite.

Format: one tag per line, no separators; tag may be commented by `//`

```sqf
__TAGS__
Common
ACE
//MyTag <-- This tag will be ignored
__TAGS_ENDS__
__VALIDATE_TAGS
```

#### Section: Before (O)
Before section marks some pre-condition code - piece of code that prepares tested objects/data for test.

By the nature this section is `try { ... } catch {}` block which stops futher execution and mark test as 'Crashed' in execution results, if exception was thrown by code (this means only exception thrown manually by https://community.bistudio.com/wiki/throw command).

Be aware, that this section is _nested_ code block, which means that any local variable declared inside the block will not be available outside the section.

```sqf
__BEFORE__
    <... precondition ...>
    if (<...precondition not set ...>) throw "Pre-condition not set!";
__BEFORE_ENDS__
```

#### Section: Test (O)
Test section marks code of the some single test. You can have as many `__TEST__` sections as you need, all will be executed, but whole test will be marked as Failed if any test section will fail.

To make result validation use one of the `ASSERT_*` macro, which fails test if results not match expected values. See XXX for details.

By the nature this section `try { ... } catch {}` block, if exception is thrown by the code - marks test as 'Crashed', but doesn't stop execution (this allows to execute other `__TEST__` and `__AFTER__` sections).

Be aware, that this section is _nested_ code block, which means that any local variable declared inside the block will not be available outside the section.

```sqf
__TEST__
    <... test code ...>
    
    private _number = 10;
    private _result = true;

    ASSERT_TRUE("Result is not true!", _result);
    ASSERT_FALSE("Result is true!", !_result);
    ASSERT_EQUALS("Number is not the same!",_number,10);
    ASSERT_NOT_EQUALS("Number is the same!",_number,22);
__TEST_ENDS__
```

#### Section: After (O)
After section marks some post-condition code - piece of code that restores data changed for test, deletes objects created during the test, etc..

By the nature this section `try { ... } catch {}` block.

Be aware, that this section is _nested_ code block, which means that any local variable declared inside the block will not be available outside the section.

```sqf
__AFTER__
    <... post-condition ...>
__AFTER_ENDS__
```

### Assertions
Assertion macro checks given condition, if validation failed - Test Failed event will be raised and test section will be exited.

By the nature assertions are `if <validate condition> exitWith { <raise event> }` blocks, so there are several limitations present:
* arrays literals (e.g. `[1,2,3]`) are not allowed to use in assertion
* assertion should not be placed inside other code blocks (like `for`, `foreach`, `if`, `switch`, `call`, etc.)

There are 4 pre-defined assertions:

##### ASSERT_TRUE(\<Message\>,\<Boolean\>)
Validates that given `<Boolean>` is True. If failed - Test Failed event raised with given `<Message>` as annotation.

##### ASSERT_FALSE(\<Message\>,\<Boolean\>)
Validates that given `<Boolean>` is False. If failed - Test Failed event raised with given `<Message>` as annotation.

##### ASSERT_EQUALS(\<Message\>,\<Variable1\>,\<Variable2\>)
Validates that given `<Variable1>` is equal to `<Variable2>`. If failed - Test Failed event raised with given `<Message>` as annotation.

##### ASSERT_NOT_EQUALS(\<Message\>,\<Variable1\>,\<Variable2\>)
Validates that given `<Variable1>` is not equal to `<Variable2>`. If failed - Test Failed event raised with given `<Message>` as annotation.

##### Manual handle
You can manually handle result validation and then raise event by code:
```sqf
[
    EVENT_TEST_FAILED, 
    [
        _TEST_NAME,
        format ["%1:%2",__FILE__,__LINE__],
        "Validation message",
        "Condition validation details message"
    ]
] call CBA_fnc_localEvent;
breakOut ""; // If you want to also exit __TEST__ section
```

### Logging
There is basic logging system is included in Tesqf.

Default logging level is set in `Tesqf\InitTesqf.sqf` as `TGVAR(LogLevel)` variable. There are several logs levels available under next macroses:

| Level | Constant | Description |
|---|---|----|
| -1 | TLOG_LEVEL_NONE | No logging |
| 0 | TLOG_LEVEL_ERROR | Errors logs only |
| 1 | TLOG_LEVEL_WARN | Errors and Warnings logs |
| 2 | TLOG_LEVEL_INFO | Errors, Warning and Info logs |
| 3 | TLOG_LEVEL_DEBUG | All logs |

In Test case code logging macroses available by using next format:
```sqf
// One-liner
<LOG_MACRO> "Message %1",_param1,...,_paramN _EOL

// Multi-line
<LOG_MACRO> "Message %1 %2 %3",
            _param1,
            _param2,
            _param3
_EOL
```
where:
<br>**a)** `<LOG_MACRO>` is one of the:
| Macro | Min. log level |
|---|---|----|
| ERR_<br>ERROR_ | TLOG_LEVEL_ERROR |
| WARN_ | TLOG_LEVEL_WARN |
| INFO_<br>LOG_ | TLOG_LEVEL_INFO |
| DEBUG_<br>DBG_ | TLOG_LEVEL_DEBUG |
<br>**b)** Message and formatting parametes; e.g. _"Message %1 %2",100,[1,2,3]_ will result in message _"Message 100 [1,2,3]"_
<br>**c)** `_EOL` macro marks end of log line


### Tricks & Tips
#### Parameterized test
You can execute single test multiple times with different parameters. To make so - just add array and put `__TEST__` section in `apply` (https://community.bistudio.com/wiki/apply) block.
For example:
```sqf
...

[
    [100,200],
    [5,10],
    [-1,-2]
] apply {
__TEST__
    _x params ["_input","_expected"];
    private _result = _input * 2;

    ASSERT_EQUALS("Result not match!",_result,_expected);
__TEST_ENDS__
};

...

```
This code will execute test 3 times with 3 sets of data.


## Test Suite 

## Execution
