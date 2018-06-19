import XCTest
@testable import Backgroundable


class GlobalFunctionsTests: XCTestCase
{
    let testMainThreadDescription = "Executing on the main thread"
    func testMainThread() {
        var expectations: [XCTestExpectation] = []
        expectations.append(expectation(description: testMainThreadDescription))
        
        //Printing on the main thread
        onTheMainThread {
            XCTAssertTrue(Thread.isMainThread, "We should be on the main thread")
            print("Are we on the main thread? \(Thread.isMainThread)")
            
            expectations.forEach {
                $0.fulfill()
            }
        }
        
        wait(for: expectations,
             timeout: 5)
    }
    
    let testBackgroundDescription = "Executing in the background"
    func testBackground() {
        var expectations: [XCTestExpectation] = []
        expectations.append(expectation(description: testBackgroundDescription))
        
        //Printing in the background
        inTheBackground {
            XCTAssertFalse(Thread.isMainThread, "We shouldn't be on the main thread")
            print("Are we in the background? \(!Thread.isMainThread)")
            
            expectations.forEach {
                $0.fulfill()
            }
        }
        
        wait(for: expectations,
             timeout: 5)
    }
}

extension GlobalFunctionsTests
{
    static var allTests : [(String, (GlobalFunctionsTests) -> () throws -> Swift.Void)] {
        return [
            ("testMainThread", testMainThread),
            ("testBackground", testBackground)
        ]
    }
}
