//
//  Backgroundable.swift
//  Project
//
//  Created by Bell App Lab on 05/08/15.
//  Copyright (c) 2015 Bell App Lab. All rights reserved.
//

import UIKit


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


//MARK: - Backgroundable Table View Controller

public class BackgroundableTableViewController: UITableViewController, AppStatesHandler, Visibility
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


//MARK: - Backgroundable Collection View Controller

public class BackgroundableCollectionViewController: UICollectionViewController, AppStatesHandler, Visibility
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
