import UIKit


//
//  CwlMutex.swift
//  CwlUtils
//
//  Created by Matt Gallagher on 2015/02/03.
//  Copyright © 2015 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

fileprivate final class PThreadMutex {
    func sync<R>(execute work: () throws -> R) rethrows -> R {
        unbalancedLock()
        defer { unbalancedUnlock() }
        return try work()
    }
    func trySync<R>(execute work: () throws -> R) rethrows -> R? {
        guard unbalancedTryLock() else { return nil }
        defer { unbalancedUnlock() }
        return try work()
    }
    
    typealias MutexPrimitive = pthread_mutex_t
    
    // Non-recursive "PTHREAD_MUTEX_NORMAL" and recursive "PTHREAD_MUTEX_RECURSIVE" mutex types.
    enum PThreadMutexType {
        case normal
        case recursive
    }
    
    var unsafeMutex = pthread_mutex_t()
    
    /// Default constructs as ".Normal" or ".Recursive" on request.
    init(type: PThreadMutexType = .normal) {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }
        switch type {
        case .normal:
            pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_NORMAL))
        case .recursive:
            pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
        }
        guard pthread_mutex_init(&unsafeMutex, &attr) == 0 else {
            preconditionFailure()
        }
        pthread_mutexattr_destroy(&attr)
    }
    
    deinit {
        pthread_mutex_destroy(&unsafeMutex)
    }
    
    func unbalancedLock() {
        pthread_mutex_lock(&unsafeMutex)
    }
    
    func unbalancedTryLock() -> Bool {
        return pthread_mutex_trylock(&unsafeMutex) == 0
    }
    
    func unbalancedUnlock() {
        pthread_mutex_unlock(&unsafeMutex)
    }
}


//MARK: - App States
/**
 The AppStatesHandler protocol defines an interface for objects that want to receive `UIApplicationWillResignActive` and `UIApplicationDidBecomeActive` notifications.
 
 - note: If implementing this protocol yourself, make sure to call `becomeAppStatesHandler()` and `resignAppStatesHandler()` to start and stop receiving notifications.
 */
protocol AppStatesHandler: class
{
    /**
     This is the main point of interaction this protocol provides. Implementing this method gives objects the hability to perform actions when the app is going to the background and coming from it.
     
     - note: In order to start receiving calls to this method you need to call `becomeAppStatesHandler()`. 
     - warning: Be sure to call `resignAppStatesHandler()` once you're done.
     - parameters:
        - toBackground: lets its host object know if the app is moving to the background or coming from it
     */
    func handleAppStateChange(_ toBackground: Bool)
    
    /**
     The appStateNotifications array stores the `NSObjectProtocol` notifications that allow an AppStatesHandler to act whenever the shared application moves to and from the background. 
     
     - note: You should not need to interact with this property.
     */
    var appStateNotifications: [NSObjectProtocol] { get set }
}

extension AppStatesHandler
{
    /**
     Call this method to start receiving app state notifications.
     
     ## See Also:
     - `handleAppStateChange(_:)`
     */
    func becomeAppStatesHandler() {
        guard self.appStateNotifications.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        
        self.appStateNotifications.append(notificationCenter.addObserver(forName: .UIApplicationWillResignActive,
                                                                         object: UIApplication.shared,
                                                                         queue: OperationQueue.main)
        { [weak self] (notification) in
            self?.handleAppStateChange(true)
        })
        
        self.appStateNotifications.append(notificationCenter.addObserver(forName: .UIApplicationDidBecomeActive,
                                                                         object: UIApplication.shared,
                                                                         queue: OperationQueue.main)
        { [weak self] (notification) in
            self?.handleAppStateChange(false)
        })
    }
    
    /**
     Call this method to stop receiving app state notifications.
     
     ## See Also:
     - `handleAppStateChange(_:)`
     */
    func resignAppStatesHandler() {
        guard !self.appStateNotifications.isEmpty else { return }
        
        let notificationCenter = NotificationCenter.default
        
        self.appStateNotifications.forEach {
            notificationCenter.removeObserver($0)
        }

        self.appStateNotifications = []
    }
}

//MARK: - Visibility
/**
 The Visibility protocol defines an interface for objects to know if they are currently visible depending on the current state of the application. When your app moves to and from the background, `willChangeVisibility()` and `didChangeVisibility()` will be called and the `isVisible` will be set accordingly.
 */
protocol Visibility: AppStatesHandler
{
    /**
     Informs callers if the app is currently in the foreground or not.
     */
    var isVisible: Bool { get set }
    /**
     Called immediately before changing visibility.
     
     - note: When this method is called, `isVisible` will not have been set to the its new state. Therefore, if the app is in the foreground and moving to the background, `isVisible` will be set to `true` at this point.
     */
    func willChangeVisibility()
    /**
     Called after the visibility transition has finished.
     
     - note: When this method is called, `isVisible` will already have been set to the its new state. Therefore, if the app is in the foreground and moving to the background, `isVisible` will be set to `false` at this point.
     */
    func didChangeVisibility()
}

extension Visibility
{
    /**
     Default implementation for the `AppStatesHandler` protocol.
     
     ## See Also:
     - `AppStatesHandler.handleAppStateChange(_:)`
     */
    func handleAppStateChange(_ toBackground: Bool) {
        if self.isVisible && toBackground || !self.isVisible && !toBackground {
            self.willChangeVisibility()
            self.isVisible = !toBackground
            self.didChangeVisibility()
        }
    }
}


//MARK: - Operations
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
@objc
final class AsyncOperation: Operation
{
    static let defaultTimeout: TimeInterval = 10
    
    private struct State {
        let isExecuting: Bool
        let isFinished: Bool
        let isCancelled: Bool
        
        init(isExecuting: Bool = false,
             isFinished: Bool = false,
             isCancelled: Bool = false)
        {
            var isExecuting = isExecuting
            var isFinished = isFinished
            var isCancelled = isCancelled
            
            if isCancelled {
                isFinished = true
                isExecuting = false
            } else if isFinished {
                isCancelled = false
                isExecuting = false
            } else if isExecuting {
                isCancelled = false
                isFinished = false
            }
            
            self.isExecuting = isExecuting
            self.isFinished = isFinished
            self.isCancelled = isCancelled
        }
        
        func changedKeys(otherState: State) -> [String]
        {
            var keys = [String]()
            
            if self.isExecuting != otherState.isExecuting {
                keys.append("isExecuting")
            }
            
            if self.isFinished != otherState.isFinished {
                keys.append("isFinished")
            }
            
            if self.isCancelled != otherState.isCancelled {
                keys.append("isCancelled")
            }
            
            return keys
        }
    }
    
    override var isExecuting: Bool {
        return self.getState().isExecuting
    }
    
    override var isFinished: Bool {
        return self.getState().isFinished
    }
    
    override var isCancelled: Bool {
        return self.getState().isCancelled
    }
    
    /**
     Custom flag used to emit KVO notifications regarding the `isExecuting` property.
     */
    private var _state = PThreadMutex().sync { State() }
    private func getState() -> State {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return self._state
    }
    private func set(state newValue: State) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let oldValue = self._state
        let strongSelf = self
        
        let keys = oldValue.changedKeys(otherState: newValue)
        keys.forEach {
            strongSelf.willChangeValue(forKey: $0)
        }
        self._state = newValue
        keys.forEach {
            strongSelf.didChangeValue(forKey: $0)
        }
    }
    
    override func start() {
        guard !self.isCancelled else { return }
        
        self.set(state: State(isExecuting: true))
        
        self.startTimeout()
        
        unowned let weakSelf = self
        self.closure(weakSelf)
    }
    
    /**
     Call this method when your operation is complete and should be removed from the queue. 
     
     Calling this function sets the `isExecuting` property to `false` and `isFinished` property to `true`.
     */
    func finish() {
        guard self.isCancelled == false else { return }
        self.set(state: State(isFinished: true))
    }
    
    override func cancel() {
        guard self.isFinished == false else { return }
        self.set(state: State(isCancelled: true))
    }
    
    /// The closure to be executed by the operation.
    private let closure: (_ operation: AsyncOperation) -> Void
    /// The timeout interval before the operation is removed from the queue.
    private let timeout: TimeInterval
    
    /**
     Designated initialiser for a new `AsyncOperation`.
     
     - parameters:
        - timeout: The time in seconds after which this operation should be marked as finished and removed from the queue. 
        - closure: The closure to be executed by the operation. The closure takes a `AsyncOperation` parameter. Call `finish()` on the object passed here.
     */
    @nonobjc
    required init(timeout: TimeInterval = AsyncOperation.defaultTimeout,
                  _ closure: @escaping (_ operation: AsyncOperation) -> Void)
    {
        self.closure = closure
        self.timeout = timeout >= 0.0 ? timeout : AsyncOperation.defaultTimeout
        super.init()
    }
    
    @objc
    convenience init(timeout: TimeInterval,
                     andBlock closure: @escaping (_ operation: AsyncOperation) -> Void)
    {
        self.init(timeout: timeout,
                  closure)
    }
}

@nonobjc
fileprivate extension AsyncOperation
{
    /**
     If an operation never calls its `finish()` method, this will cancel it.
     */
    func startTimeout() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + self.timeout) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.cancel()
        }
    }
}

//MARK: Operation Queue
private var backgroundQueueContext = 0

/**
 The `BackgroundQueueDelegate` receive reports from its `BackgroundQueue` of events happening with the queue.
 */
protocol BackgroundQueueDelegate: class {
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
@objc
final class BackgroundQueue: OperationQueue
{
    private var backgroundTaskId = UIBackgroundTaskInvalid
    
    /**
     The BackgroundQueue's delegate.
     
     ## See Also:
     `BackgroundQueueDelegate`
     */
    weak var delegate: BackgroundQueueDelegate?
    
    private func startBackgroundTask() {
        PThreadMutex().sync { [weak self] () -> Void in
            guard self?.backgroundTaskId == UIBackgroundTaskInvalid else { return }
            
            self?.backgroundTaskId = UIApplication.shared.beginBackgroundTask {
                self?.endBackgroundTask()
            }
        }
    }
    
    private func endBackgroundTask() {
        PThreadMutex().sync { [weak self] () -> Void in
            guard let backgroundTaskId = self?.backgroundTaskId, backgroundTaskId != UIBackgroundTaskInvalid else { return }
            
            //If iOS invalidates background tasks (because the we ran out of background time), we should cancel all existing operations here
            if self?.operationCount ?? 0 > 0 {
                self?.cancelAllOperations()
            }
            
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            self?.backgroundTaskId = UIBackgroundTaskInvalid
        }
    }
    
    deinit {
        self.removeObserver(self,
                            forKeyPath: #keyPath(OperationQueue.operationCount))
    }
    
    override init() {
        super.init()
        self.name = "com.bellapplab.BackgroundQueue"
        self.qualityOfService = .background
        
        self.addObserver(self,
                         forKeyPath: #keyPath(OperationQueue.operationCount),
                         options: .new,
                         context: &backgroundQueueContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?)
    {
        if context == &backgroundQueueContext, (object as? BackgroundQueue) === self {
            if let new = change?[.newKey] as? Int {
                if new > 0 {
                    self.startBackgroundTask()
                } else if new == 0 {
                    self.reportFinishToDelegate { [weak self] in
                        self?.endBackgroundTask()
                    }
                }
            }
            return
        }
        
        super.observeValue(forKeyPath: keyPath,
                           of: object,
                           change: change,
                           context: context)
    }
    
    private func reportFinishToDelegate(_ completion: @escaping () -> Void) {
        guard let delegate = self.delegate else { completion(); return }
        inTheGlobalQueue { [weak self] in
            defer { completion() }
            guard let strongSelf = self else { return }
            delegate.backgroundQueueDidFinishOperations(strongSelf)
        }
    }
}


@objc
extension OperationQueue
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
    func addSequentialOperations(_ ops: [Operation],
                                 waitUntilFinished wait: Bool)
    {
        if ops.count > 1 {
            for i in 1..<ops.count {
                ops[i].addDependency(ops[i - 1])
            }
        }
        
        self.addOperations(ops,
                           waitUntilFinished: wait)
    }
}


//MARK: - Functions
/**
 The easiest way to execute code in the background. 
 
 - parameters:
    - closure: The closure to be executed in the background.
 */
public func inTheBackground(_ closure: @escaping () -> Void)
{
    OperationQueue.background.addOperation(closure)
}

/**
 The easiest way to excute code on the main thread.
 
 - parameters:
    - closure: The closure to be executed on the main thread.
 */
public func onTheMainThread(_ closure: @escaping () -> Void)
{
    OperationQueue.main.addOperation(closure)
}

/**
 The easiest way to excute code in the global background queue.
 
 - parameters:
    - closure: The closure to be executed in the global background queue.
 */
public func inTheGlobalQueue(_ closure: @escaping () -> Void)
{
    DispatchQueue.global(qos: .background).async(execute: closure)
}
