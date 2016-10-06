import UIKit


//MARK: - Main
//MARK: App States

@objc public protocol AppStatesHandler: AnyObject, NSObjectProtocol
{
    func handleAppStateChange(_ toBackground: Bool)
    @objc func handleAppState(_ notification: Notification)
}

public extension AppStatesHandler
{
    final public func becomeAppStatesHandler() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AppStatesHandler.handleAppState(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: UIApplication.shared)
        notificationCenter.addObserver(self, selector: #selector(AppStatesHandler.handleAppState(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
    }
    
    final public func resignAppStatesHandler() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: UIApplication.shared)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: UIApplication.shared)
    }
}

extension NSObject: AppStatesHandler
{
    @objc final public func handleAppState(_ notification: Notification) {
        if notification.name == NSNotification.Name.UIApplicationWillResignActive {
            self.handleAppStateChange(true)
        } else if notification.name == NSNotification.Name.UIApplicationDidBecomeActive {
            self.handleAppStateChange(false)
        }
    }
    
    public func handleAppStateChange(_ toBackground: Bool) {
        
    }
}

//MARK: Visibility

public protocol Visibility: AppStatesHandler
{
    var visible: Bool { get set }
    func willChangeVisibility()
    func didChangeVisibility()
}


//MARK: - Functions
//MARK: Background Task IDs

public struct BackgroundTask {
    @nonobjc fileprivate static var id = UIBackgroundTaskInvalid
    
    public fileprivate(set) static var active: Bool  = false {
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
    
    fileprivate static func startBackgroundTask() {
        self.endBackgroundTask()
        self.id = UIApplication.shared.beginBackgroundTask (expirationHandler: { () -> Void in
            if self.active {
                self.startBackgroundTask()
            }
        })
    }
    
    fileprivate static func endBackgroundTask() {
        if self.id == UIBackgroundTaskInvalid {
            return
        }
        UIApplication.shared.endBackgroundTask(self.id)
        self.id = UIBackgroundTaskInvalid
    }
}

public func startBackgroundTask() {
    BackgroundTask.active = true
}

public func endBackgroundTask() {
    BackgroundTask.active = false
}

//MARK: Dispatching

public struct Background {
    public static var cleanAfterDone = false {
        didSet {
            if cleanAfterDone {
                if Background.operationCount == 0 {
                    Background.concurrentQueue = nil
                }
            }
        }
    }
    
    fileprivate static var concurrentQueue: OperationQueue!
    fileprivate static var operationCount = 0
    
    fileprivate static func enqueue(_ operations: [Operation])
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

public func inTheBackground(_ x: @escaping () -> Void)
{
    Background.enqueue([BlockOperation(block: x)])
}

public func onTheMainThread(_ x: @escaping () -> Void)
{
    DispatchQueue.main.async {
        x()
    }
}
