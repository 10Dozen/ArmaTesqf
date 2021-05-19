
/*
	Handle test suite creation
*/


#include "tesqf_macro.hpp"
#define SELF TFUNC(TestSuite)

params ["_method",["_arg1", ""],["_arg2", ""],["_arg3", ""],["_arg4", ""]];

private _result = objNull;

switch toUpper _method do {
	case "CREATE": {
		_suiteSettings = call compile preprocessFileLineNumbers _arg1;
		_suiteSettings params [
			"_name",
			["_filesStr",""],
			["_tagsStr",""],
			["_optionsStr",""]
		];

		_files = [];
		_tags = [];
		_options = [];

		if (_filesStr isNotEqualTo "") then {
			_files = ["__PARSE_LIST_STRING", _filesStr] call SELF;
		};

		if (_tagsStr isNotEqualTo "") then {
			_tags = ["__PARSE_LIST_STRING", _tagsStr] call SELF;
		};

		if (_optionsStr isNotEqualTo "") then {
			_options = ["__PARSE_OPTIONS_STRING", _optionsStr] call SELF;
		};

		_suite = ["__CREATE_FROM_FILES", _files] call SELF;
		["__INIT", _suite, _name, _tags, _options] call SELF;

		_result = _suite;
	};
	case "__CREATE_FROM_FILES": {
		// Compiles given files and assign into Suite
		private _files = _arg1;
		if (_files isEqualTo []) exitWith {
			["Tesqf.TestSuite :: Empty list of test files was provided!"] call BIS_fnc_error;
		};

		private _suite = createHashMap;
		private _tests = [];
		{
			private ["_test"];
			try {
				_test = compile preprocessFileLineNumbers _x;
				_tests pushBack _test;
			} catch {
				["Failed to compile test [%1] -- %2", _x, _exception] call BIS_fnc_error;
			};
		} forEach _files;

		_suite set ["tests",_tests];

		_result = _suite;
	};
	case "__INIT": {
		// Initialize suite with given settings
		private _suite = _arg1;
		private _name = _arg2;
		private _tags = _arg3;
		private _options = _arg4;

		_suite set ["name", _name];
		_suite set ["tags", _tags];
		_suite set ["log",[]];
		["__SET_OPTIONS", _suite, _options] call SELF;
	};
	case "__SET_OPTIONS": {
		// Set up suite options with given values or defaults
		private _suite = _arg1;
		private _options = _arg2;
		private _defaults = [
			["output", [TESQF_OUTPUT_RPT,TESQF_OUTPUT_DIARY,TESQF_OUTPUP_SYSTEMCHAT]],
			["instant_fail", false]
		];

		{
			_x params ["_option", "_default"];
			_suite set [format ["options.%1", _option], _default];
		} forEach _defaults;

		{
			_x params ["_option", "_value"];
			_option = toLower _option;

			switch _option do {
				case "output": {
					if (isNil "_value") exitWith {
						_value = []
					};
					_value = (_value splitString ",") apply { toLower _x };
				};
				case "instant_fail": {
					if (isNil "_value") exitWith {
						_value = false;
					};
					_value = call compile _value;
				 };
				default { nil };
			};

			if (!isNil "_value") then {
				_suite set [format ["options.%1", _option], _value];
			};
		} forEach _options;
	};
	case "__PARSE_OPTIONS_STRING": {
		_result = ((toLower _arg1) splitString " " joinString "" splitString ";") apply {
			trim _x splitString ":"
		} select { _x isNotEqualTo [] };
	};
	case "__PARSE_LIST_STRING": {
		_result = _arg1 splitString toString[10,19] apply { trim _x } select {
			_x != ""  && _x select [0,2] != "//"
		};
	};
};

_result
