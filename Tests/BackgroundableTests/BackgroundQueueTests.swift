import XCTest
@testable import Backgroundable


class BackgroundQueueTests: XCTestCase, BackgroundQueueTest
{
    let backgroundQueue: BackgroundQueue = BackgroundQueue()
    var expectations: [XCTestExpectation] = []
    
    override func setUp() {
        super.setUp()
        
        setUpBackgroundQueue()
        expectations = []
    }
    
    let testSequentialOperationsToTheMainOperationQueueDescription = "Executing sequential operations on the main operation queue"
    func testSequentialOperationsOnTheMainOperationQueue() {
        let description1 = testSequentialOperationsToTheMainOperationQueueDescription + " _1"
        let description2 = testSequentialOperationsToTheMainOperationQueueDescription + " _2"
        let description3 = testSequentialOperationsToTheMainOperationQueueDescription + " _3"
        
        var hasFulfilledOperation1 = false
        var hasFulfilledOperation2 = false
        var hasFulfilledOperation3 = false
        
        //Executing sequential operations in the background
        var sequentialOperations = [Operation]()
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Executing sequential operation 1")
            
            XCTAssertFalse(hasFulfilledOperation1, "We shouldn't have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description1 })?.fulfill()
            hasFulfilledOperation1 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(expectation(description: description1))
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Executing sequential operation 2")
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description2 })?.fulfill()
            hasFulfilledOperation2 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(expectation(description: description2))
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Executing sequential operation 3")
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description3 })?.fulfill()
            hasFulfilledOperation3 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertTrue(hasFulfilledOperation3, "We should have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(expectation(description: description3))
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            defer { op.finish() }
            
            guard let strongSelf = self else { return }
            if let expectation = strongSelf.expectations.first(where: { $0.expectationDescription == strongSelf.testSequentialOperationsToTheMainOperationQueueDescription }) {
                expectation.fulfill()
                return
            }
        })
        expectations.append(expectation(description: testSequentialOperationsToTheMainOperationQueueDescription))
        
        OperationQueue.main.addSequentialOperations(sequentialOperations,
                                                    waitUntilFinished: false)
        
        wait(for: expectations,
             timeout: 20)
    }
    
    let testSequentialOperationsInTheBackgroundDescription = "Executing sequential operations in the background"
    func testSequentialOperationsInTheBackground() {
        let description1 = testSequentialOperationsInTheBackgroundDescription + " _1"
        let description2 = testSequentialOperationsInTheBackgroundDescription + " _2"
        let description3 = testSequentialOperationsInTheBackgroundDescription + " _3"
        
        var hasFulfilledOperation1 = false
        var hasFulfilledOperation2 = false
        var hasFulfilledOperation3 = false
        
        //Executing sequential operations in the background
        var sequentialOperations = [Operation]()
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Executing sequential operation 1")
            
            XCTAssertFalse(hasFulfilledOperation1, "We shouldn't have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description1 })?.fulfill()
            hasFulfilledOperation1 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(expectation(description: description1))
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Executing sequential operation 2")
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description2 })?.fulfill()
            hasFulfilledOperation2 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(expectation(description: description2))
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Executing sequential operation 3")
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description3 })?.fulfill()
            hasFulfilledOperation3 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertTrue(hasFulfilledOperation3, "We should have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(expectation(description: description3))
        
        expectations.append(expectation(description: testSequentialOperationsInTheBackgroundDescription))
        
        backgroundQueue.addSequentialOperations(sequentialOperations,
                                                waitUntilFinished: false)
        
        wait(for: expectations,
             timeout: 20)
    }
    
    let testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription = "A sequential operation shoudn't start before its dependency has finished"
    func testSequentialOperationShouldntStartBeforeDependencyHasFinished() {
        expectations.append(expectation(description: testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription))
        
        let executionDescription1 = testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription + " _executed1"
        expectations.append(expectation(description: executionDescription1))
        
        let executionDescription2 = testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription + " _not_executed2"
        expectations.append(expectation(description: executionDescription2))
        
        var expectationNot2: XCTestExpectation? = expectation(description: testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription + " _not_executed2")
        expectations.append(expectationNot2!)
        expectationNot2!.isInverted = true
        
        //A timeout AsyncOperation
        backgroundQueue.addSequentialOperations(
            [
                AsyncOperation(timeout: 5) { [weak self] (op) in
                    print("Executing Operation 1")
                    
                    self?.expectations.first(where: { $0.expectationDescription == executionDescription1 })?.fulfill()
                    
                    expectationNot2 = nil
                },
                AsyncOperation { [weak self] (op) in
                    print("Executing Operation 2")
                    
                    self?.expectations.first(where: { $0.expectationDescription == executionDescription2 })?.fulfill()
                    
                    expectationNot2?.fulfill()
                    
                    op.finish()
                }
            ], waitUntilFinished: false)
        
        wait(for: expectations,
             timeout: 10)
    }
}


extension BackgroundQueueTests: BackgroundQueueDelegate
{
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue) {
        //Noop
    }
    
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
    {
        guard queue == backgroundQueue else { return }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testSequentialOperationsInTheBackgroundDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription }) {
            expectation.fulfill()
            return
        }
    }
}

extension BackgroundQueueTests
{
    static var allTests : [(String, (BackgroundQueueTests) -> () throws -> Swift.Void)] {
        return [
            ("testSequentialOperationsOnTheMainOperationQueue", testSequentialOperationsOnTheMainOperationQueue),
            ("testSequentialOperationsInTheBackground", testSequentialOperationsInTheBackground),
            ("testSequentialOperationShouldntStartBeforeDependencyHasFinished", testSequentialOperationShouldntStartBeforeDependencyHasFinished)
        ]
    }
}
