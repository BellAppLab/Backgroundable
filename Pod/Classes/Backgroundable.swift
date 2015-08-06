//
//  Backgroundable.swift
//  Project
//
//  Created by Bell App Lab on 05/08/15.
//  Copyright (c) 2015 Bell App Lab. All rights reserved.
//

import UIKit


//MARK: - Background task IDs

@objc public protocol Backgroundable: NSObjectProtocol
{
    var bgTaskId: UIBackgroundTaskIdentifier { get set }
    
    func startBackgroundTask()
    func endBackgroundTask()
}


//MARK: - Handling App States

@objc public protocol AppStatesHandler: NSObjectProtocol
{
    func handleAppState(notification: NSNotification)
    optional func handleAppStateChange(toBackground: Bool)
}


//MARK: - Visibility

@objc public protocol Visibility: NSObjectProtocol
{
    var visible: Bool { get set }
    func willChangeVisibility()
    func didChangeVisibility()
}


//MARK: - Extensions

extension NSObject: Backgroundable
{
    public var bgTaskId: UIBackgroundTaskIdentifier {
        get {
            if var int = objc_getAssociatedObject(self, "bgTaskId") as? Int {
                return int
            }
            return UIBackgroundTaskInvalid
        }
        set {
            //KVO
            self.willChangeValueForKey("bgTaskId")
            objc_setAssociatedObject(self, "bgTaskId", newValue as Int, UInt(OBJC_ASSOCIATION_RETAIN) as objc_AssociationPolicy)
            //KVO
            self.didChangeValueForKey("bgTaskId")
        }
    }
    
    public func startBackgroundTask() {
        startBgTask(self)
    }
    
    public func endBackgroundTask() {
        endBgTask(self)
    }
    
    public static func startBackgroundTask() -> UIBackgroundTaskIdentifier
    {
        return startBgTask()
    }
    
    public static func endBackgroundTask(backgroundTaskId: UIBackgroundTaskIdentifier)
    {
        endBgTask(backgroundTaskId)
    }
}

extension UIViewController: AppStatesHandler, Visibility
{
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
        handleAppStateNotification(result, self)
        self.willChangeVisibility()
        self.visible = !result
        self.didChangeVisibility()
    }
    
    public func handleAppStateChange(toBackground: Bool)
    {
        
    }
    
    //MARK: Visibility
    public var visible: Bool {
        get {
            if var int = objc_getAssociatedObject(self, "visible") as? Bool {
                return int
            }
            return false
        }
        set {
            objc_setAssociatedObject(self, "visible", newValue as Bool, UInt(OBJC_ASSOCIATION_RETAIN) as objc_AssociationPolicy)
        }
    }
    
    public func willChangeVisibility()
    {
        
    }
    
    public
    func didChangeVisibility()
    {
        
    }
}


//MARK: - Backgroundable View Controller

public class BackgroundableViewController: UIViewController
{
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
        super.resignBackgroundable()
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
        
        let queuer = self.concurrentQueue!
        startBgTask(queuer)
        
        var completionBlock = operation.completionBlock
        operation.completionBlock = { () -> Void in
            if var block = completionBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    block()
                })
            }
            self.didEndOperation()
            endBgTask(queuer)
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
        
        var first = operations.firstObject as! NSOperation
        operations.removeObjectAtIndex(0)
        (operations.objectAtIndex(0) as! NSOperation).addDependency(first)
        
        self.enqueue(operations)
    }
}


//MARK: Auxiliary global functions

private func startBgTask(object: Backgroundable)
{
    if object.bgTaskId != UIBackgroundTaskInvalid {
        endBgTask(object)
    }
    
    object.bgTaskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler{ () -> Void in
        endBgTask(object)
    }
}

public func startBgTask() -> UIBackgroundTaskIdentifier
{
    var result = UIBackgroundTaskInvalid
    result = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler{ () -> Void in
        endBgTask(result)
    }
    return result
}

private func endBgTask(object: Backgroundable)
{
    endBgTask(object.bgTaskId)
    object.bgTaskId = UIBackgroundTaskInvalid
}

public func endBgTask(bgTaskId: UIBackgroundTaskIdentifier)
{
    if bgTaskId == UIBackgroundTaskInvalid {
        return
    }
    
    UIApplication.sharedApplication().endBackgroundTask(bgTaskId)
}

internal func makeAppStatesHandler(object: AppStatesHandler)
{
    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.addObserver(object, selector: "handleAppState:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
    notificationCenter.addObserver(object, selector: "handleAppState:", name: UIApplicationWillEnterForegroundNotification, object: UIApplication.sharedApplication())
}

internal func unmakeAppStatesHandler(object: AppStatesHandler)
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
