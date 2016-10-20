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
        print("Will change visibility; Are we visible? \(self.isVisible)")
    }
    
    override func didChangeVisibility() {
        print("Did change visibility; Are we visible? \(self.isVisible)")
    }
}

