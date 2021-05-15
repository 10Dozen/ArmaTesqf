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

### Test Case creation

### Test Suite creation 

### Test Suite execution
