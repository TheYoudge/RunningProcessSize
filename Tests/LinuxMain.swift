import XCTest

import RunningProcessSizeTests

var tests = [XCTestCaseEntry]()
tests += RunningProcessSizeTests.allTests()
XCTMain(tests)
