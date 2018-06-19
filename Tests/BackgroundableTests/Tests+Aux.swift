import XCTest
@testable import Backgroundable


protocol BackgroundQueueTest: BackgroundQueueDelegate {
    var backgroundQueue: BackgroundQueue { get }
    var expectations: [XCTestExpectation] { get set }
}


extension BackgroundQueueTest
{
    func setUpBackgroundQueue() {
        backgroundQueue.delegate = self
    }
}


extension DispatchQueue
{
    static func async(in timeInterval: TimeInterval, _ block: @escaping () -> Swift.Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval, execute: block)
    }
}
