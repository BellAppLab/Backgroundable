# Backgroundable

[![CI Status](http://img.shields.io/travis/Bell App Lab/Backgroundable.svg?style=flat)](https://travis-ci.org/Bell App Lab/Backgroundable)
[![Version](https://img.shields.io/cocoapods/v/Backgroundable.svg?style=flat)](http://cocoapods.org/pods/Backgroundable)
[![License](https://img.shields.io/cocoapods/l/Backgroundable.svg?style=flat)](http://cocoapods.org/pods/Backgroundable)
[![Platform](https://img.shields.io/cocoapods/p/Backgroundable.svg?style=flat)](http://cocoapods.org/pods/Backgroundable)

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

iOS 8+

## Installation

Backgroundable is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Backgroundable"
```

## Author

Bell App Lab, apps@bellapplab.com

## License

Backgroundable is available under the MIT license. See the LICENSE file for more info.
