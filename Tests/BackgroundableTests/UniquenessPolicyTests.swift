import XCTest
@testable import Backgroundable


class UniquenessPolicyTests: XCTestCase, BackgroundQueueTest
{
    let backgroundQueue: BackgroundQueue = {
        let result = BackgroundQueue()
        result.maxConcurrentOperationCount = 1
        return result
    }()
    var expectations: [XCTestExpectation] = []

    override func setUp() {
        super.setUp()

        setUpBackgroundQueue()
        expectations = []
    }

    let testOperationsWithNoNameAreIgnoredDescription = "Operations with no name ignore uniqueness policy"
    func testOperationsWithNoNameAreIgnored() {
        backgroundQueue.isSuspended = true

        expectations.append(expectation(description: testOperationsWithNoNameAreIgnoredDescription + "_1"))
        backgroundQueue.addOperation(AsyncOperation(uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testOperationsWithNoNameAreIgnoredDescription)_1" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        expectations.append(expectation(description: testOperationsWithNoNameAreIgnoredDescription + "_2"))
        backgroundQueue.addOperation(AsyncOperation(name: testOperationsWithNoNameAreIgnoredDescription, uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testOperationsWithNoNameAreIgnoredDescription)_2" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        expectations.append(expectation(description: testOperationsWithNoNameAreIgnoredDescription + "_3"))
        backgroundQueue.addOperation(AsyncOperation(name: "Something", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testOperationsWithNoNameAreIgnoredDescription)_3" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)
    }

    let testFinishedOperationsAreIgnoredDescription = "Finished operations ignore uniqueness policy"
    func testFinishedOperationsAreIgnored() {

        expectations.append(expectation(description: testFinishedOperationsAreIgnoredDescription + "_1"))
        let finishedOp = AsyncOperation(name: testFinishedOperationsAreIgnoredDescription, uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testFinishedOperationsAreIgnoredDescription)_1" }) {
                expectation.fulfill()
            }
            DispatchQueue.async(in: 0.1) {
                op.finish()
            }
        }
        backgroundQueue.addOperation(finishedOp)

        DispatchQueue.async(in: 0.1) { [weak self] in
            DispatchQueue.main.sync {
                guard let self = self else { return }
                self.expectations.append(self.expectation(description: self.testFinishedOperationsAreIgnoredDescription + "_2"))
                self.backgroundQueue.addOperation(AsyncOperation(name: self.testFinishedOperationsAreIgnoredDescription, uniquenessPolicy: .drop) { (op) in
                    print("Operation executed in the background!")
                    XCTAssertEqual(finishedOp.isFinished, true, "The first operation should be finished by now")
                    if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testFinishedOperationsAreIgnoredDescription)_2" }) {
                        expectation.fulfill()
                    }
                    op.finish()
                })
            }
        }

        wait(for: expectations,
             timeout: 5)
    }

    let testCancelledOperationsDescription = "Cancelled operations with uniqueness policy"
    func testCancelledOperations() {
        backgroundQueue.isSuspended = true

        expectations.append(expectation(description: testCancelledOperationsDescription + "_1"))
        expectations.last!.isInverted = true
        let op1 = AsyncOperation(name: testCancelledOperationsDescription + "_A", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_1" }) {
                expectation.fulfill()
            }
            op.finish()
        }
        backgroundQueue.addOperation(op1)
        backgroundQueue.operations.last!.cancel()

        expectations.append(expectation(description: testCancelledOperationsDescription + "_2"))
        backgroundQueue.addOperation(AsyncOperation(name: testCancelledOperationsDescription + "_A", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            XCTAssertEqual(op1.isCancelled, true, "The operation should have been cancelled here")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_2" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        expectations.append(expectation(description: testCancelledOperationsDescription + "_3"))
        expectations.last!.isInverted = true
        let op2 = AsyncOperation(name: testCancelledOperationsDescription + "_B", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_3" }) {
                expectation.fulfill()
            }
            op.finish()
        }
        backgroundQueue.addOperation(op2)
        backgroundQueue.operations.last!.cancel()

        expectations.append(expectation(description: testCancelledOperationsDescription + "_4"))
        backgroundQueue.addOperation(AsyncOperation(name: testCancelledOperationsDescription + "_B", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            XCTAssertEqual(op2.isCancelled, true, "The operation should have been cancelled here")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_4" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)

        expectations = []
        backgroundQueue.isSuspended = true

        expectations.append(expectation(description: testCancelledOperationsDescription + "_5"))
        backgroundQueue.addOperation(AsyncOperation(name: testCancelledOperationsDescription + "_C", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_5" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        expectations.append(expectation(description: testCancelledOperationsDescription + "_6"))
        expectations.last!.isInverted = true
        let op3 = AsyncOperation(name: testCancelledOperationsDescription + "_C", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_6" }) {
                expectation.fulfill()
            }
            op.finish()
        }
        backgroundQueue.addOperation(op3)
        XCTAssertEqual(op3.isCancelled, false, "The operation should NOT have been cancelled here")

        expectations.append(expectation(description: testCancelledOperationsDescription + "_6"))
        expectations.last!.isInverted = true
        let op4 = AsyncOperation(name: testCancelledOperationsDescription + "_D", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_6" }) {
                expectation.fulfill()
            }
            op.finish()
        }
        backgroundQueue.addOperation(op4)

        expectations.append(expectation(description: testCancelledOperationsDescription + "_7"))
        backgroundQueue.addOperation(AsyncOperation(name: testCancelledOperationsDescription + "_D", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testCancelledOperationsDescription)_7" }) {
                expectation.fulfill()
            }
            op.finish()
        })
        XCTAssertEqual(op4.isCancelled, true, "The operation should have been cancelled here")

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)
    }

    let testExecutingOperationsDescription = "Executing operations with uniqueness policy"
    func testExecutingOperations() {
        backgroundQueue.isSuspended = true

        expectations.append(expectation(description: testExecutingOperationsDescription + "_1"))
        let op1 = AsyncOperation(name: testExecutingOperationsDescription + "_A", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            DispatchQueue.async(in: 1) {
                print("Operation executed in the background!")
                if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testExecutingOperationsDescription)_1" }) {
                    expectation.fulfill()
                }
                op.finish()
            }
        }
        backgroundQueue.addOperation(op1)

        expectations.append(expectation(description: testExecutingOperationsDescription + "_2"))
        expectations.last!.isInverted = true
        backgroundQueue.addOperation(AsyncOperation(name: testExecutingOperationsDescription + "_A", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testExecutingOperationsDescription)_2" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        expectations.append(expectation(description: testExecutingOperationsDescription + "_3"))
        expectations.last!.isInverted = true
        let op2 = AsyncOperation(name: testExecutingOperationsDescription + "_B", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            DispatchQueue.async(in: 1) {
                print("Operation executed in the background!")
                if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testExecutingOperationsDescription)_3" }) {
                    expectation.fulfill()
                }
                op.finish()
            }
        }
        backgroundQueue.addOperation(op2)

        expectations.append(expectation(description: testExecutingOperationsDescription + "_4"))
        backgroundQueue.addOperation(AsyncOperation(name: testExecutingOperationsDescription + "_B", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            XCTAssertEqual(op2.isExecuting, false, "The operation should NOT be executing here")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testExecutingOperationsDescription)_4" }) {
                expectation.fulfill()
            }
            op.finish()
        })

        backgroundQueue.isSuspended = false

        DispatchQueue.async(in: 0.3) {
            DispatchQueue.main.sync {
                XCTAssertEqual(op1.isExecuting, true, "The operation should be executing here")
            }
        }

        wait(for: expectations,
             timeout: 5)
    }

    let testDroppingOperationsDescription = "Dropping operations with uniqueness policy"
    func testDroppingOperations() {
        backgroundQueue.isSuspended = true

        expectations.append(expectation(description: testDroppingOperationsDescription + "_1"))
        let op1 = AsyncOperation(name: testDroppingOperationsDescription + "_A", uniquenessPolicy: .drop) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testDroppingOperationsDescription)_1" }) {
                expectation.fulfill()
            }
            op.finish()
        }
        backgroundQueue.addOperation(op1)

        (2...3).forEach { i in
            expectations.append(expectation(description: testDroppingOperationsDescription + "_\(i)"))
            expectations.last!.isInverted = true
            backgroundQueue.addOperation(AsyncOperation(name: testDroppingOperationsDescription + "_A", uniquenessPolicy: .drop) { [weak self] (op) in
                guard let self = self else { XCTFail(); return }
                print("Operation executed in the background!")
                if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testDroppingOperationsDescription)_\(i)" }) {
                    expectation.fulfill()
                }
                op.finish()
            })
        }

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)

        XCTAssertEqual(op1.isCancelled, false, "The operation should NOT have been cancelled")

        backgroundQueue.isSuspended = true
        expectations = []

        backgroundQueue.addOperations((4...5).map { i in
            expectations.append(expectation(description: testDroppingOperationsDescription + "_\(i)"))
            return AsyncOperation(name: testDroppingOperationsDescription + "_B", uniquenessPolicy: .drop) { [weak self] (op) in
                guard let self = self else { XCTFail(); return }
                print("Operation executed in the background!")
                if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testDroppingOperationsDescription)_\(i)" }) {
                    expectation.fulfill()
                }
                op.finish()
            }
        }, waitUntilFinished: false)

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)
    }

    let testReplacingOperationsDescription = "Replacing operations with uniqueness policy"
    func testReplacingOperations() {
        backgroundQueue.isSuspended = true

        (1...2).forEach { i in
            expectations.append(expectation(description: testReplacingOperationsDescription + "_\(i)"))
            expectations.last!.isInverted = true
            backgroundQueue.addOperation(AsyncOperation(name: testReplacingOperationsDescription + "_A", uniquenessPolicy: .replace) { [weak self] (op) in
                guard let self = self else { XCTFail(); return }
                print("Operation executed in the background!")
                if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testReplacingOperationsDescription)_\(i)" }) {
                    expectation.fulfill()
                }
                op.finish()
            })
        }

        expectations.append(expectation(description: testReplacingOperationsDescription + "_3"))
        let op1 = AsyncOperation(name: testReplacingOperationsDescription + "_A", uniquenessPolicy: .replace) { [weak self] (op) in
            guard let self = self else { XCTFail(); return }
            print("Operation executed in the background!")
            if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testReplacingOperationsDescription)_3" }) {
                expectation.fulfill()
            }
            op.finish()
        }
        backgroundQueue.addOperation(op1)

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)

        XCTAssertEqual(op1.isCancelled, false, "The operation should NOT have been cancelled")

        backgroundQueue.isSuspended = true
        expectations = []

        backgroundQueue.addOperations((1...2).map { i in
            expectations.append(expectation(description: testReplacingOperationsDescription + "_\(i)"))
            return AsyncOperation(name: testReplacingOperationsDescription + "_B", uniquenessPolicy: .replace) { [weak self] (op) in
                guard let self = self else { XCTFail(); return }
                print("Operation executed in the background!")
                if let expectation = self.expectations.first(where: { $0.expectationDescription == "\(self.testReplacingOperationsDescription)_\(i)" }) {
                    expectation.fulfill()
                }
                op.finish()
            }
        }, waitUntilFinished: false)

        backgroundQueue.isSuspended = false

        wait(for: expectations,
             timeout: 5)
    }
}

extension UniquenessPolicyTests
{
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue) {
        //Noop
    }

    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue) {
        //Noop
    }
}

extension UniquenessPolicyTests
{
    static var allTests : [(String, (UniquenessPolicyTests) -> () throws -> Swift.Void)] {
        return [
            ("testOperationsWithNoNameAreIgnored", testOperationsWithNoNameAreIgnored),
            ("testFinishedOperationsAreIgnored", testFinishedOperationsAreIgnored),
            ("testCancelledOperations", testCancelledOperations),
            ("testExecutingOperations", testExecutingOperations),
            ("testDroppingOperations", testDroppingOperations),
            ("testReplacingOperations", testReplacingOperations)
        ]
    }
}
