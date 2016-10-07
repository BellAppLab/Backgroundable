import UIKit


//MARK: - Main
//MARK: App States
/**
 The AppStatesHandler protocol defines an interface for objects that want to receive `UIApplicationWillResignActive` and `UIApplicationDidBecomeActive` notifications.
 
 - note If implementing this protocol yourself, make sure to call `becomeAppStatesHandler()` and `resignAppStatesHandler()` to start and stop receiving notifications.
 */
@objc protocol AppStatesHandler: AnyObject, NSObjectProtocol
{
    /**
     This is the main point of interaction this protocol provides. Implementing this method gives objects the hability to perform actions when the app is going to the background and coming from it.
     
     - param    toBackground    lets its host object know if the app is moving to the background or coming from it
     */
    func handleAppStateChange(_ toBackground: Bool)
    /**
     This method is called by `NSNotificationCenter` to let the object know the app is changing states. 
     
     - note You shouldn't need to implement this method, nor override it.
     */
    @objc func handleAppState(_ notification: Notification)
}

extension AppStatesHandler
{
    final func becomeAppStatesHandler() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AppStatesHandler.handleAppState(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: UIApplication.shared)
        notificationCenter.addObserver(self, selector: #selector(AppStatesHandler.handleAppState(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
    }
    
    final func resignAppStatesHandler() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: UIApplication.shared)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
    }
}

extension NSObject: AppStatesHandler
{
    @objc final func handleAppState(_ notification: Notification) {
        if notification.name == NSNotification.Name.UIApplicationWillResignActive {
            self.handleAppStateChange(true)
        } else if notification.name == NSNotification.Name.UIApplicationDidBecomeActive {
            self.handleAppStateChange(false)
        }
    }
    
    func handleAppStateChange(_ toBackground: Bool) {
        
    }
}

//MARK: Visibility
/**
 THe Visibility protocol defines an interface for objects to know if they are currently visible depending on the current state of the application. When your app moves to and from the background, `willChangeVisibility()` and `didChangeVisibility()` will be called and the `isVisible` will be set accordingly.
 */
protocol Visibility: AppStatesHandler
{
    /**
     Informs callers if the app is currently in the foreground or not.
     */
    var isVisible: Bool { get set }
    /**
     Called immediately before changing visibility.
     
     - note When this method is called, `isVisible` will not have been set to the its new state. Therefore, if the app is in the foreground and moving to the background, `isVisible` will be set to `true` at this point.
     */
    func willChangeVisibility()
    /**
     Called after the visibility transition has finished.
     
     - note When this method is called, `isVisible` will already have been set to the its new state. Therefore, if the app is in the foreground and moving to the background, `isVisible` will be set to `false` at this point.
     */
    func didChangeVisibility()
}


//MARK: - Functions
//MARK: Background Task IDs

private struct BackgroundTask {
    @nonobjc fileprivate static var id = UIBackgroundTaskInvalid
    
    fileprivate static var active: Bool  = false {
        didSet {
            if oldValue != active {
                if active {
                    self.startBackgroundTask()
                } else {
                    self.endBackgroundTask()
                }
            }
        }
    }
    
    private static func startBackgroundTask() {
        self.endBackgroundTask()
        self.id = UIApplication.shared.beginBackgroundTask (expirationHandler: { () -> Void in
            if self.active {
                self.startBackgroundTask()
            }
        })
    }
    
    private static func endBackgroundTask() {
        if self.id == UIBackgroundTaskInvalid {
            return
        }
        UIApplication.shared.endBackgroundTask(self.id)
        self.id = UIBackgroundTaskInvalid
    }
}

private func startBackgroundTask() {
    BackgroundTask.active = true
}

private func endBackgroundTask() {
    BackgroundTask.active = false
}

//MARK: Dispatching
/**
 Defines a set of states regarding the execution of code in the background.
 */
struct Background {
    /**
     When set to `true`, the underlying `OperationQueue` will be set to `nil` after all operations have been completed and a new one will be created when needed. The default value is `false`.
     
     - note It's recommended to set this to true only if background operations are sporadic within the context of your app. If you constantly send code to be executed in the background, set this option to `false`.
     */
    static var cleanAfterDone = false {
        didSet {
            if cleanAfterDone {
                if Background.operationCount == 0 {
                    Background.concurrentQueue = nil
                }
            }
        }
    }
    
    private static var concurrentQueue: OperationQueue!
    private static var operationCount = 0
    
    /**
     Enqueues several `Operation` objects to be executed in the background.
     
     - param    operations  An array of `Operation` objects to be executed.
     */
    static func enqueue(_ operations: [Operation])
    {
        if operations.isEmpty {
            return
        }
        
        if Background.concurrentQueue == nil {
            let queue = OperationQueue()
            queue.name = "BackgroundableQueue"
            Background.concurrentQueue = queue
        }
        Background.operationCount += 1
        
        startBackgroundTask()
        
        for (index, item) in operations.enumerated() {
            if index + 1 < operations.count {
                item.addDependency(operations[index + 1])
            }
        }
        
        let last = operations.last!
        let completionBlock = last.completionBlock
        last.completionBlock = { () -> Void in
            if let block = completionBlock {
                onTheMainThread(block)
            }
            
            if Background.concurrentQueue != nil {
                Background.operationCount -= 1
                if Background.operationCount < 0 {
                    Background.operationCount = 0
                }
                if Background.operationCount == 0 && Background.cleanAfterDone {
                    Background.concurrentQueue = nil
                }
            }
            
            endBackgroundTask()
        }
        
        Background.concurrentQueue.addOperations(operations, waitUntilFinished: false)
    }
}

/**
 The easiest way to execute code in the background. 
 
 - param    x   The closure to be executed in the background.
 */
public func inTheBackground(_ x: @escaping () -> Void)
{
    Background.enqueue([BlockOperation(block: x)])
}

/**
 The easiest way to come back to the main thread.
 
 - param    x   The closure to be executed on the main thread.
 */
public func onTheMainThread(_ x: @escaping () -> Void)
{
    DispatchQueue.main.async {
        x()
    }
}
