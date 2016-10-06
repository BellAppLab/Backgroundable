# Backgroundable

A collection of handy classes, extensions and global functions to handle being in the background on iOS using Swift.

## Usage

Transform this:

```swift
let queue = NSOperationQueue()
var bgTaskId = UIBackgroundTaskInvalid
bgTaskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
    bgTaskId = UIBackgroundTaskInvalid
}
queue.addOperation(NSBlockOperation(block: { () -> Void in
    //do something in the background
    UIApplication.sharedApplication().endBackgroundTask(bgTaskId)
}))
```
    
**Into this**:

```swift
inTheBackground {
    //move to the background and get on with your life
}
```
    
And transform this:

```swift
dispatch_async(dispatch_get_main_queue(), { () -> Void in
    //do something on the main thread
})
```
    
**Into this**:

```swift
onTheMainThread {
    //you're back to the main thread
}
```
    
And transform this: 

```swift
class ViewController: UIViewController {

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleBackgroundNotification:", name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
            do something when the view appears,
            but wait...
        */
    }
        
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
            
        /*
            do something when the view disappears,
            but wait...
        */
    }
        
    func handleBackgroundNotification(notification: NSNotification) {
        /*
            say the user presses the home button
            now that viewWillDisappear method will never be called and you won't be able to undo the things you wanted...
        */
    }
}
```

**Into this**:

```swift
class ViewController: BackgroundableViewController {

    override func willChangeVisibility() {
        //NO NEED TO CALL SUPER!
            
        if !self.visible { //we're becoming visible, either from navigation or from the app being launched
            // \o/
        } else { //we're becoming invisible
            
        }
    }
        
    override func didChangeVisibility() {
        if self.visible { //we're visible
            // \o/
        } else { //we're invisible
            
        }
    }
}
```

## Requirements

* iOS 8+
* Swift 3.0

## Installation

### Cocoapods

Because of [this](http://stackoverflow.com/questions/39637123/cocoapods-app-xcworkspace-does-not-exists), I've dropped support for Cocoapods on this repo. I cannot have production code rely on a dependency manager that breaks this badly. 

### Git Submodules

**Why submodules, you ask?**

Following [this thread](http://stackoverflow.com/questions/31080284/adding-several-pods-increases-ios-app-launch-time-by-10-seconds#31573908) and other similar to it, and given that Cocoapods only works with Swift by adding the use_frameworks! directive, there's a strong case for not bloating the app up with too many frameworks. Although git submodules are a bit trickier to work with, the burden of adding dependencies should weigh on the developer, not on the user. :wink:

To install Backgroundable using git submodules:

```
cd toYourProjectsFolder
git submodule add -b submodule --name Backgroundable https://github.com/BellAppLab/Backgroundable.git
```

Navigate to the new Backgroundable folder and drag the `Source` folder into your Xcode project.

## Author

Bell App Lab, apps@bellapplab.com

## License

Backgroundable is available under the MIT license. See the LICENSE file for more info.
