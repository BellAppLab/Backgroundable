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
        
        //Printing on the main thread
        onTheMainThread {
            print("Are we on the main thread? \(Thread.isMainThread)")
        }
        
        //Printing in the background
        inTheBackground {
            print("Are we in the background? \(!Thread.isMainThread)")
        }
        
        //Executing an AsyncOperation in the background
        let op = AsyncOperation { (operation) in
            print("Operation executed in the background!")
            operation.finish()
        }
        OperationQueue.background.addOperation(op)
        
        //Executing an AsyncOperation on the main operation queue
        OperationQueue.main.addOperation(AsyncOperation({ (op) in
            print("On the main operation queue")
            op.finish()
        }))
        
        //Executing sequential operations in the background
        var sequentialOperations = [Operation]()
        sequentialOperations.append(AsyncOperation({ (op) in
            print("Executing sequential operation 1")
            op.finish()
        }))
        sequentialOperations.append(AsyncOperation({ (op) in
            print("Executing sequential operation 2")
            op.finish()
        }))
        sequentialOperations.append(AsyncOperation({ (op) in
            print("Executing sequential operation 3")
            op.finish()
        }))
        OperationQueue.background.addSequentialOperations(sequentialOperations,
                                                          waitUntilFinished: false)
        
        //A timeout AsyncOperation
        OperationQueue.background.addOperation(AsyncOperation({ (op) in
            print("Waiting for timeout")
        }))
        
        //Executing a long running task in the background with dependencies; also moving between threads
        sequentialOperations = []
        sequentialOperations.append(AsyncOperation({ (op) in
            print("Sequencial async operation 1 - background")
            onTheMainThread {
                print("Sequencial async operation 1 - main thread")
                
                inTheBackground {
                    print("Sequencial async operation 1 - background again")
                    
                    op.finish()
                }
            }
        }))
        sequentialOperations.append(AsyncOperation({ (op) in
            print("Sequencial async operation 2")
        }))
        OperationQueue.background.addSequentialOperations(sequentialOperations,
                                                          waitUntilFinished: false)
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

