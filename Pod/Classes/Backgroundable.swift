//
//  Backgroundable.swift
//  Project
//
//  Created by Bell App Lab on 05/08/15.
//  Copyright (c) 2015 Bell App Lab. All rights reserved.
//

import UIKit


//MARK: - Background task IDs

@objc public protocol Backgroundable
{
    static func startBackgroundTask() -> UIBackgroundTaskIdentifier
    static func endBackgroundTask(backgroundTaskId: UIBackgroundTaskIdentifier)
}


//MARK: - Handling App States

@objc public protocol AppStatesHandler
{
    func handleAppState(notification: NSNotification)
    optional func handleAppStateChange(toBackground: Bool)
}


//MARK: - Visibility

@objc public protocol Visibility
{
    var visible: Bool { get set }
    func willChangeVisibility()
    func didChangeVisibility()
}


//MARK: - Extensions

extension NSObject: Backgroundable
{
    public static func startBackgroundTask() -> UIBackgroundTaskIdentifier
    {
        return startBgTask()
    }
    
    public static func endBackgroundTask(backgroundTaskId: UIBackgroundTaskIdentifier)
    {
        endBgTask(backgroundTaskId)
    }
}


//MARK: - Backgroundable View Controller

public class BackgroundableViewController: UIViewController, AppStatesHandler, Visibility
{
    public var visible = false
    
    //MARK: Becoming
    public final func becomeBackgroundable()
    {
        makeAppStatesHandler(self)
    }
    
    public final func resignBackgroundable()
    {
        unmakeAppStatesHandler(self)
    }
    
    //MARK: App States
    public func handleAppState(notification: NSNotification)
    {
        let result = appStateNotificationResult(notification)
        handleAppStateNotification(result, object: self)
        self.willChangeVisibility()
        self.visible = !result
        self.didChangeVisibility()
    }
    
    public func handleAppStateChange(toBackground: Bool)
    {
        
    }
    
    public func willChangeVisibility() {
        
    }
    
    public func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
    override public func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.willChangeVisibility()
        self.visible = true
        self.becomeBackgroundable()
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.resignBackgroundable()
        self.willChangeVisibility()
        self.visible = false
        
        super.viewWillDisappear(animated)
    }
    
    override public func viewDidDisappear(animated: Bool)
    {
        self.didChangeVisibility()
        
        super.viewDidDisappear(animated)
    }
}


//MARK: - Queuer

public typealias VoidClosure = ()->()

public class Queuer
{
    //MARK: Singletons
    private static var concurrentQueue: NSOperationQueue?
    
    //MARK: Setup
    private static var operationCount = 0
    private static func willStartOperation()
    {
        if ++operationCount == 1 {
            concurrentQueue = NSOperationQueue()
            concurrentQueue!.name = "Queuer.concurrent"
        }
    }
    private static func didEndOperation()
    {
        if --operationCount < 0 {
            operationCount = 0
        }
        if operationCount == 0 {
            concurrentQueue = nil
        }
    }
    
    //MARK: Enqueueing
    public static func enqueue(operation: NSOperation)
    {
        self.willStartOperation()
        
        let bgTaskId = startBgTask()
        
        let completionBlock = operation.completionBlock
        operation.completionBlock = { () -> Void in
            if let block = completionBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    block()
                })
            }
            self.didEndOperation()
            endBgTask(bgTaskId)
        }
        
        self.concurrentQueue!.addOperation(operation)
    }
    
    internal static func enqueue(closure: VoidClosure)
    {
        self.enqueue(NSBlockOperation(block: closure))
    }
    
    public static func enqueue(operations: [NSOperation])
    {
        if operations.count == 0 {
            return
        }
        
        self.enqueue(NSMutableArray(array: operations))
    }
    
    private static func enqueue(operations: NSMutableArray)
    {
        if operations.count == 1 {
            self.enqueue(operations.firstObject as! NSOperation)
            return
        }
        
        let first = operations.firstObject as! NSOperation
        operations.removeObjectAtIndex(0)
        (operations.objectAtIndex(0) as! NSOperation).addDependency(first)
        
        self.enqueue(operations)
    }
}


//MARK: Auxiliary global functions

public func startBgTask() -> UIBackgroundTaskIdentifier
{
    var result = UIBackgroundTaskInvalid
    result = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler{ () -> Void in
        endBgTask(result)
    }
    return result
}

public func endBgTask(bgTaskId: UIBackgroundTaskIdentifier)
{
    if bgTaskId == UIBackgroundTaskInvalid {
        return
    }
    
    UIApplication.sharedApplication().endBackgroundTask(bgTaskId)
}

public func makeAppStatesHandler(object: AppStatesHandler)
{
    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.addObserver(object, selector: "handleAppState:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
    notificationCenter.addObserver(object, selector: "handleAppState:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
}

public func unmakeAppStatesHandler(object: AppStatesHandler)
{
    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.removeObserver(object, name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
    notificationCenter.removeObserver(object, name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
}

private func appStateNotificationResult(notification: NSNotification) -> Bool
{
    return notification.name == UIApplicationWillResignActiveNotification
}

private func handleAppStateNotification(bool: Bool, object: AppStatesHandler)
{
    object.handleAppStateChange?(bool)
}

public func handleAppStateNotification(notification: NSNotification, forObject object: AppStatesHandler)
{
    object.handleAppStateChange?(appStateNotificationResult(notification))
}

public func toBackground(x: VoidClosure)
{
    Queuer.enqueue {
        x()
    }
}

public func toMainThread(x: VoidClosure)
{
    dispatch_async(dispatch_get_main_queue(), {
        x()
    })
}
