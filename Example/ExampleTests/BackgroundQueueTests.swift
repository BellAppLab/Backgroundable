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
        let description1 = testSequentialOperationsInTheBackgroundDescription + "_1"
        let description2 = testSequentialOperationsInTheBackgroundDescription + "_2"
        let description3 = testSequentialOperationsInTheBackgroundDescription + "_3"
        
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
        
        let executionDescription = testTimeoutDescription + "_executed"
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
        
        let description1 = testMovingBetweenThreadsInAsyncOperationDescription + "_1"
        let description2 = testMovingBetweenThreadsInAsyncOperationDescription + "_2"
        let description3 = testMovingBetweenThreadsInAsyncOperationDescription + "_3"
        let description4 = testMovingBetweenThreadsInAsyncOperationDescription + "_4"
        
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
    }
}
