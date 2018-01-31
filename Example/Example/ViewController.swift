import UIKit

class ViewController: UIViewController, Visibility {

    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: - Visibility
    var appStateNotifications: [NSObjectProtocol] = []
    
    var isVisible: Bool = false

    open func willChangeVisibility() {
        //Printing out visibility changes
        print("Will change visibility; Are we visible? \(self.isVisible)")
    }
    
    open func didChangeVisibility() {
        //Printing out visibility changes
        print("Did change visibility; Are we visible? \(self.isVisible)")
    }
    
    //MARK: - View Controller Life Cycle
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.becomeAppStatesHandler()
    }
    
    override open func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.willChangeVisibility()
        self.isVisible = true
    }
    
    override open func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.didChangeVisibility()
    }
    
    override open func viewWillDisappear(_ animated: Bool)
    {
        self.willChangeVisibility()
        self.isVisible = false
        
        super.viewWillDisappear(animated)
    }
    
    override open func viewDidDisappear(_ animated: Bool)
    {
        self.didChangeVisibility()
        
        super.viewDidDisappear(animated)
    }
}

