import UIKit


//MARK: - Backgroundable View Controller
open class BackgroundableViewController: UIViewController, Visibility
{
    //MARK: Setup
    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: Visibility
    public var isVisible = false
    
    open func willChangeVisibility() {
        
    }
    
    open func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
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
    
    override func handleAppStateChange(_ toBackground: Bool) {
        if (self.isVisible && toBackground) || (!self.isVisible && !toBackground) {
            self.willChangeVisibility()
            self.isVisible = !toBackground
            self.didChangeVisibility()
        }
    }
}


//MARK: - Backgroundable Table View Controller
open class BackgroundableTableViewController: UITableViewController, Visibility
{
    //MARK: Setup
    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: Visibility
    public var isVisible = false
    
    open func willChangeVisibility() {
        
    }
    
    open func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
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
    
    override func handleAppStateChange(_ toBackground: Bool) {
        if (self.isVisible && toBackground) || (!self.isVisible && !toBackground) {
            self.willChangeVisibility()
            self.isVisible = !toBackground
            self.didChangeVisibility()
        }
    }
}


//MARK: - Backgroundable Collection View Controller
open class BackgroundableCollectionViewController: UICollectionViewController, Visibility
{
    //MARK: Setup
    deinit {
        self.resignAppStatesHandler()
    }
    
    //MARK: Visibility
    public var isVisible = false
    
    open func willChangeVisibility() {
        
    }
    
    open func didChangeVisibility() {
        
    }
    
    //MARK: View Controller Life Cycle
    override open func viewDidLoad() {
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
    
    override func handleAppStateChange(_ toBackground: Bool) {
        if (self.isVisible && toBackground) || (!self.isVisible && !toBackground) {
            self.willChangeVisibility()
            self.isVisible = !toBackground
            self.didChangeVisibility()
        }
    }
}
