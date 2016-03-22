//
//  Backgroundable.swift
//  Project
//
//  Created by Bell App Lab on 05/08/15.
//  Copyright (c) 2015 Bell App Lab. All rights reserved.
//

import UIKit


//MARK: - Main
//MARK: App States

@objc public protocol AppStatesHandler: AnyObject, NSObjectProtocol
{
    func handleAppStateChange(toBackground: Bool)
    @objc func handleAppState(notification: NSNotification)
}

public extension AppStatesHandler
{
    final public func becomeAppStatesHandler() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(AppStatesHandler.handleAppState(_:)), name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: #selector(AppStatesHandler.handleAppState(_:)), name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
    
    final public func resignAppStatesHandler() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
}

extension NSObject: AppStatesHandler
{
    @objc final public func handleAppState(notification: NSNotification) {
        if notification.name == UIApplicationWillResignActiveNotification {
            self.handleAppStateChange(true)
        } else if notification.name == UIApplicationDidBecomeActiveNotification {
            self.handleAppStateChange(false)
        }
    }
    
    public func handleAppStateChange(toBackground: Bool) {
        
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
    @nonobjc private static var id = UIBackgroundTaskInvalid
    
    public private(set) static var active: Bool  = false {
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
        self.id = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            if self.active {
                self.startBackgroundTask()
            }
        }
    }
    
    private static func endBackgroundTask() {
        if self.id == UIBackgroundTaskInvalid {
            return
        }
        UIApplication.sharedApplication().endBackgroundTask(self.id)
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
    
    private static var concurrentQueue: NSOperationQueue!
    private static var operationCount = 0
    
    private static func enqueue(operations: [NSOperation])
    {
        if operations.isEmpty {
            return
        }
        
        if Background.concurrentQueue == nil {
            let queue = NSOperationQueue()
            queue.name = "BackgroundableQueue"
            Background.concurrentQueue = queue
        }
        Background.operationCount += 1
        
        startBackgroundTask()
        
        for (index, item) in operations.enumerate() {
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

public func inTheBackground(x: () -> Void)
{
    Background.enqueue([NSBlockOperation(block: x)])
}

public func onTheMainThread(x: () -> Void)
{
    dispatch_async(dispatch_get_main_queue()) {
        x()
    }
}
