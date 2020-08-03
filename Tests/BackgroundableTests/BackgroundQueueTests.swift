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
        
        OperationQueue.background.addSequentialOperations(sequentialOperations,
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

    let testOperationShouldntStartOnSuspendedQueueDescription = "A an operation shoudn't start on a suspended queue"
    func testOperationShouldntStartOnSuspendedQueue() {
        var expectations = [XCTestExpectation]()

        let expectation1 = expectation(description: testOperationShouldntStartOnSuspendedQueueDescription)
        expectation1.isInverted = true
        expectations.append(expectation1)

        backgroundQueue.isSuspended = true
        backgroundQueue.addOperation {
            expectation1.fulfill()
        }

        wait(for: expectations,
             timeout: 3)

        backgroundQueue.cancelAllOperations()
        backgroundQueue.isSuspended = false
    }

    let testSuspendedQueueShouldUnsuspendDescription = "A suspended queue should be able to become unsuspended"
    func testSuspendedQueueShouldUnsuspend() {
        let expectation1 = expectation(description: testOperationShouldntStartOnSuspendedQueueDescription)
        expectation1.isInverted = true

        backgroundQueue.isSuspended = true
        backgroundQueue.addOperation {
            expectation1.fulfill()
        }

        wait(for: [expectation1],
             timeout: 3)

        backgroundQueue.cancelAllOperations()

        let expectation2 = expectation(description: testSuspendedQueueShouldUnsuspendDescription)
        backgroundQueue.addOperation {
            expectation2.fulfill()
        }

        backgroundQueue.isSuspended = false

        wait(for: [expectation2],
             timeout: 2)
    }

    let testMultipleSuspensionsDescription = "A queue should be able to unsuspend after being suspended several times"
    func testMultipleSuspensions() {
        let expectation1 = expectation(description: testOperationShouldntStartOnSuspendedQueueDescription)
        expectation1.isInverted = true

        backgroundQueue.isSuspended = true

        backgroundQueue.addOperation {
            expectation1.fulfill()
        }

        backgroundQueue.isSuspended = true
        backgroundQueue.isSuspended = true

        backgroundQueue.isSuspended = false

        XCTAssertTrue(backgroundQueue.isSuspended, "The background queue should still be suspended after 3 suspensions and 1 unsuspension")

        wait(for: [expectation1],
             timeout: 3)

        backgroundQueue.cancelAllOperations()

        let expectation2 = expectation(description: testMultipleSuspensionsDescription)
        backgroundQueue.addOperation {
            expectation2.fulfill()
        }

        backgroundQueue.isSuspended = false

        XCTAssertTrue(backgroundQueue.isSuspended, "The background queue should still be suspended after 3 suspensions and 2 unsuspensions")

        backgroundQueue.isSuspended = false

        XCTAssertFalse(backgroundQueue.isSuspended, "The background queue should not be suspended after 3 suspensions and 3 unsuspensions")

        wait(for: [expectation2],
             timeout: 2)

        let expectation3 = expectation(description: testMultipleSuspensionsDescription)
        backgroundQueue.addOperation {
            expectation3.fulfill()
        }

        backgroundQueue.isSuspended = false

        wait(for: [expectation3],
             timeout: 2)

        XCTAssertFalse(backgroundQueue.isSuspended, "The background queue should not be suspended after 3 suspensions and 4 unsuspensions")
    }

    let testOperationShouldBeAddedDescription = "A background queue should be able to receive operations"
    func testOperationShouldBeAdded() {
        let expectation1 = expectation(description: testOperationShouldBeAddedDescription)

        backgroundQueue.addOperation {
            expectation1.fulfill()
        }

        wait(for: [expectation1],
             timeout: 3)
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
            ("testSequentialOperationShouldntStartBeforeDependencyHasFinished", testSequentialOperationShouldntStartBeforeDependencyHasFinished),
            ("testOperationShouldBeAdded", testOperationShouldBeAdded)
        ]
    }
}
