/*
 Copyright (c) 2018 Bell App Lab <apps@bellapplab.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation


@objc
public extension OperationQueue
{
    /**
     The global background queue.
     
     The returned queue is an instance of `BackgroundQueue`.
     
     ## See Also:
     `Backgroundable.BackgroundQueue`
     */
    @objc(backgroundQueue)
    static let background = BackgroundQueue()
    
    /**
     Takes several operations and sets them as dependant on one another, so they are executed sequentially. In other words:
     
     ```
     var operations = [firstOperation, secondOperation, thirdOperation]
     queue.addSequentialOperations(operations, waitUntilFinished: false)
     
     //is equivalent to
     
     secondOperation.addDependency(firstOperation)
     thirdOperation.addDependency(secondOperation)
     ```
     
     - parameters:
         - ops: The array of `Operations` to be enqueued.
         - waitUntilFinished: See `OperationQueue.addOperations(_:waitUntilFinished:)`
     */
    @objc
    func addSequentialOperations(_ ops: [Operation],
                                 waitUntilFinished wait: Bool)
    {
        if ops.count > 1 {
            for i in 1..<ops.count {
                ops[i].addDependency(ops[i - 1])
            }
        }
        
        addOperations(ops,
                      waitUntilFinished: wait)
    }

    /**
     Enqueues a new `AsyncOperation` to be executed on this queue.

     - parameters:
         - name: The name of the operation. Useful for debugging. Defaults to `nil`.
         - timeout: The time in seconds after which this operation should be marked as finished and removed from the queue. Defaults to 10.
         - closure: The closure to be executed by the operation. The closure takes a `AsyncOperation` parameter. Call `finish()` on the object passed here.
     */
    @nonobjc
    func addAsyncOperation(name: String? = nil,
                           timeout: TimeInterval = 10,
                           _ closure: @escaping (_ operation: AsyncOperation) -> Swift.Void)
    {
        addOperation(AsyncOperation(name: name, timeout: timeout, closure))
    }
}
