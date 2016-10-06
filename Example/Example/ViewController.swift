//
//  ViewController.swift
//  Example
//
//  Created by André Abou Chami Campana on 06/10/2016.
//  Copyright © 2016 Bell App Lab. All rights reserved.
//

import UIKit

class ViewController: BackgroundableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onTheMainThread {
            print("Are we on the main thread? \(Thread.isMainThread)")
        }
        
        inTheBackground {
            print("Are we in the background? \(!Thread.isMainThread)")
        }
    }

    override func willChangeVisibility() {
        print("Will change visibility; Are we visible? \(self.visible)")
    }
    
    override func didChangeVisibility() {
        print("Did change visibility; Are we visible? \(self.visible)")
    }
}

