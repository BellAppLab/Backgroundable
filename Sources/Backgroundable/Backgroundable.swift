//Adapted from: https://github.com/mattgallagher/CwlUtils
/*
 ISC License
 
 Copyright © 2017 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
 
 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.
 
 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
 IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

private final class PThreadMutex {
    func sync<R>(execute work: () throws -> R) rethrows -> R {
        unbalancedLock()
        defer { unbalancedUnlock() }
        return try work()
    }
    
    private var unsafeMutex = pthread_mutex_t()
    
    /// Default constructs as ".Normal" or ".Recursive" on request.
    init() {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }
        pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_NORMAL))
        guard pthread_mutex_init(&unsafeMutex, &attr) == 0 else {
            preconditionFailure()
        }
        pthread_mutexattr_destroy(&attr)
    }
    
    deinit {
        pthread_mutex_destroy(&unsafeMutex)
    }
    
    private func unbalancedLock() {
        pthread_mutex_lock(&unsafeMutex)
    }
    
    private func unbalancedUnlock() {
        pthread_mutex_unlock(&unsafeMutex)
    }
}

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


//MARK: - Operations
/**
 The uniqueness policy dictates whether operations with the same `name` should co-exist in a `BackgroundQueue`. This property is set on new `AsyncOperation`s only.

 When adding an `AsyncOperation` to a `BackgroundQueue`, the queue decides which action to take based on the following criteria:
 * If the **new operation** has the `.replace` policy, any existing operations with the same `name` will be dropped from the queue.
 * If the **new operation** has the `.drop` policy, it itself will be dropped if another operation with the same name exists in the queue.
 * Only the **new operation**'s flag is evaluated when adding an operation to the queue.
 * Only operations that have **not** finished will be evaluated.
 * Only operations that have **not** been canceled will be evaluated.
 * **New operations** that are already executing will not be evaluated.
 * Existing operations that are dropped receive a `cancel()` call.
 * The `.ignore` flag opts out of the uniqueness constraints and lets the **new operation** behave like a regular `Operation` when added to a queue. This is the default behaviour.
 * Both operations need to have a `name` set. If either operations have a `nil` name, `.ignore` is assumed.
 * If multiple operations with the same `name` are being added at the same time, `.ignore` is assumed.

 - note: This functionality will **only** work on `BackgroundQueue`.
 */
@objc
public enum AsyncOperationUniquenessPolicy: Int {
    /**
     Operations with this policy opt out of the uniqueness constraints. This is equivalent to not setting a uniqueness policy, or to adding a regular `Operation` to a queue. This is the default behaviour.
     */
    case ignore
    /**
     `AsyncOperation`s with this policy will replace any existing operations already in the queue.
     */
    case replace
    /**
     `AsyncOperation`s with this policy will be dropped if another opertion with the same `name` already exists in the queue.
     */
    case drop

    /// The default `AsyncOperationUniquenessPolicy`. It is set to `.ignore`.
    public static let `default`: AsyncOperationUniquenessPolicy = .ignore
}

extension AsyncOperationUniquenessPolicy: CustomStringConvertible
{
    public var description: String {
        switch self {
        case .ignore: return "AsyncOperationUniquenessPolicy.ignore"
        case .replace: return "AsyncOperationUniquenessPolicy.replace"
        case .drop: return "AsyncOperationUniquenessPolicy.drop"
        }
    }
}

public typealias AsyncOperationClosure = (_ operation: AsyncOperation) -> Swift.Void


/**
 An `AsyncOperation` is an easy way to perform asynchronous tasks in an `OperationQueue`. It's designed to make it easy to perform long-running tasks on an operation queue regardless of how many times its task needs to jump between threads. Only once everything is done, the `AsyncOperation` is removed from the queue. 
 
 ## Example
 
 ```
 operationQueue.addOperation(AsyncOperation({ (op) in
     //We're on a background thread now; NICE!
     self.loadThingsFromTheInternet(callback: { (result, error) in
         //process the result
         inTheBackground {
             //do more stuff in the background again
             //once everything is done, finish
             op.finish()
             //only now the queue will start working on the next thing
         }
     })
 }))
 ```
 
 Optionally, you can change the operation's default timeout time:
 
 ```
 AsyncOperation(timeout: 60) { (op) in
    //do something that will take less than a minute
 }
 ```
 
 - warning: Be sure to call `op.finish()` once your operation is done, otherwise it will time out. By default, AsyncOperations time out after 10 seconds. This is to avoid blocking any dependencies in the queue.
 
 ## See Also:
 - `BackgroundQueue`
 */
@objc(BLAsyncOperation)
public final class AsyncOperation: Operation
{
    @nonobjc
    private let mutex = PThreadMutex()
    
    @nonobjc
    private var _isExecuting = false
    
    public private(set) override var isExecuting: Bool {
        get {
            return mutex.sync { _isExecuting }
        }
        set {
            let oldValue = isExecuting
            guard oldValue != newValue else { return }
            let keys = ["executing", "isExecuting"]
            willChangeValue(forKeys: keys)
            mutex.sync { _isExecuting = newValue }
            didChangeValue(forKeys: keys)
            if newValue {
                startTimeout()
            }
        }
    }
    
    @nonobjc
    private var _isFinished = false
    
    public private(set) override var isFinished: Bool {
        get {
            return mutex.sync { _isFinished }
        }
        set {
            let oldValue = isFinished
            guard oldValue != newValue else { return }
            let keys = ["finished", "isFinished"]
            willChangeValue(forKeys: keys)
            mutex.sync { _isFinished = newValue }
            didChangeValue(forKeys: keys)
        }
    }
    
    @nonobjc
    private var _isCancelled = false
    
    public private(set) override var isCancelled: Bool {
        get {
            return mutex.sync { _isCancelled }
        }
        set {
            let oldValue = isCancelled
            guard oldValue != newValue else { return }
            let keys = ["cancelled", "isCancelled"]
            willChangeValue(forKeys: keys)
            mutex.sync { _isCancelled = newValue }
            didChangeValue(forKeys: keys)
        }
    }
    
    @nonobjc
    private func willChangeValue(forKeys keys: [String]) {
        keys.forEach { willChangeValue(forKey: $0) }
    }
    
    @nonobjc
    private func didChangeValue(forKeys keys: [String]) {
        keys.forEach { didChangeValue(forKey: $0) }
    }
    
    public override func start() {
        isExecuting = true
        
        guard !isCancelled else {
            finish()
            return
        }
        
        guard let closure = closure else {
            finish()
            return
        }
        
        unowned let weakSelf = self
        closure(weakSelf)
    }
    
    /**
     Call this method when your operation is complete and should be removed from the queue. 
     
     Calling this function sets the `isExecuting` property to `false` and `isFinished` property to `true`.
     */
    @objc
    public func finish() {
        guard !isFinished else { return }
        guard isExecuting else {
            cancel()
            return
        }
        isExecuting = false
        isFinished = true
    }
    
    public override func cancel() {
        closure = nil
        super.cancel()
        isCancelled = true
        if isExecuting {
            finish()
        }
    }
    
    /// The closure to be executed by the operation.
    @nonobjc
    private var _closure: AsyncOperationClosure?
    
    @nonobjc
    private var closure: AsyncOperationClosure? {
        get {
            return mutex.sync { _closure }
        }
        set {
            mutex.sync { _closure = newValue }
        }
    }
    
    /// The timeout interval before the operation is removed from the queue. Defaults to 10.
    let timeout: TimeInterval

    /**
     Callback to be executed when this operation times out.

     - parameters:
        - operation: The `AsyncOperation` that has timed out.

     - note: The callback is executed on `OperationQueue.background`.
     */
    @nonobjc
    fileprivate let onTimeoutCallback: AsyncOperationClosure?

    /**
     The uniqueness policy to be applied when adding this operation to a queue.

     ## See Also:
     - `AsyncOperationUniquenessPolicy`
     */
    let uniquenessPolicy: AsyncOperationUniquenessPolicy
    
    /**
     Designated initialiser for a new `AsyncOperation`.
     
     - parameters:
        - name: The name of the operation. Useful for debugging. Defaults to `nil`.
        - timeout: The time in seconds after which this operation should be marked as finished and removed from the queue. Defaults to 10.
        - onTimeoutCallback: The callback to be executed when this operation times out. The callback is executed on `OperationQueue.background`.
        - uniquenessPolicy: The uniqueness policy to be applied to this operation when adding it to a `BackgroundQueue`.
        - closure: The closure to be executed by the operation. The closure takes a `AsyncOperation` parameter. Call `finish()` on the object passed here.
     
     - note:
        As per [Apple's documentation](https://developer.apple.com/documentation/foundation/operation/1408418-iscancelled), it's always a good idea to check if your operation has been cancelled during the execution of its closure and shortcircuit it prematurely if needed.

     ## See Also:
     - `AsyncOperationUniquenessPolicy`
     */
    @objc(withName:timeout:onTimeoutBlock:uniquenessPolicys:andBlock:)
    public required init(name: String? = nil,
                         timeout: TimeInterval = 10,
                         onTimeoutCallback: AsyncOperationClosure? = nil,
                         uniquenessPolicy: AsyncOperationUniquenessPolicy = .default,
                         _ closure: @escaping AsyncOperationClosure)
    {
        self._closure = closure
        self.timeout = timeout
        self.onTimeoutCallback = onTimeoutCallback
        self.uniquenessPolicy = uniquenessPolicy
        super.init()
        self.name = name
    }

    deinit {
        timer = nil
    }

    @nonobjc
    private weak var timer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    /**
     If an operation never calls its `finish()` method, this will cancel it.
     */
    @nonobjc
    private func startTimeout() {
        let description = self.debugDescription
        let timeout = self.timeout
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: timeout,
                                               repeats: false)
            {
                guard $0.isValid else { return }
                guard let self = self else { $0.invalidate(); return }
                self.timer = nil
                guard self.isFinished == false else { return }
                #if DEBUG
                print("Async Operation did time out: \(description)")
                #endif
                self.finish()
                if let callback = self.onTimeoutCallback {
                    let strongSelf = self
                    OperationQueue.background.addOperation {
                        callback(strongSelf)
                    }
                }
            }
        }
    }

    public override var debugDescription: String {
        return """
        \(String(describing: self)) - name: \(name ?? "NO NAME") - Timeout: \(timeout) - Uniqueness Policy: \(uniquenessPolicy) - isExecuting: \(isExecuting) - isFinished: \(isFinished) - isCancelled: \(isCancelled) - isReady: \(isReady)
        """
    }
}


#if !AF_APP_EXTENSIONS && (os(iOS) || os(tvOS))
import UIKit

private typealias BackgroundTaskIdentifier = UIBackgroundTaskIdentifier
#if swift(>=4.2)
private let BackgroundTaskInvalid = UIBackgroundTaskIdentifier.invalid
#else
private let BackgroundTaskInvalid = UIBackgroundTaskInvalid
#endif

private func beginBackgroundTask(handler: (() -> Swift.Void)? = nil) -> BackgroundTaskIdentifier {
    return UIApplication.shared.beginBackgroundTask(expirationHandler: handler)
}

private func finishBackgroundTask(identifier: UIBackgroundTaskIdentifier) {
    UIApplication.shared.endBackgroundTask(identifier)
}
#else
private typealias BackgroundTaskIdentifier = Int
private let BackgroundTaskInvalid = -1

private func beginBackgroundTask(handler: (() -> Swift.Void)? = nil) -> BackgroundTaskIdentifier {
    return 0
}

private func finishBackgroundTask(identifier: BackgroundTaskIdentifier) {
    //Noop
}
#endif


//MARK: - Operation Queue
private var backgroundQueueContext = 0

/**
 The `BackgroundQueueDelegate` receive reports from its `BackgroundQueue` of events happening with the queue.
 */
@objc
public protocol BackgroundQueueDelegate: AnyObject {
    /**
     Called when the `BackgroundQueue` will start executing operations.
     
     - parameters:
        - queue: The underlying `BackgroundQueue` who's about to start processing operations.
     
     - warning: This method is called in `DispatchQueue.global()`.
     */
    func backgroundQueueWillStartOperations(_ queue: BackgroundQueue)
    /**
     Called when the `BackgroundQueue` has become empty.
     
     - parameters:
         - queue: The underlying `BackgroundQueue` whose operations have finished.
     
     - warning: This method is called in `DispatchQueue.global()`.
     */
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
}

/**
 The `BackgroundQueue` class is a concrete subclass of the `OperationQueue` that automatically handles background task identifiers. Whenever an operation is enqueued, a background task identifier is generated and whenever the queue is empty, the queue automatically invalidates it.
 
 - note: These operations are guaranteed to be executed one after the other.
 */
@objc(BLBackgroundQueue)
public final class BackgroundQueue: OperationQueue
{
    @nonobjc
    private let mutex = PThreadMutex()
    
    @nonobjc
    private var _backgroundTaskId: BackgroundTaskIdentifier = BackgroundTaskInvalid
    
    @nonobjc
    private var backgroundTaskId: BackgroundTaskIdentifier {
        get {
            return mutex.sync { _backgroundTaskId }
        }
        set {
            mutex.sync { _backgroundTaskId = newValue }
        }
    }
    
    /**
     The BackgroundQueue's delegate.
     
     ## See Also:
     `BackgroundQueueDelegate`
     */
    @objc
    public weak var delegate: BackgroundQueueDelegate?
    
    @nonobjc
    private func startBackgroundTask() {
        guard backgroundTaskId == BackgroundTaskInvalid else { return }
        
        backgroundTaskId = beginBackgroundTask(handler: { [weak self] in
            inTheGlobalQueue {
                self?.endBackgroundTask()
            }
        })
    }
    
    @nonobjc
    private func endBackgroundTask() {
        let bgTaskId = backgroundTaskId
        guard bgTaskId != BackgroundTaskInvalid else { return }
        finishBackgroundTask(identifier: bgTaskId)
        backgroundTaskId = BackgroundTaskInvalid
    }
    
    deinit {
        removeObserver(self,
                       forKeyPath: #keyPath(OperationQueue.operationCount))
    }
    
    public override init() {
        super.init()
        
        self.name = "com.bellapplab.BackgroundQueue"
        self.qualityOfService = .background
        
        inTheGlobalQueue { [unowned self] in
            self.addObserver(self,
                             forKeyPath: #keyPath(OperationQueue.operationCount),
                             options: [.old, .new],
                             context: &backgroundQueueContext)
        }
    }

    public override func addOperation(_ op: Operation) {
        addOperations([op],
                      waitUntilFinished: false)
    }

    public override func addOperations(_ ops: [Operation],
                                       waitUntilFinished wait: Bool)
    {
        ops
            .forEach { newOp in
                operations(name: newOp.name)
                    .compactMap { newOp.operationToCancel($0) }
                    .forEach {
                        guard $0.isCancelled == false else { return }
                        $0.cancel()
                    }
            }

        let opsToAdd = ops
            .compactMap { newOp -> Operation? in
                let existingOps = operations(name: newOp.name)
                guard existingOps.isEmpty == false else { return newOp }
                return existingOps.compactMap { newOp.operationToAdd($0) }.first
            }

        super.addOperations(opsToAdd,
                            waitUntilFinished: wait)
    }
    
    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?)
    {
        guard context == &backgroundQueueContext, (object as? BackgroundQueue) === self else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        switch (change?[.oldKey], change?[.newKey]) {
        case (let oldValue as Int, let newValue as Int) where oldValue == 0 && newValue > 0:
            inTheGlobalQueue { [weak self] in
                self?.reportToDelegate(isStarting: true)
                self?.startBackgroundTask()
            }
        case (let oldValue as Int, let newValue as Int) where oldValue > 0 && newValue == 0:
            inTheGlobalQueue { [weak self] in
                self?.reportToDelegate(isStarting: false)
                self?.endBackgroundTask()
            }
        default:
            break
        }
    }
    
    @nonobjc
    private func reportToDelegate(isStarting: Bool) {
        guard let delegate = delegate else { return }
        if isStarting {
            delegate.backgroundQueueWillStartOperations(self)
        } else {
            delegate.backgroundQueueDidFinishOperations(self)
        }
    }

    @nonobjc
    private var suspensionCount: Int = 0

    public override var isSuspended: Bool {
        get {
            return mutex.sync { super.isSuspended }
        }
        set {
            mutex.sync {
                let oldCount = suspensionCount
                let increment = newValue ? 1 : -1
                suspensionCount += increment
                if suspensionCount < 0 { suspensionCount = 0 }
                guard oldCount != suspensionCount else { return }
                super.isSuspended = suspensionCount > 0
            }
        }
    }
}

private extension BackgroundQueue
{
    func operations(name: String?) -> [Operation] {
        guard let name = name else { return operations }
        return operations.filter { $0.name == name }
    }
}
