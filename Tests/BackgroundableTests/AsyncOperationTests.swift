import XCTest
@testable import Backgroundable


class AsyncOperationTests: XCTestCase, BackgroundQueueTest
{
    let backgroundQueue: BackgroundQueue = BackgroundQueue()
    var expectations: [XCTestExpectation] = []
    
    override func setUp() {
        super.setUp()
        
        setUpBackgroundQueue()
        expectations = []
    }
    
    let testAsyncOperationInTheBackgroundDescription = "Executing an AsyncOperation in the background"
    func testAsyncOperationInTheBackground() {
        expectations.append(expectation(description: testAsyncOperationInTheBackgroundDescription))
        
        //Executing an AsyncOperation in the background
        let op = AsyncOperation({ (op) in
            print("Operation executed in the background!")
            
            op.finish()
        })
        op.completionBlock = { [weak self] in
            guard let strongSelf = self else { return }
            if let expectation = strongSelf.expectations.first(where: { $0.expectationDescription == strongSelf.testAsyncOperationInTheBackgroundDescription }) {
                expectation.fulfill()
                return
            }
        }
        backgroundQueue.addOperation(op)
        
        wait(for: expectations,
             timeout: 5)
    }
    
    let testAsyncOperationOnTheMainQueueDescription = "Executing an AsyncOperation on the main queue"
    func testAsyncOperationOnTheMainQueue() {
        expectations.append(expectation(description: testAsyncOperationOnTheMainQueueDescription))
        
        //Executing an AsyncOperation on the main operation queue
        let op = AsyncOperation({ (op) in
            print("On the main operation queue")
            
            op.finish()
        })
        op.completionBlock = { [weak self] in
            guard let strongSelf = self else { return }
            if let expectation = strongSelf.expectations.first(where: { $0.expectationDescription == strongSelf.testAsyncOperationOnTheMainQueueDescription }) {
                expectation.fulfill()
                return
            }
        }
        OperationQueue.main.addOperation(op)
        
        wait(for: expectations,
             timeout: 5)
    }
    
    let testTimeoutDescription = "Testing an AsyncOperation that times out"
    func testTimeout() {
        expectations.append(expectation(description: testTimeoutDescription))
        
        let executionDescription = testTimeoutDescription + " _executed"
        expectations.append(expectation(description: executionDescription))
        
        let startDate = Date()
        let dateDescription = testTimeoutDescription + " _date"
        expectations.append(expectation(description: dateDescription))
        
        //A timeout AsyncOperation
        let timeout: TimeInterval = 5
        let op = AsyncOperation(timeout: timeout) { [weak self] (op) in
            print("Waiting for timeout")
            
            self?.expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
        }
        op.completionBlock = { [weak self] in
            let interval = startDate.timeIntervalSinceNow
            XCTAssertTrue(interval < -timeout && interval > -(timeout + 1), "The time out should have been executed in aprox. \(timeout) second(s)")
            self?.expectations.first(where: { $0.expectationDescription == dateDescription })?.fulfill()
            
            guard let strongSelf = self else { return }
            if let expectation = strongSelf.expectations.first(where: { $0.expectationDescription == strongSelf.testTimeoutDescription }) {
                expectation.fulfill()
                return
            }
        }
        backgroundQueue.addOperation(op)
        
        wait(for: expectations,
             timeout: timeout * 2)
    }
    
    let testMovingBetweenThreadsInAsyncOperationDescription = "Executing a long running task in the background with dependencies; also moving between threads"
    func testMovingBetweenThreadsInAsyncOperation() {
        expectations.append(expectation(description: testMovingBetweenThreadsInAsyncOperationDescription))
        
        let description1 = testMovingBetweenThreadsInAsyncOperationDescription + " _1"
        let description2 = testMovingBetweenThreadsInAsyncOperationDescription + " _2"
        let description3 = testMovingBetweenThreadsInAsyncOperationDescription + " _3"
        let description4 = testMovingBetweenThreadsInAsyncOperationDescription + " _4"
        
        expectations.append(expectation(description: description1))
        expectations.append(expectation(description: description2))
        expectations.append(expectation(description: description3))
        expectations.append(expectation(description: description4))
        
        var hasFulfilled1 = false
        var hasFulfilled2 = false
        var hasFulfilled3 = false
        var hasFulfilled4 = false
        
        //Executing a long running task in the background with dependencies; also moving between threads
        var sequentialOperations = [Operation]()
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Sequencial async operation 1 - background")
            
            XCTAssertFalse(hasFulfilled1, "We shouldn't have fulfilled 1")
            XCTAssertFalse(hasFulfilled2, "We shouldn't have fulfilled 2")
            XCTAssertFalse(hasFulfilled3, "We shouldn't have fulfilled 3")
            
            self?.expectations.first(where: { $0.expectationDescription == description1 })?.fulfill()
            hasFulfilled1 = true
            
            XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
            XCTAssertFalse(hasFulfilled2, "We shouldn't have fulfilled 2")
            XCTAssertFalse(hasFulfilled3, "We shouldn't have fulfilled 3")
            
            XCTAssertFalse(hasFulfilled4, "We shouldn't have fulfilled 4")
            
            onTheMainThread {
                print("Sequencial async operation 1 - main thread")
                
                XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
                XCTAssertFalse(hasFulfilled2, "We shouldn't have fulfilled 2")
                XCTAssertFalse(hasFulfilled3, "We shouldn't have fulfilled 3")
                
                self?.expectations.first(where: { $0.expectationDescription == description2 })?.fulfill()
                hasFulfilled2 = true
                
                XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
                XCTAssertTrue(hasFulfilled2, "We should have fulfilled 2")
                XCTAssertFalse(hasFulfilled3, "We shouldn't have fulfilled 3")
                
                XCTAssertFalse(hasFulfilled4, "We shouldn't have fulfilled 4")
                
                inTheBackground {
                    print("Sequencial async operation 1 - background again")
                    
                    XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
                    XCTAssertTrue(hasFulfilled2, "We should have fulfilled 2")
                    XCTAssertFalse(hasFulfilled3, "We shouldn't have fulfilled 3")
                    
                    self?.expectations.first(where: { $0.expectationDescription == description3 })?.fulfill()
                    hasFulfilled3 = true
                    
                    XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
                    XCTAssertTrue(hasFulfilled2, "We should have fulfilled 2")
                    XCTAssertTrue(hasFulfilled3, "We should have fulfilled 3")
                    
                    XCTAssertFalse(hasFulfilled4, "We shouldn't have fulfilled 4")
                    
                    op.finish()
                }
            }
        })
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            print("Sequencial async operation 2")
            
            XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
            XCTAssertTrue(hasFulfilled2, "We should have fulfilled 2")
            XCTAssertTrue(hasFulfilled3, "We should have fulfilled 3")
            
            XCTAssertFalse(hasFulfilled4, "We shouldn't have fulfilled 4")
            
            self?.expectations.first(where: { $0.expectationDescription == description4 })?.fulfill()
            hasFulfilled4 = true
            
            XCTAssertTrue(hasFulfilled4, "We should have fulfilled 4")
            
            op.finish()
        })
        
        sequentialOperations.append(AsyncOperation { [weak self] (op) in
            guard let strongSelf = self else { return }
            if let expectation = strongSelf.expectations.first(where: { $0.expectationDescription == strongSelf.testMovingBetweenThreadsInAsyncOperationDescription }) {
                expectation.fulfill()
                return
            }
        })
        
        backgroundQueue.addSequentialOperations(sequentialOperations,
                                                waitUntilFinished: false)
        
        wait(for: expectations,
             timeout: 7)
    }
}

extension AsyncOperationTests
{
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue) {
        //Noop
    }
    
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue) {
        //Noop
    }
}

extension AsyncOperationTests
{
    static var allTests : [(String, (AsyncOperationTests) -> () throws -> Swift.Void)] {
        return [
            ("testAsyncOperationInTheBackground", testAsyncOperationInTheBackground),
            ("testAsyncOperationOnTheMainQueue", testAsyncOperationOnTheMainQueue),
            ("testTimeout", testTimeout),
            ("testMovingBetweenThreadsInAsyncOperation", testMovingBetweenThreadsInAsyncOperation)
        ]
    }
}


class AsyncOperationCancellationTest: XCTestCase, BackgroundQueueTest
{
    let backgroundQueue: BackgroundQueue = BackgroundQueue()
    var expectations: [XCTestExpectation] = []
    
    override func setUp() {
        super.setUp()
        
        setUpBackgroundQueue()
        expectations = []
    }
    
    let testCancellingAnOperationDescription = "Testing cancelling an AsyncOperation"
    func testCancellingAnOperation() {
        expectations.append(expectation(description: testCancellingAnOperationDescription + " _final"))
        expectations.last!.isInverted = true
        
        let executionDescription = testCancellingAnOperationDescription + " _executed"
        expectations.append(expectation(description: executionDescription))
        
        expectations.append(expectation(description: testCancellingAnOperationDescription + " _first"))
        
        let startDate = Date()
        let dateDescription = testCancellingAnOperationDescription + " _date"
        expectations.append(expectation(description: dateDescription))
        
        //A timeout AsyncOperation
        let op = AsyncOperation(timeout: 5) { [weak self] (op) in
            print("Executing Operation")
            
            self?.expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
        }
        op.completionBlock = { [weak self] in
            XCTAssertTrue(startDate.timeIntervalSinceNow > -5, "We shouldn't have waited 5 seconds to execute this")
            self?.expectations.first(where: { $0.expectationDescription == dateDescription })?.fulfill()
        }
        backgroundQueue.addOperation(op)
        
        DispatchQueue.async(in: 3) {
            op.cancel()
        }
        
        wait(for: expectations,
             timeout: 10)
    }
}

extension AsyncOperationCancellationTest
{
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue) {
        //Noop
    }
    
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
    {
        guard queue == backgroundQueue else { return }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationDescription + " _first" }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationDescription + " _final" }) {
            //aka This should never happen
            expectation.fulfill()
            return
        }
    }
}

extension AsyncOperationCancellationTest
{
    static var allTests : [(String, (AsyncOperationCancellationTest) -> () throws -> Swift.Void)] {
        return [
            ("testCancellingAnOperation", testCancellingAnOperation)
        ]
    }
}


class AsyncOperationMultipleCancellationTest: XCTestCase, BackgroundQueueTest
{
    let backgroundQueue: BackgroundQueue = BackgroundQueue()
    var expectations: [XCTestExpectation] = []
    
    override func setUp() {
        super.setUp()
        
        setUpBackgroundQueue()
        expectations = []
    }
    
    let testCancellingMultipleOperationsDescription = "Testing cancelling multiple AsyncOperations"
    func testCancellingMultipleOperations() {
        expectations.append(expectation(description: testCancellingMultipleOperationsDescription))
        
        let executionDescription1 = testCancellingMultipleOperationsDescription + " _executed1"
        expectations.append(expectation(description: executionDescription1))
        
        let executionDescription2 = testCancellingMultipleOperationsDescription + " _executed2"
        expectations.append(expectation(description: executionDescription2))
        expectations.last!.isInverted = true
        
        //A timeout AsyncOperation
        backgroundQueue.addSequentialOperations(
            [
                AsyncOperation(timeout: 5) { [weak self] (op) in
                    print("Executing Operation 1")
                    
                    self?.expectations.first(where: { $0.expectationDescription == executionDescription1 })?.fulfill()
                },
                AsyncOperation { [weak self] (op) in
                    print("Executing Operation 2 (aka THIS SHOULD NEVER HAPPEN) isCancelled: \(op.isCancelled)")
                    
                    self?.expectations.first(where: { $0.expectationDescription == executionDescription2 })?.fulfill()
                }
            ], waitUntilFinished: false)
        
        DispatchQueue.async(in: 3) { [weak self] in
            self?.backgroundQueue.cancelAllOperations()
        }
        
        wait(for: expectations,
             timeout: 6)
    }
}

extension AsyncOperationMultipleCancellationTest
{
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue) {
        //Noop
    }
    
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
    {
        guard queue == backgroundQueue else { return }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingMultipleOperationsDescription }) {
            expectation.fulfill()
            return
        }
    }
}

extension AsyncOperationMultipleCancellationTest
{
    static var allTests : [(String, (AsyncOperationMultipleCancellationTest) -> () throws -> Swift.Void)] {
        return [
            ("testCancellingMultipleOperations", testCancellingMultipleOperations)
        ]
    }
}


class AsyncOperationCancellationTimeoutTest: XCTestCase, BackgroundQueueTest
{
    let backgroundQueue: BackgroundQueue = BackgroundQueue()
    var expectations: [XCTestExpectation] = []
    
    override func setUp() {
        super.setUp()
        
        setUpBackgroundQueue()
        expectations = []
    }
    
    let testCancellingAnOperationShouldntWaitForTheTimeoutDescription = "Testing cancelling an AsyncOperation should't wait for its timeout"
    func testCancellingAnOperationShouldntWaitForTheTimeout() {
        expectations.append(expectation(description: testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _final"))
        expectations.last!.isInverted = true
        
        let executionDescription = testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _executed"
        expectations.append(expectation(description: executionDescription))
        
        expectations.append(expectation(description: testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _first"))
        
        let startDate = Date()
        let dateDescription = testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _date"
        expectations.append(expectation(description: dateDescription))
        
        //A timeout AsyncOperation
        let op = AsyncOperation(timeout: 60) { [weak self] (op) in
            print("Executing Operation")
            
            self?.expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
        }
        op.completionBlock = { [weak self] in
            XCTAssertTrue(startDate.timeIntervalSinceNow > -60, "We shouldn't have waited 60 seconds to execute this")
            self?.expectations.first(where: { $0.expectationDescription == dateDescription })?.fulfill()
        }
        backgroundQueue.addOperation(op)
        
        DispatchQueue.async(in: 3) { [weak self] in
            self?.backgroundQueue.cancelAllOperations()
        }
        
        wait(for: expectations,
             timeout: 10)
    }
}

extension AsyncOperationCancellationTimeoutTest
{
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue) {
        //Noop
    }
    
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
    {
        guard queue == backgroundQueue else { return }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _first" }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _final" }) {
            expectation.fulfill()
            return
        }
    }
}

extension AsyncOperationCancellationTimeoutTest
{
    static var allTests : [(String, (AsyncOperationCancellationTimeoutTest) -> () throws -> Swift.Void)] {
        return [
            ("testCancellingAnOperationShouldntWaitForTheTimeout", testCancellingAnOperationShouldntWaitForTheTimeout)
        ]
    }
}
