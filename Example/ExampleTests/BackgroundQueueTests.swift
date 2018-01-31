//
//  BackgroundQueueTests.swift
//  ExampleTests
//
//  Created by André Campana on 31.01.18.
//  Copyright © 2018 Bell App Lab. All rights reserved.
//

import XCTest


var expectations: [XCTestExpectation] = []


class BackgroundQueueTests: XCTestCase
{
    var backgroundQueue: BackgroundQueue!
    
    override func setUp() {
        super.setUp()
        
        self.backgroundQueue = BackgroundQueue()
        self.backgroundQueue.delegate = self
    }
    
    override func tearDown() {
        expectations = []
        
        super.tearDown()
    }
    
    let testMainThreadDescription = "Executing on the main thread"
    func testMainThread() {
        expectations.append(self.expectation(description: testMainThreadDescription))
        
        //Printing on the main thread
        onTheMainThread {
            XCTAssertTrue(Thread.isMainThread, "We should be on the main thread")
            print("Are we on the main thread? \(Thread.isMainThread)")
            
            expectations.forEach {
                $0.fulfill()
            }
        }
        
        self.wait(for: expectations,
                  timeout: 5)
    }
    
    let testBackgroundDescription = "Executing in the background"
    func testBackground() {
        expectations.append(self.expectation(description: testBackgroundDescription))
        
        //Printing in the background
        inTheBackground {
            XCTAssertFalse(Thread.isMainThread, "We shouldn't be on the main thread")
            print("Are we in the background? \(!Thread.isMainThread)")
            
            expectations.forEach {
                $0.fulfill()
            }
        }
        
        self.wait(for: expectations,
                  timeout: 5)
    }
    
    let testAsyncOperationInTheBackgroundDescription = "Executing an AsyncOperation in the background"
    func testAsyncOperationInTheBackground() {
        expectations.append(self.expectation(description: testAsyncOperationInTheBackgroundDescription))
        
        //Executing an AsyncOperation in the background
        let op = AsyncOperation { (operation) in
            print("Operation executed in the background!")
            operation.finish()
        }
        self.backgroundQueue.addOperation(op)
        
        self.wait(for: expectations,
                  timeout: 10)
    }
    
    let testAsyncOperationOnTheMainQueueDescription = "Executing an AsyncOperation on the main queue"
    func testAsyncOperationOnTheMainQueue() {
        expectations.append(self.expectation(description: testAsyncOperationOnTheMainQueueDescription))
        
        //Executing an AsyncOperation on the main operation queue
        OperationQueue.main.addOperation(AsyncOperation { (op) in
            print("On the main operation queue")
            op.finish()
            
            expectations.forEach {
                $0.fulfill()
            }
        })
        
        self.wait(for: expectations,
                  timeout: 5)
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
        sequentialOperations.append(AsyncOperation { (op) in
            print("Executing sequential operation 1")
            
            XCTAssertFalse(hasFulfilledOperation1, "We shouldn't have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            expectations.first(where: { $0.expectationDescription == description1 })?.fulfill()
            hasFulfilledOperation1 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(self.expectation(description: description1))
        
        sequentialOperations.append(AsyncOperation { (op) in
            print("Executing sequential operation 2")
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertFalse(hasFulfilledOperation2, "We shouldn't have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            expectations.first(where: { $0.expectationDescription == description2 })?.fulfill()
            hasFulfilledOperation2 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(self.expectation(description: description2))
        
        sequentialOperations.append(AsyncOperation { (op) in
            print("Executing sequential operation 3")
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertFalse(hasFulfilledOperation3, "We shouldn't have fulfilled operation 3")
            
            expectations.first(where: { $0.expectationDescription == description3 })?.fulfill()
            hasFulfilledOperation3 = true
            
            XCTAssertTrue(hasFulfilledOperation1, "We should have fulfilled operation 1")
            XCTAssertTrue(hasFulfilledOperation2, "We should have fulfilled operation 2")
            XCTAssertTrue(hasFulfilledOperation3, "We should have fulfilled operation 3")
            
            op.finish()
        })
        expectations.append(self.expectation(description: description3))
        
        expectations.append(self.expectation(description: testSequentialOperationsInTheBackgroundDescription))
        
        self.backgroundQueue.addSequentialOperations(sequentialOperations,
                                                     waitUntilFinished: false)
        
        self.wait(for: expectations,
                  timeout: 20)
    }
    
    let testTimeoutDescription = "Testing an AsyncOperation that times out"
    func testTimeout() {
        expectations.append(self.expectation(description: testTimeoutDescription))
        
        let executionDescription = testTimeoutDescription + " _executed"
        expectations.append(self.expectation(description: executionDescription))
        
        //A timeout AsyncOperation
        self.backgroundQueue.addOperation(AsyncOperation(timeout: 2) { (op) in
            print("Waiting for timeout")
            
            expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
            
            
        })
        
        self.wait(for: expectations,
                  timeout: 10)
    }
    
    let testMovingBetweenThreadsInAsyncOperationDescription = "Executing a long running task in the background with dependencies; also moving between threads"
    func testMovingBetweenThreadsInAsyncOperation() {
        expectations.append(self.expectation(description: testMovingBetweenThreadsInAsyncOperationDescription))
        
        let description1 = testMovingBetweenThreadsInAsyncOperationDescription + " _1"
        let description2 = testMovingBetweenThreadsInAsyncOperationDescription + " _2"
        let description3 = testMovingBetweenThreadsInAsyncOperationDescription + " _3"
        let description4 = testMovingBetweenThreadsInAsyncOperationDescription + " _4"
        
        expectations.append(self.expectation(description: description1))
        expectations.append(self.expectation(description: description2))
        expectations.append(self.expectation(description: description3))
        expectations.append(self.expectation(description: description4))
        
        var hasFulfilled1 = false
        var hasFulfilled2 = false
        var hasFulfilled3 = false
        var hasFulfilled4 = false
        
        //Executing a long running task in the background with dependencies; also moving between threads
        var sequentialOperations = [Operation]()
        sequentialOperations.append(AsyncOperation { (op) in
            print("Sequencial async operation 1 - background")
            
            XCTAssertFalse(hasFulfilled1, "We shouldn't have fulfilled 1")
            XCTAssertFalse(hasFulfilled2, "We shouldn't have fulfilled 2")
            XCTAssertFalse(hasFulfilled3, "We shouldn't have fulfilled 3")
            
            expectations.first(where: { $0.expectationDescription == description1 })?.fulfill()
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
                
                expectations.first(where: { $0.expectationDescription == description2 })?.fulfill()
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
                    
                    expectations.first(where: { $0.expectationDescription == description3 })?.fulfill()
                    hasFulfilled3 = true
                    
                    XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
                    XCTAssertTrue(hasFulfilled2, "We should have fulfilled 2")
                    XCTAssertTrue(hasFulfilled3, "We should have fulfilled 3")
                    
                    XCTAssertFalse(hasFulfilled4, "We shouldn't have fulfilled 4")
                    
                    op.finish()
                }
            }
        })
        
        sequentialOperations.append(AsyncOperation { (op) in
            print("Sequencial async operation 2")
            
            XCTAssertTrue(hasFulfilled1, "We should have fulfilled 1")
            XCTAssertTrue(hasFulfilled2, "We should have fulfilled 2")
            XCTAssertTrue(hasFulfilled3, "We should have fulfilled 3")
            
            XCTAssertFalse(hasFulfilled4, "We shouldn't have fulfilled 4")
            
            expectations.first(where: { $0.expectationDescription == description4 })?.fulfill()
            hasFulfilled4 = true
            
            XCTAssertTrue(hasFulfilled4, "We should have fulfilled 4")
            
            op.finish()
        })
        
        self.backgroundQueue.addSequentialOperations(sequentialOperations,
                                                     waitUntilFinished: false)
        
        self.wait(for: expectations,
                  timeout: 7)
    }
    
    let testCancellingAnOperationDescription = "Testing cancelling an AsyncOperation"
    func testCancellingAnOperation() {
        expectations.append(self.expectation(description: testCancellingAnOperationDescription + " _final"))
        expectations.last!.isInverted = true
        
        let executionDescription = testCancellingAnOperationDescription + " _executed"
        expectations.append(self.expectation(description: executionDescription))
        
        expectations.append(self.expectation(description: testCancellingAnOperationDescription + " _first"))
        
        //A timeout AsyncOperation
        self.backgroundQueue.addOperation(AsyncOperation(timeout: 5) { (op) in
            print("Executing Operation")
            
            expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
        })
        
        Timer.scheduledTimer(withTimeInterval: 3,
                             repeats: false)
        { [weak self] (timer) in
            timer.invalidate()
            self?.backgroundQueue.cancelAllOperations()
        }
        
        self.wait(for: expectations,
                  timeout: 10)
    }
    
    let testCancellingMultipleOperationsDescription = "Testing cancelling multiple AsyncOperations"
    func testCancellingMultipleOperations() {
        expectations.append(self.expectation(description: testCancellingMultipleOperationsDescription))
        
        let executionDescription1 = testCancellingMultipleOperationsDescription + " _executed1"
        expectations.append(self.expectation(description: executionDescription1))
        
        let executionDescription2 = testCancellingMultipleOperationsDescription + " _executed2"
        expectations.append(self.expectation(description: executionDescription2))
        expectations.last!.isInverted = true
        
        //A timeout AsyncOperation
        self.backgroundQueue.addSequentialOperations(
            [
            AsyncOperation(timeout: 5) { (op) in
                print("Executing Operation 1")
                
                expectations.first(where: { $0.expectationDescription == executionDescription1 })?.fulfill()
            },
            AsyncOperation(timeout: 5) { (op) in
                print("Executing Operation 2")
                
                expectations.first(where: { $0.expectationDescription == executionDescription2 })?.fulfill()
            }
            ], waitUntilFinished: false)
        
        Timer.scheduledTimer(withTimeInterval: 3,
                             repeats: false)
        { [weak self] (timer) in
            timer.invalidate()
            self?.backgroundQueue.cancelAllOperations()
        }
        
        self.wait(for: expectations,
                  timeout: 6)
    }
    
    let testCancellingAnOperationBeforeItStartsDescription = "Testing cancelling an AsyncOperation before it starts"
    func testCancellingAnOperationBeforeItStarts() {
        expectations.append(self.expectation(description: testCancellingAnOperationBeforeItStartsDescription))
        
        let executionDescription = testCancellingAnOperationBeforeItStartsDescription + " _executed1"
        expectations.append(self.expectation(description: executionDescription))
        expectations.last!.isInverted = true
        
        self.backgroundQueue.isSuspended = true
        
        //A timeout AsyncOperation
        self.backgroundQueue.addOperation(AsyncOperation(timeout: 5) { (op) in
            print("Executing Operation")
            
            expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
        })
        
        self.backgroundQueue.cancelAllOperations()
        
        Timer.scheduledTimer(withTimeInterval: 3,
                             repeats: false)
        { [weak self] (timer) in
            timer.invalidate()
            self?.backgroundQueue.isSuspended = false
        }
        
        self.wait(for: expectations,
                  timeout: 6)
    }
    
    let testCancellingAnOperationShouldntWaitForTheTimeoutDescription = "Testing cancelling an AsyncOperation should't wait for its timeout"
    func testCancellingAnOperationShouldntWaitForTheTimeout() {
        expectations.append(self.expectation(description: testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _final"))
        expectations.last!.isInverted = true
        
        let executionDescription = testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _executed"
        expectations.append(self.expectation(description: executionDescription))
        
        expectations.append(self.expectation(description: testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _first"))
        
        //A timeout AsyncOperation
        self.backgroundQueue.addOperation(AsyncOperation(timeout: 60) { (op) in
            print("Executing Operation")
            
            expectations.first(where: { $0.expectationDescription == executionDescription })?.fulfill()
        })
        
        Timer.scheduledTimer(withTimeInterval: 3,
                             repeats: false)
        { [weak self] (timer) in
            timer.invalidate()
            self?.backgroundQueue.cancelAllOperations()
        }
        
        self.wait(for: expectations,
                  timeout: 10)
    }
    
    let testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription = "A sequential operation shoudn't start before its dependency has finished"
    func testSequentialOperationShouldntStartBeforeDependencyHasFinished() {
        expectations.append(self.expectation(description: testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription))
        
        let executionDescription1 = testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription + " _executed1"
        expectations.append(self.expectation(description: executionDescription1))
        
        let executionDescription2 = testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription + " _not_executed2"
        expectations.append(self.expectation(description: executionDescription2))
        
        var expectationNot2: XCTestExpectation? = self.expectation(description: testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription + " _not_executed2")
        expectations.append(expectationNot2!)
        expectationNot2!.isInverted = true
        
        Timer.scheduledTimer(withTimeInterval: 4.5,
                             repeats: false)
        { (timer) in
            timer.invalidate()
            expectationNot2 = nil
        }
        
        //A timeout AsyncOperation
        self.backgroundQueue.addSequentialOperations(
            [
                AsyncOperation(timeout: 5) { (op) in
                    print("Executing Operation 1")
                    
                    expectations.first(where: { $0.expectationDescription == executionDescription1 })?.fulfill()
                },
                AsyncOperation { (op) in
                    print("Executing Operation 2")
                    
                    expectations.first(where: { $0.expectationDescription == executionDescription2 })?.fulfill()
                    
                    expectationNot2?.fulfill()
                    
                    op.finish()
                }
            ], waitUntilFinished: false)
        
        self.wait(for: expectations,
                  timeout: 10)
    }
}


extension BackgroundQueueTests: BackgroundQueueDelegate
{
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
    {
        guard queue == self.backgroundQueue else { return }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testAsyncOperationInTheBackgroundDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testSequentialOperationsInTheBackgroundDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testTimeoutDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testMovingBetweenThreadsInAsyncOperationDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationDescription + " _first" }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationDescription + " _final" }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingMultipleOperationsDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationBeforeItStartsDescription }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _first" }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testCancellingAnOperationShouldntWaitForTheTimeoutDescription + " _final" }) {
            expectation.fulfill()
            return
        }
        
        if let expectation = expectations.first(where: { $0.expectationDescription == testSequentialOperationShouldntStartBeforeDependencyHasFinishedDescription }) {
            expectation.fulfill()
            return
        }
    }
}
