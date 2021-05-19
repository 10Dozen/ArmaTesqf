
/*
	Runs test suite
*/

#include "tesqf_macro.hpp"

#define SELF TFUNC(Runner)
#define CURRENT_TEST_ID _suite get "current_test.id"

params ["_method",["_arg1", ""],["_arg2", ""],["_arg3", ""],["_arg4", ""]];

private _result = false;

switch toUpper _method do {
	case "RUN": {
		// --- First time init (if running suite by function call, not by Diary topic)
		["__INIT"] call SELF;

		// --- Exit if Runner is busy
		if ((RUNNER__SELF get "state") isNotEqualTo STATE_RUNNER_READY) exitWith {
			private _suite = RUNNER__SUITE;
			hint format [
				"Test Suite [%1] is in progress now.\nProgress: %2 of %3\nPlease, wait for it be finished",
				_suite get "name",
				_suite get "progress",
				_suite get "count"
			];
		};

		private _suite = _arg1;

		if (_suite isEqualType "") then {
			_suite = ["CREATE",_suite] call TFUNC(TestSuite);
		};

		// --- Prepare for execution
		["__PREPARE", _suite] call SELF;

		// --- Async execution of tests
		["__START", _suite] spawn SELF;
	};
	case "ADD": {
		private _suiteFiles = _arg1;
		if (_arg1 isEqualType "") then {
			_suiteFiles = [_arg1];
		};

		["__INIT"] call SELF;
		_suiteFiles apply {
			["ADD_SUITE_TO_RUNNER_CONTROLS",_x] call TFUNC(Reporter);
		};
	};
	case "__INIT": {
		// First time init
		if (!isNil QTGVAR(TestStartedEH)) exitWith {};

		RUNNER__SELF = createHashMap;
		RUNNER__SELF set ["suites", []];
		RUNNER__SELF set ["running_suite_id", -1];
		RUNNER__SELF set ["state", STATE_RUNNER_READY];

		["CREATE_RUNNER_CONTROLS"] call TFUNC(Reporter);

		TGVAR(TestSuiteStartedEH) = [EVENT_SUITE_STARTED, {
			params["_suite"];

			["REPORT_SUITE_STARTED",_suite] call TFUNC(Reporter);
		}] call CBA_fnc_addEventHandler;

		TGVAR(TestSuiteFinishedEH) = [EVENT_SUITE_FINISHED, {
			params["_suite"];

			private _suiteTestResults = _suite get "results";
			private _testsTotal = count _suiteTestResults;

			// --- Calcululate results count
			private _counter = createHashMap;
			{
				private _testResult = _x;
				private _count = { _x isEqualTo _testResult } count _suiteTestResults;
				private _prcnt = "" + ((_count/_testsTotal * 100) toFixed 0) + "%";

				_counter set [_testResult, _count];
				_counter set [format ["%1.percent", _testResult], _prcnt];
			} forEach [STATE_PASS, STATE_FAIL, STATE_SKIP, STATE_CRASH];

			_suite set ["results_counter", _counter];

			// --- Define Suite's total result
			private _suiteResult = STATE_NOT_RUN;
			if (
				(_counter get STATE_FAIL) isNotEqualTo 0
				|| (_counter get STATE_CRASH) isNotEqualTo 0
			) then {
				_suiteResult = STATE_FAIL;
			} else {
				if ((_counter get STATE_PASS) isNotEqualTo 0) then {
					_suiteResult = STATE_PASS;
				};
			};
			_suite set ["suite_result",_suiteResult];

			// --- Report results
			["REPORT_SUITE_RESULTS",_suite] call TFUNC(Reporter);

			// --- Clean tests
			_suite set ["tests", []];

			// --- Reset runner
			RUNNER__SELF set ["state",STATE_RUNNER_READY];
			RUNNER__SELF set ["running_suite_id",-1];
			RUNNER__SELF set ["reporter.output",[]];

			[EVENT_RUNNER_STOPPED, []] call CBA_fnc_localEvent;
		}] call CBA_fnc_addEventHandler;

		TGVAR(TestStartedEH) = [EVENT_TEST_STARTED, {
			params ["_testName","_testFile"];

			private _suite = RUNNER__SUITE;
			_suite set ["current_test.name", _testName];
			_suite set ["current_test.file", _testFile];
		}] call CBA_fnc_addEventHandler;

		TGVAR(TestSkipped) = [EVENT_TEST_SKIPPED, {
			params ["_testName","_testFile"];

			private _suite = RUNNER__SUITE;

			["__UPDATE_TEST_RESULT",
				_suite,
				[_testName, _testFile, CURRENT_TEST_ID],
				STATE_SKIP,
				[]
			] call SELF;
		}] call CBA_fnc_addEventHandler;

		TGVAR(TestPassedEH) = [EVENT_TEST_PASSED, {
			params ["_testName","_testFile"];

			private _suite = RUNNER__SUITE;

			["__UPDATE_TEST_RESULT",
				_suite,
				[_testName, _testFile, CURRENT_TEST_ID],
				STATE_PASS,
				[]
			] call SELF;
		}] call CBA_fnc_addEventHandler;

		TGVAR(TestExceptionEH) = [EVENT_TEST_CRASHED, {
			params ["_testName","_testFile","_msg","_exception"];

			private _suite = RUNNER__SUITE;

			["__UPDATE_TEST_RESULT",
				_suite,
				[_testName, _testFile, CURRENT_TEST_ID],
				STATE_CRASH,
				[_msg, _exception]
			] call SELF;
		}] call CBA_fnc_addEventHandler;

		TGVAR(TestFailedEH) = [EVENT_TEST_FAILED, {
			params ["_testName","_testFile","_assertMsg","_conditionMsg"];

			private _suite = RUNNER__SUITE;

			["__UPDATE_TEST_RESULT",
				_suite,
				[_testName, _testFile, CURRENT_TEST_ID],
				STATE_FAIL,
				[_assertMsg, _conditionMsg]
			] call SELF;
		}] call CBA_fnc_addEventHandler;
	};
	case "__PREPARE": {
		private _suite = _arg1;
		private _suiteID = (RUNNER__SELF get "suites") pushBack _suite;
		private _testsCount = count (_suite get "tests");

		_suite set ["id", _suiteID];
		_suite set ["count", _testsCount];
		_suite set ["progress", 0];

		private _executionResults = [];
		for "_i" from 0 to (_testsCount - 1) do {
			_executionResults pushBack STATE_NOT_RUN;
		};
		_suite set ["results", _executionResults];
	};
	case "__START": {
		private _suite = _arg1;

		RUNNER__SELF set ["state",STATE_RUNNER_BUSY];
		RUNNER__SELF set ["running_suite_id",_suite get "id"];
		RUNNER__SELF set ["reporter.output", _suite get "options.output"];

		if (TESQF_OUTPUT_DIARY in (RUNNER__SELF get "reporter.output")) then {
			["CREATE_SUITE_TOPIC",
				_suite get "name",
				_suite get "id"
			] call TFUNC(Reporter);
		};

		private _tags = _suite get "tags";
		private _tests = _suite get "tests";
		private _instantFail = _suite get "options.instant_fail";

		[EVENT_SUITE_STARTED, [_suite]] call CBA_fnc_localEvent;

		{
			_suite set ["current_test.id", _forEachIndex];
			_suite set ["current_test.result", STATE_NOT_RUN];

			private _test = _x;
			private _scriptHandler = [_tags] spawn _test;

			// Wait for script to be done (exit on error on finished)
			waitUntil { scriptDone _scriptHandler };

			// If test result is not set still - then test passed
			if (_suite get "current_test.result" isEqualTo STATE_NOT_RUN) then {
				[EVENT_TEST_PASSED, [
					_suite get "current_test.name",
					_suite get "current_test.file"
				]] call CBA_fnc_localEvent;
			};

			// Update Suite's progress
			_suite set ["progress", (_suite get "progress") + 1];

			// Exit if Instant Fail option is enabled and test case fails/crashes
			if (
				_instantFail
				&& { _suite get "current_test.result" in [STATE_CRASH, STATE_FAIL] }
			) exitWith {};

			// Wait between tests
			uiSleep 0.1;
		} forEach _tests;

		[EVENT_SUITE_FINISHED, [_suite]] call CBA_fnc_localEvent;
	};

	case "__VALIDATE_TAGS": {
		// Checks Suite tags vs Test tags and return True if there is any match
		private _suiteTags = _arg1;
		private _tagsStr = _arg2;

		// --- No tags for Suite -- all test are ok
		if (_suiteTags isEqualTo []) exitWith { _result = true; };

		// --- Check for any suite's tag in test's tags
		_result = false;
		private _tags = ["__PARSE_LIST_STRING", _tagsStr] call TFUNC(TestSuite);
		{
			_result = _x in _tags;
			if (_result) exitWith {};
		} forEach _suiteTags;
	};
	case "__UPDATE_TEST_RESULT": {
		[_arg1,_arg2,_arg3,_arg4] params [
			"_suite",
			"_testDetails",
			"_testResult",
			"_msgDetails"
		];

		// Update test's result
		_suite set ["current_test.result", _testResult];

		// Update result in suite
		_testDetails params ["_testName","_testFile","_testId"];
		(_suite get "results") set [_testId, _testResult];

		// Save to log
		(_suite get "log") pushBack [_testResult, _testDetails, _msgDetails];

		// Report results
		["REPORT",
			_suite,
			_testResult,
			_testDetails,
			_msgDetails
		] call TFUNC(Reporter);
	};
};

_result
