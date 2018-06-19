import XCTest
@testable import Backgroundable

XCTMain([
    testCase(GlobalFunctionsTests.allTests),
    testCase(AsyncOperationTests.allTests),
    testCase(AsyncOperationCancellationTest.allTests),
    testCase(AsyncOperationMultipleCancellationTest.allTests),
    testCase(AsyncOperationCancellationTimeoutTest.allTests),
    testCase(BackgroundQueueTests.allTests)
])
