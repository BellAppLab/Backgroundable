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

public protocol AppStatesHandler: AnyObject
{
    func handleAppStateChange(toBackground: Bool)
}

public extension AppStatesHandler
{
    public func becomeAppStatesHandler() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleAppState:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.addObserver(self, selector: "handleAppState:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }
    
    func resignAppStatesHandler() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
        notificationCenter.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
    }
    
    public func handleAppState(notification: NSNotification) {
        if notification.name == UIApplicationWillResignActiveNotification {
            self.handleAppStateChange(true)
        } else if notification.name == UIApplicationWillEnterForegroundNotification {
            self.handleAppStateChange(false)
        }
    }
}

//MARK: Visibility

public protocol Visibility: AppStatesHandler
{
    var visible: Bool { get set }
    func willChangeVisibility()
    func didChangeVisibility()
}

public extension Visibility
{
    public func handleAppStateChange(toBackground: Bool) {
        self.willChangeVisibility()
        self.visible = !toBackground
        self.didChangeVisibility()
    }
}


//MARK: - Functions
//MARK: Background Task IDs

private var bgTaskId = UIBackgroundTaskInvalid

public func startBackgroundTask() {
    let currentTaskId = bgTaskId
    bgTaskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
        startBackgroundTask()
    }
    if currentTaskId != UIBackgroundTaskInvalid {
        UIApplication.sharedApplication().endBackgroundTask(currentTaskId)
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

public func enqueue(operation: NSOperation)
{
    if concurrentQueue == nil {
        let queue = NSOperationQueue()
        queue.name = "BackgroundableQueue"
        concurrentQueue = (queue, 0)
    }
    concurrentQueue.count++
    
    startBackgroundTask()
    
    let completionBlock = operation.completionBlock
    operation.completionBlock = { () -> Void in
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
    
    concurrentQueue.queue.addOperation(operation)
}

public func enqueue(var operations: [NSOperation])
{
    if operations.isEmpty {
        return
    }
    
    if operations.count == 1 {
        enqueue(operations.first!)
        return
    }
    
    let first = operations.removeFirst()
    operations.first!.addDependency(first)
    enqueue(operations)
}

public func toBackground(x: () -> Void)
{
    enqueue(NSBlockOperation(block: x))
}

public func toMainThread(x: () -> Void)
{
    dispatch_async(dispatch_get_main_queue()) {
        x()
    }
}
