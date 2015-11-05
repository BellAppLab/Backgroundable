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
    public var visible = false
    
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
        self.becomeAppStatesHandler()
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.resignAppStatesHandler()
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

public class BackgroundableTableViewController: UITableViewController, Visibility
{
    public var visible = false
    
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
        self.becomeAppStatesHandler()
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.resignAppStatesHandler()
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

public class BackgroundableCollectionViewController: UICollectionViewController, Visibility
{
    public var visible = false
    
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
        self.becomeAppStatesHandler()
    }
    
    override public func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override public func viewWillDisappear(animated: Bool)
    {
        self.resignAppStatesHandler()
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
