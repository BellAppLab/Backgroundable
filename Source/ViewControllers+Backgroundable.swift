//
//  Backgroundable.swift
//  Project
//
//  Created by Bell App Lab on 05/08/15.
//  Copyright (c) 2015 Bell App Lab. All rights reserved.
//

import UIKit


//MARK: - Backgroundable View Controller
public class BackgroundableViewController: UIViewController, Visibility
{
    //MARK: Setup
    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: Visibility
    public var visible = false
    
    public func willChangeVisibility() {
        
    }
    
    public func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.becomeAppStatesHandler()
    }
    
    override public func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.willChangeVisibility()
        self.visible = true
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.willChangeVisibility()
        self.visible = false
        
        super.viewWillDisappear(animated)
    }
    
    override public func viewDidDisappear(animated: Bool)
    {
        self.didChangeVisibility()
        
        super.viewDidDisappear(animated)
    }
    
    public final override func handleAppStateChange(toBackground: Bool) {
        if (self.visible && toBackground) || (!self.visible && !toBackground) {
            self.willChangeVisibility()
            self.visible = !toBackground
            self.didChangeVisibility()
        }
    }
}


//MARK: - Backgroundable Table View Controller
public class BackgroundableTableViewController: UITableViewController, Visibility
{
    //MARK: Setup
    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: Visibility
    public var visible = false
    
    public func willChangeVisibility() {
        
    }
    
    public func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.becomeAppStatesHandler()
    }
    
    override public func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.willChangeVisibility()
        self.visible = true
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.willChangeVisibility()
        self.visible = false
        
        super.viewWillDisappear(animated)
    }
    
    override public func viewDidDisappear(animated: Bool)
    {
        self.didChangeVisibility()
        
        super.viewDidDisappear(animated)
    }
    
    public final override func handleAppStateChange(toBackground: Bool) {
        if (self.visible && toBackground) || (!self.visible && !toBackground) {
            self.willChangeVisibility()
            self.visible = !toBackground
            self.didChangeVisibility()
        }
    }
}


//MARK: - Backgroundable Collection View Controller
public class BackgroundableCollectionViewController: UICollectionViewController, Visibility
{
    //MARK: Setup
    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: Visibility
    public var visible = false
    
    public func willChangeVisibility() {
        
    }
    
    public func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.becomeAppStatesHandler()
    }
    
    override public func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.willChangeVisibility()
        self.visible = true
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.willChangeVisibility()
        self.visible = false
        
        super.viewWillDisappear(animated)
    }
    
    override public func viewDidDisappear(animated: Bool)
    {
        self.didChangeVisibility()
        
        super.viewDidDisappear(animated)
    }
    
    public final override func handleAppStateChange(toBackground: Bool) {
        if (self.visible && toBackground) || (!self.visible && !toBackground) {
            self.willChangeVisibility()
            self.visible = !toBackground
            self.didChangeVisibility()
        }
    }
}
