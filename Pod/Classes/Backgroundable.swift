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

extension NSObject: AppStatesHandler
{
    final public func becomeAppStatesHandler() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleAppState:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: "handleAppState:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }
    
    final public func resignAppStatesHandler() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }
    
    @objc final public func handleAppState(notification: NSNotification) {
        if notification.name == UIApplicationWillResignActiveNotification {
            self.handleAppStateChange(true)
        } else if notification.name == UIApplicationWillEnterForegroundNotification {
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

private var bgTaskId = UIBackgroundTaskInvalid

public func startBackgroundTask() {
    var currentTaskId = bgTaskId
    bgTaskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
        startBackgroundTask()
    }
    if currentTaskId != UIBackgroundTaskInvalid {
        UIApplication.sharedApplication().endBackgroundTask(currentTaskId)
        currentTaskId = UIBackgroundTaskInvalid
    }
}

public func endBackgroundTask() {
    if bgTaskId == UIBackgroundTaskInvalid {
        return
    }
    UIApplication.sharedApplication().endBackgroundTask(bgTaskId)
    bgTaskId = UIBackgroundTaskInvalid
}

//MARK: Dispatching

private var concurrentQueue: (queue: NSOperationQueue, count: Int)!

public func enqueue(operations: [NSOperation])
{
    if operations.isEmpty {
        return
    }
    
    if concurrentQueue == nil {
        let queue = NSOperationQueue()
        queue.name = "BackgroundableQueue"
        concurrentQueue = (queue, 0)
    }
    concurrentQueue.count++
    
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
            toMainThread(block)
        }
        
        if concurrentQueue != nil {
            if --concurrentQueue.count < 0 {
                concurrentQueue.count = 0
            }
            if concurrentQueue.count == 0 {
                concurrentQueue = nil
            }
        }
        
        endBackgroundTask()
    }
    
    concurrentQueue.queue.addOperations(operations, waitUntilFinished: false)
}

public func toBackground(x: () -> Void)
{
    enqueue([NSBlockOperation(block: x)])
}

public func toMainThread(x: () -> Void)
{
    dispatch_async(dispatch_get_main_queue()) {
        x()
    }
}
