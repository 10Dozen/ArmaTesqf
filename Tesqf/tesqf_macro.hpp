
// --- Enums ---
#define EVENT_TEST_STARTED QTGVAR(TestStarted)
#define EVENT_TEST_PASSED QTGVAR(TestPassed)
#define EVENT_TEST_FAILED QTGVAR(TestFailed)
#define EVENT_TEST_CRASHED QTGVAR(TestException)
#define EVENT_TEST_SKIPPED QTGVAR(TestSkipped)

#define EVENT_SUITE_STARTED QTGVAR(TestSuiteStarted)
#define EVENT_SUITE_FINISHED QTGVAR(TestSuiteFinished)

#define STATE_PASS "Passed"
#define STATE_SKIP "Skipped"
#define STATE_CRASH "Crashed"
#define STATE_FAIL "Failed"
#define STATE_NOT_RUN "Not run"

#define TESQF_SUBJECT "Tesqfy"
#define TESQF_RUNNER_TOPIC "Tesqf Runner"


// --- Common ---
#ifndef QUOTE
	#define QUOTE(X) #X
#endif

#define DBL(X,Y) X##Y
#define TRPL(X,Y,Z) DBL(DBL(X,Y),Z)
#define QUAD(X,Y,Z,K) DBL(TRPL(X,Y,Z),K)

#define COMPONENT Tesqf
#define QCOMPONENT QUOTE(COMPONENT)
#define TGVAR(X) TRPL(COMPONENT,_,X)
#define QTGVAR(X) QUOTE(TGVAR(X))
#define TLVAR(X) QUAD(_,COMPONENT,_,X)
#define QTLVAR(X) QUOTE(TLVAR(X))
#define TFUNC(X) TGVAR(DBL(fnc_,X))

#define TESQF_COMPILE_FUNCTION(NAME) TGVAR(NAME) = compile preprocessFileLineNumbers QUOTE(QUAD(PATH_TO_TESQF,\,NAME,.sqf))


// --- Runner object ---
#define RUNNER__SELF TGVAR(Runner)

#define RUNNER__GET_SUITE_BY_ID(ID) ((RUNNER__SELF get "suites") select (ID))
#define RUNNER__SUITE RUNNER__GET_SUITE_BY_ID(RUNNER__SELF get "running_suite_id")
#define RUNNER__SUITE_GET_CURRENT_ID (RUNNER__SELF get "running_suite_id")



// --- Test execution ---
#define _TEST_NAME TLVAR(TestName)

#define FAIL_TEST(__FILE__,MSG,CONDITION) [EVENT_TEST_FAILED,[_TEST_NAME,format ["%1:%2",__FILE__,__LINE__],MSG,CONDITION]] call CBA_fnc_localEvent

#define _IN_TEST_FORMAT_CONDITION(CONDITION) format ["Condition [%1] is %2", QUOTE(CONDITION), CONDITION]
#define _IN_TEST_FORMAT_EQUALS_CONDITION(VAR1,VAR2) format ["%1 is equals %2", VAR1, VAR2]
#define _IN_TEST_FORMAT_NOT_EQUALS_CONDITION(VAR1,VAR2) format ["%1 is not equals %2", VAR1, VAR2]

#define ASSERT_TRUE(MSG,CONDITION) \
	if !(CONDITION) exitWith { \
		FAIL_TEST(__FILE__,MSG,_IN_TEST_FORMAT_CONDITION(CONDITION)); \
	}

#define ASSERT_FALSE(MSG,CONDITION) \
	if (CONDITION) exitWith { \
		FAIL_TEST(__FILE__,MSG,_IN_TEST_FORMAT_CONDITION(CONDITION)); \
	}

#define ASSERT_EQUALS(MSG,VAR1,VAR2) \
	if !(VAR1 isEqualType VAR2 && {VAR1 isEqualTo VAR2}) exitWith { \
		FAIL_TEST(__FILE__,MSG,_IN_TEST_FORMAT_NOT_EQUALS_CONDITION(VAR1,VAR2)); \
	}

#define ASSERT_NOT_EQUALS(MSG,VAR1,VAR2) \
	if (VAR1 isEqualType VAR2 && {VAR1 isEqualTo VAR2}) exitWith { \
		FAIL_TEST(__FILE__,MSG,_IN_TEST_FORMAT_EQUALS_CONDITION(VAR1,VAR2)); \
	}


// --- Test/Suite definition --
#define __TESTCASE(X) _TEST_NAME = X; [EVENT_TEST_STARTED,[X,__FILE__]] call CBA_fnc_localEvent;
#define __SUITE(X) private [QTLVAR(name),QTLVAR(files),QTLVAR(tags),QTLVAR(options)]; TLVAR(name) = X;

#define __SUITE_ENDS__ [TLVAR(name),TLVAR(files),TLVAR(tags),TLVAR(options)]

#define __TAGS__ TLVAR(tags) = "
#define __TAGS_ENDS__ ";

#define __VALIDATE_TAGS \
 	if !(["__VALIDATE_TAGS",_this select 0,TLVAR(tags)] call TFUNC(Runner)) exitWith { \
		[EVENT_TEST_SKIPPED,[_TEST_NAME,__FILE__]] call CBA_fnc_localEvent; \
	};


#define __FILES__ TLVAR(files) = "
#define __FILES_ENDS__ ";

#define __OPTIONS__ TLVAR(options) = "
#define __OPTIONS_ENDS__ ";

#define __BEFORE__ \
	TLVAR(skip) = false; \
	try {

#define __BEFORE_ENDS__ \
	} catch { \
		[EVENT_TEST_CRASHED,[_TEST_NAME,__FILE__,"Exeception on Before",_exception]] call CBA_fnc_localEvent; \
		TLVAR(skip) = true; \
	}; \
	if (TLVAR(skip)) exitWith {};

#define __TEST__ \
	try {

#define __TEST_ENDS__ \
	} catch { \
		[EVENT_TEST_CRASHED,[_TEST_NAME,__FILE__,"Exception on Test",_exception]] call CBA_fnc_localEvent; \
	};

#define __AFTER__ \
	try {

#define __AFTER_ENDS__ \
	} catch {};

// --- Logging ---

// Sets Global log level
#define T_SET_LOG_LEVEL(X) TGVAR(LogLevel) = X

#define TLOG_LEVEL_ERROR 0
#define TLOG_LEVEL_WARN 1
#define TLOG_LEVEL_INFO 2
#define TLOG_LEVEL_DEBUG 3
#define TLOG_LEVEL_NAME(X) (["ERR","WARN","INFO","DEBUG"] select X)

#define T_MESSAGE(LEVEL) ['REPORT_LOG',LEVEL,format["(%1) %2",_TEST_NAME,format[
#define _EOL ]]] call TFUNC(Reporter);

#define ERR_ T_MESSAGE(TLOG_LEVEL_ERROR)
#define ERROR_ T_MESSAGE(TLOG_LEVEL_ERROR)
#define WARN_ T_MESSAGE(TLOG_LEVEL_WARN)
#define LOG_ T_MESSAGE(TLOG_LEVEL_INFO)
#define INFO_ T_MESSAGE(TLOG_LEVEL_INFO)
#define DBG_ T_MESSAGE(TLOG_LEVEL_DEBUG)
#define DEBUG_ T_MESSAGE(TLOG_LEVEL_DEBUG)
