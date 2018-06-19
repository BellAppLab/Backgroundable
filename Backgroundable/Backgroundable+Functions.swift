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


//MARK: - Functions
/**
 The easiest way to execute code in the background.
 
 - parameters:
 - closure: The closure to be executed in the background.
 */
public func inTheBackground(_ closure: @escaping () -> Swift.Void)
{
    OperationQueue.background.addOperation(closure)
}

/**
 The easiest way to excute code on the main thread.
 
 - parameters:
 - closure: The closure to be executed on the main thread.
 */
public func onTheMainThread(_ closure: @escaping () -> Swift.Void)
{
    OperationQueue.main.addOperation(closure)
}

/**
 The easiest way to excute code in the global background queue.
 
 - parameters:
 - closure: The closure to be executed in the global background queue.
 */
public func inTheGlobalQueue(_ closure: @escaping () -> Swift.Void)
{
    DispatchQueue.global(qos: .background).async(execute: closure)
}
