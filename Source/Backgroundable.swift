import UIKit


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
final class AsyncOperation: Operation
{
    override var isExecuting: Bool {
        return self.isWorking
    }
    
    override var isFinished: Bool {
        return self.isDone
    }
    
    /**
     Custom flag used to emit KVO notifications regarding the `isExecuting` property.
     */
    public private(set) var isWorking: Bool = false
    private var _isWorking: Bool = false
    
    /**
     Custom flag used to emit KVO notifications regarding the `isFinished` property.
     */
    public private(set) var isDone: Bool = false
    private var _isDone: Bool = false
    
    private func set(isWorking: Bool? = nil,
                     isDone: Bool? = nil)
    {
        var didChangeFinished: Bool = false
        if let isDone = isDone {
            if self._isDone != isDone {
                self.willChangeValue(forKey: "isFinished")
                didChangeFinished = true
            }
            self._isDone = isDone
        }
        
        var didChangeExecution: Bool = false
        if let isWorking = isWorking {
            if self._isWorking != isWorking {
                self.willChangeValue(forKey: "isExecuting")
                didChangeExecution = true
            }
            self._isWorking = isWorking
        }
        
        self.isDone = self._isDone
        self.isWorking = self._isWorking
        
        if didChangeFinished {
            self.didChangeValue(forKey: "isFinished")
        }
        if didChangeExecution {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    override func start() {
        guard !self.isCancelled else { return }
        
        self.set(isWorking: true)
        
        /**
         If an operation never calls its `finish()` method, a Timer will fire and execute this method.
         */
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if #available(iOS 10.0, *) {
                Timer.scheduledTimer(withTimeInterval: strongSelf.timeout,
                                     repeats: false)
                { (timer) in
                    defer { timer.invalidate() }
                    strongSelf.cancel()
                }
            } else {
                Timer.scheduledTimer(timeInterval: strongSelf.timeout,
                                     target: strongSelf,
                                     selector: #selector(strongSelf.handleTimeoutTimer(_:)),
                                     userInfo: nil,
                                     repeats: false)
            }
        }
        
        unowned let weakSelf = self
        self.closure(weakSelf)
    }
    
    /**
     Call this method when your operation is complete and should be removed from the queue. 
     
     Calling this function sets the `isExecuting` property to `false` and `isFinished` property to `true`.
     */
    func finish() {
        self.set(isWorking: false,
                 isDone: true)
    }
    
    override func cancel() {
        guard !self.isFinished else { return }
        super.cancel()
        self.set(isWorking: false)
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
    required init(timeout: TimeInterval = 10,
                  _ closure: @escaping (_ operation: AsyncOperation) -> Void)
    {
        self.closure = closure
        self.timeout = timeout
        super.init()
    }
}

extension AsyncOperation
{
    @objc func handleTimeoutTimer(_ timer: Timer) {
        defer { timer.invalidate() }
        self.cancel()
    }
}

//MARK: Operation Queue
private var backgroundQueueContext = 0

protocol BackgroundQueueDelegate: class {
    func backgroundQueueDidFinishOperations(_ queue: BackgroundQueue)
}

/**
 The `BackgroundQueue` class is a concrete subclass of the `OperationQueue` that automatically handles background task identifiers. Whenever an operation is enqueued, a background task identifier is generated and whenever the queue is empty, the queue automatically invalidates it.
 
 - note: These operations are guaranteed to be executed one after the other.
 */
final class BackgroundQueue: OperationQueue
{
    private var backgroundTaskId = UIBackgroundTaskInvalid
    
    weak var delegate: BackgroundQueueDelegate?
    
    private func startBackgroundTask() {
        guard self.backgroundTaskId == UIBackgroundTaskInvalid else { return }
        
        self.backgroundTaskId = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        guard self.backgroundTaskId != UIBackgroundTaskInvalid else { return }
        
        //If iOS invalidates background tasks (because the we ran out of background time), we should cancel all existing operations here
        if self.operationCount > 0 {
            self.cancelAllOperations()
        }
        
        UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
        self.backgroundTaskId = UIBackgroundTaskInvalid
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
                    self.endBackgroundTask()
                    self.reportFinishToDelegate()
                }
            }
            return
        }
        
        super.observeValue(forKeyPath: keyPath,
                           of: object,
                           change: change,
                           context: context)
    }
    
    private func reportFinishToDelegate() {
        guard let delegate = self.delegate else { return }
        onTheMainThread { [weak self] in
            guard let strongSelf = self else { return }
            delegate.backgroundQueueDidFinishOperations(strongSelf)
        }
    }
}


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
