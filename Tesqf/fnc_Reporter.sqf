
/*
	Handle reports to selected outputs

*/
#include "tesqf_macro.hpp"
#define SELF TFUNC(Reporter)

params ["_method",["_arg1", ""],["_arg2", ""],["_arg3", ""],["_arg4", ""]];

private _result = false;

switch toUpper _method do {
	case "REPORT": {
		private _suite = _arg1;
		private _msgType = _arg2;
		private _msgTestDetails = _arg3;
		private _msgDetails = _arg4;

		private _testSuiteName = _suite get "name";
		private _suiteId = _suite get "id";

		private _outputs = _suite get "option.output";
		if (RUNNER__CHECK_OUTPUTS(TESQF_OUTPUT_RPT)) then {
			[
				"__REPORT_TEST_TO_RPT",
				_testSuiteName,
				_msgType,
				_msgTestDetails,
				_msgDetails
			] call SELF;
		};
		if (RUNNER__CHECK_OUTPUTS(TESQF_OUTPUP_SYSTEMCHAT)) then {
			[
				"__REPORT_TEST_TO_SYSTEMCHAT",
				_testSuiteName,
				_msgType,
				_msgTestDetails,
				_msgDetails
			] call SELF;
		};
		if (RUNNER__CHECK_OUTPUTS(TESQF_OUTPUT_DIARY)) then {
			["__REPORT_TEST_TO_DIARY",
				_testSuiteName,
				_suiteId,
				_msgType,
				_msgTestDetails
			] call SELF;
		};
	};
	case "REPORT_SUITE_STARTED": {
		private _suite = _arg1;

		private _suiteName = _suite get "name";
		private _testCount = _suite get "count";
		private _tags = _suite get "tags";
		private _outputs = _suite get "options.output";

		private _msg1 = format ["========= TEST SUITE [%1] STARTED =========", _suiteName];
		private _msg2 = format [
			"========= Tests: %2. Tags: %3 =========",
			_suiteName,
			_testCount,
			_tags
		];

		if (TESQF_OUTPUT_RPT in _outputs) then {
			["__WRITE_TO_RPT",_msg1] call SELF;
			["__WRITE_TO_RPT",_msg2] call SELF;
		};

		if !(TESQF_OUTPUP_SYSTEMCHAT in _outputs) exitWith {};
		systemChat format ["[%1] %2",QTCOMPONENT,_msg1];
		systemChat format ["[%1] %2",QTCOMPONENT,_msg2];
	};
	case "REPORT_SUITE_RESULTS": {
		// Final message (on top):
		/*
			Suite: My Test Suite
			Result: [ FAILED ]

			Total: 21
			Passed: 14 (60%)       Skipped: 2 (5%)
			Failed: 4 (10%)        Crashed: 4 (10%)
			-------------
			Copy results | Re-run ???
			-------------
		*/
		private _suite = _arg1;

		private _outputs = _suite get "options.output";

		private _suiteName = _suite get "name";
		private _suiteId = _suite get "id";
		private _testsTotal = _suite get "count";
		private _testsResults = _suite get "results_counter";
		private _suiteResult = _suite get "suite_result";

		// Report to Hint
		private _hint = ["__FORMAT_RESULTS_FOR_HINT",
			[_suiteName, _suiteResult, _testsResults]
		] call SELF;
		hint parseText _hint;

		// Report to Diary
		if (TESQF_OUTPUT_DIARY in _outputs) then {
			["__REPORT_SUITE_TO_DIARY",[
				_suiteName,
				_suiteId,
				_suiteResult,
				_testsTotal,
				_testsResults
			]] call SELF;
		};

		// Report to SystemChat
		if (TESQF_OUTPUP_SYSTEMCHAT in _outputs) then {
			["__REPORT_SUITE_TO_SYSTEMCHAT",[
				_suiteName,
				_suiteResult,
				_testsTotal,
				_testsResults
			]] call SELF;
		};

		// Report to RPT
		if !(TESQF_OUTPUT_RPT in _outputs) exitWith {};
		["__REPORT_SUITE_TO_RPT",[
			_suiteName,
			_suiteResult,
			_testsTotal,
			_testsResults
		]] call SELF;
	};
	case "EXPORT_RESULTS": {
		private _id = _arg1;
		private _suite = RUNNER__GET_SUITE_BY_ID(_id);

		private _export = ["__FORMAT_EXPORT_RESULTS",_suite] call SELF;
		copyToClipboard _export;

		hint "Results copied";
	};
	case "EXPORT_LOG": {
		private _id = _arg1;
		private _suite = RUNNER__GET_SUITE_BY_ID(_id);

		private _export = ["__FORMAT_EXPORT_LOG",_suite] call SELF;
		copyToClipboard _export;

		hint "Log copied";
	};
	case "REPORT_LOG": {
		private _msgLogLevel = _arg1;
		private _msg = _arg2;

		// Skip message if it's level less than needed
		if (TGVAR(LogLevel) < _msgLogLevel) exitWith {};

		private _line = format ["[%1] %2", TLOG_LEVEL_NAME(_msgLogLevel), _msg];

		["__WRITE_TO_RPT", _line] call SELF;
	};
	case "CREATE_RUNNER_CONTROLS": {
		["__CREATE_CORE_TOPIC"] call SELF;

		player createDiaryRecord  [TESQF_SUBJECT, [
			TESQF_RUNNER_TOPIC,
			"Note: Use buttons to run specific Test Suite."
		]];
	};
	case "ADD_SUITE_TO_RUNNER_CONTROLS": {
		private _suiteFile = _arg1;

		player createDiaryRecord  [TESQF_SUBJECT, [
			TESQF_RUNNER_TOPIC,
			["__FORMAT_RUNNER_CONTROL_BUTTONS", _suiteFile] call SELF
		]];
	};
	case "CREATE_SUITE_TOPIC": {
		["__CREATE_CORE_TOPIC"] call SELF;

		private _suiteName = _arg1;
		private _suiteId = _arg2;
		private _topicName = ["__FORMAT_SUITE_TOPIC_NAME",
			_suiteName,
			_suiteId
		] call SELF;

		player createDiaryRecord  [TESQF_SUBJECT, [_topicName,""]];
	};

	case "__CREATE_CORE_TOPIC": {
		private _suiteFile = _arg1;

		if (player diarySubjectExists TESQF_SUBJECT) exitWith {};
		player createDiarySubject [TESQF_SUBJECT, TESQF_SUBJECT];
	};
	case "__REPORT_TEST_TO_RPT": {
		private _msgSuiteName = _arg1;
		private _msgType = _arg2;
		private _msgTestDetails = _arg3;
		private _msgDetails = _arg4;

		private _msg = [
			"__FORMAT_TEST_FOR_RPT",
			_msgSuiteName,
			_msgType,
			_msgTestDetails,
			_msgDetails
		] call SELF;

		["__WRITE_TO_RPT",_msg] call SELF;
	};
	case "__REPORT_TEST_TO_SYSTEMCHAT": {
		private _msgSuiteName = _arg1;
		private _msgType = _arg2;
		private _msgTestDetails = _arg3;
		private _msgDetails = _arg4;

		private _msg = [
			"__FORMAT_TEST_FOR_RPT",
			_msgSuiteName,
			_msgType,
			_msgTestDetails,
			_msgDetails
		] call SELF;

		systemChat _msg;
	};
	case "__REPORT_TEST_TO_DIARY": {
		// [Passed] My Test (id:0)
		private _suiteName = _arg1;
		private _suiteId = _arg2;
		private _msgType = _arg3;
		private _msgTestDetails = _arg4;

		private _topicName = ["__FORMAT_SUITE_TOPIC_NAME",
			_suiteName,
			_suiteId
		] call SELF;

		private _line = ["__FORMAT_TEST_FOR_DIARY",
			_msgType,
			_msgTestDetails
		] call SELF;

		player createDiaryRecord [TESQF_SUBJECT, [_topicName,_line]];
	};
	case "__REPORT_SUITE_TO_RPT": {
		_arg1 params [
			"_suiteName",
			"_suiteResult",
			"_testsTotalCount",
			"_testsResults"
		];

		["__WRITE_TO_RPT", format ["========= TEST SUITE [%1] FINISHED =========",
			_suiteName
		]] call SELF;
		["__WRITE_TO_RPT", text (["__FORMAT_RESULTS_FOR_RPT",
			[_suiteName, _suiteResult,_testsTotalCount,_testsResults]
		] call SELF) ] call SELF;
	};
	case "__REPORT_SUITE_TO_SYSTEMCHAT": {
		_arg1 params [
			"_suiteName",
			"_suiteResult",
			"_testsTotalCount",
			"_testsResults"
		];

		systemChat format ["========= TEST SUITE [%1] FINISHED =========",_suiteName];
		systemChat format [["__FORMAT_RESULTS_FOR_RPT",
			[_suiteName, _suiteResult,_testsTotalCount,_testsResults]
		] call SELF];
	};
	case "__REPORT_SUITE_TO_DIARY": {
		_arg1 params [
			"_suiteName",
			"_suiteId",
			"_suiteResult",
			"_testsTotalCount",
			"_testsResults"
		];

		private _topicName = format ["%1 (%2)",_suiteName,_suiteId];
		player createDiaryRecord [
			TESQF_SUBJECT,
			[
				_topicName,
				["__FORMAT_RESULTS_FOR_DIARY",
					[_suiteName,_suiteResult,_testsTotalCount,_testsResults]
				] call SELF
			]
		];
		player createDiaryRecord [
			TESQF_SUBJECT,
			[
				_topicName,
				["__FORMAT_RESULTS_BUTTONS",_suiteId] call SELF
			]
		];
	};

	#define _GET_TEST_RESULTS(X,TYPE) X get TYPE, X get format ["%1.percent",TYPE]
	case "__FORMAT_RUNNER_CONTROL_BUTTONS": {
		private _suiteFile = _arg1;

		_result = format [
			"[<execute expression='[%2,%3] call %1'>Run</execute>] %4",
			QUOTE(TFUNC(Runner)),
			str("RUN"),
			str(_suiteFile),
			_suiteFile
		];
	};
	case "__FORMAT_RESULTS_FOR_HINT": {
		_arg1 params ["_suiteName","_suiteResult","_testResults"];

		_result = format [
			"%1
			<br />Test Suite finished
			<br />[%2]
			<br />
			<br />Passed: %3 (%4)
			<br />Failed: %5 (%6)
			<br />Skipped: %7 (%8)
			<br />Crashed: %9 (%10)",
			_suiteName,
			["__FORMAT_COLOR_TAG",_suiteResult,"HINT"] call SELF,
			_GET_TEST_RESULTS(_testResults,STATE_PASS),
			_GET_TEST_RESULTS(_testResults,STATE_FAIL),
			_GET_TEST_RESULTS(_testResults,STATE_SKIP),
			_GET_TEST_RESULTS(_testResults,STATE_CRASH)
		];
	};
	case "__FORMAT_SUITE_TOPIC_NAME": {
		private _suiteName = _arg1;
		private _suiteId = _arg2;

		_result = format ["%1 (%2)", _suiteName, _suiteId];
	};
	case "__FORMAT_RESULTS_FOR_RPT": {
		_arg1 params ["_suiteName","_suiteResult","_total","_testResults"];

		_result = format [
			"(%1) Result: [ %2 ] >> Total: %3 [P:%4(%5)|F:%6(%7)|S:%8(%9)|EX:%10(%11)]",
			_suiteName,
			_suiteResult,
			_total,
			_GET_TEST_RESULTS(_testResults,STATE_PASS),
			_GET_TEST_RESULTS(_testResults,STATE_FAIL),
			_GET_TEST_RESULTS(_testResults,STATE_SKIP),
			_GET_TEST_RESULTS(_testResults,STATE_CRASH)
		];
	};
	case "__FORMAT_RESULTS_FOR_DIARY": {
		_arg1 params ["_suiteName","_suiteResult","_total","_testResults"];

		_result = format [
			"Suite: %1<br />
			Result: [ %2 ]<br />
			<br />
			Total: %3<br />
			Passed: %4 (%5)<br />
			Failed: %6 (%7)<br />
			Skipped: %8 (%9)<br />
			Crashed: %10 (%11)<br />
			---------------------<br />
			",
			_suiteName,
			["__FORMAT_COLOR_TAG",_suiteResult,"DIARY"] call SELF,
			_testsTotal,
			_GET_TEST_RESULTS(_testResults,STATE_PASS),
			_GET_TEST_RESULTS(_testResults,STATE_FAIL),
			_GET_TEST_RESULTS(_testResults,STATE_SKIP),
			_GET_TEST_RESULTS(_testResults,STATE_CRASH)
		];
	};
	case "__FORMAT_RESULTS_BUTTONS": {
		private _suiteId = _arg1;

		_result = format [
			"[<execute expression='[%3,%2] call %1'>Copy results</execute>]
			[<execute expression='[%4,%2] call %1'>Copy log</execute>]
			<br />---------------------",
			QUOTE(SELF),
			_suiteId,
			str("EXPORT_RESULTS"),
			str("EXPORT_LOG")
		];
	};
	case "__FORMAT_EXPORT_RESULTS": {
		private _suite = _arg1;
		private _suiteName = _suite get "name";
		private _suiteResult = _suite get "suite_result";
		private _testResults = _suite get "results_counter";
		private _totalTests = _suite get "count";

		private _outputText = [
			_suiteName,
			format ["Result: [%1]",_suiteResult],
			"",
			format ["Total tests: %1", _totalTests],
			format ["Passed: %1 (%2)",_GET_TEST_RESULTS(_testResults,STATE_PASS)],
			format ["Failed: %1 (%2)",_GET_TEST_RESULTS(_testResults,STATE_FAIL)],
			format ["Skipped: %1 (%2)",_GET_TEST_RESULTS(_testResults,STATE_SKIP)],
			format ["Crashed: %1 (%2)",_GET_TEST_RESULTS(_testResults,STATE_CRASH)]
		];

		_result = _outputText joinString toString [10];
	};
	case "__FORMAT_EXPORT_LOG": {
		private _suite = _arg1;
		private _suiteName = _suite get "name";
		private _suiteLog = _suite get "log";

		private _output = [];
		{
			_x params ["_msgType","_details","_msgDetails"];

			private _msg = ["__FORMAT_TEST_FOR_RPT",
				_suiteName,
				_msgType,
				_details,
				_msgDetails
			] call SELF;

			_output pushBack format ["%1 %2", _forEachIndex, _msg];
		} forEach _suiteLog;

		_result = _output joinString toString [10];
	};
	case "__FORMAT_TEST_FOR_RPT": {
		private _testSuiteName = _arg1;
		private _msgType = _arg2;
		_arg3 params ["_testName","_testFile","_testId"];
		private _msgDetails = _arg4;

		private _lines = [format [
			"(%1)(id:%2) [%3] %4",
			_testSuiteName,
			_testId,
			toUpper(_msgType),
			_testName
		]];
		switch (_msgType) do {
			case STATE_PASS: {
				// _lines pushBack "[PASSED]";
			};
			case STATE_FAIL: {
				_msgDetails params ["_msg","_condition"];
				_lines pushBack format [
					": Assertion: %1 -> %2",
					_msg,
					_condition
				];
			};
			case STATE_CRASH: {
				_msgDetails params ["_msg","_exception"];
				_lines pushBack format [
					": Exception thrown: %1 -> %2",
					_msg,
					_exception
				];
			};
			case STATE_SKIP: {
				//_lines pushBack "[SKIPPED]";
			};
		};
		_lines pushBack format ["(%1)", _testFile];

		_result = _lines joinString " ";
	};
	case "__FORMAT_TEST_FOR_DIARY": {
		private _testResult = _arg1;
		_arg2 params ["_testName","_testFile","_testId"];

		_result = format [
			"[%1] (id:%2) %3",
			["__FORMAT_COLOR_TAG", _testResult, "DIARY"] call SELF,
			_testId,
			_testName
		];
	};
	case "__FORMAT_COLOR_TAG": {
		private _testResult = _arg1;
		private _mode = _arg2;

		private _tag = switch (toUpper _mode) do {
			case "HINT": { "t" };
			case "DIARY": { "font" };
		};
		private _color = switch _testResult do {
			case STATE_PASS: { "#a4d194" };
			case STATE_FAIL: { "#ff4545" };
			case STATE_CRASH: { "#fc6f03" };
			case STATE_SKIP: { "#8ac5d1" };
		};

		_result = format ["<%1 color='%2'>%3</%1>", _tag, _color, _testResult];
	};

	case "__WRITE_TO_RPT": {
		private _msg = _arg1;
		diag_log parseText format ["[%1] %2", QTCOMPONENT, _msg];
	};
};

_result
