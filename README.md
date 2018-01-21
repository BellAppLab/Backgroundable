# Backgroundable

A collection of handy classes, extensions and global functions to handle being in the background on iOS using Swift.

_v0.7.0_

## Executing Code in the Background

Transform this:

```swift
let queue = OperationQueue()
var bgTaskId = UIBackgroundTaskInvalid
bgTaskId = UIApplication.shared.beginBackgroundTask { () -> Void in
    bgTaskId = UIBackgroundTaskInvalid
}
queue.addOperation(BlockOperation(block: { () -> Void in
    //do something in the background
    UIApplication.shared.endBackgroundTask(bgTaskId)
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
DispatchQueue.main.async {
    //do something on the main thread
}
```
    
**Into this**:

```swift
onTheMainThread {
    //you're back to the main thread
}
```

## Operations

Backgroundable exposes a nifty way to enqueue several operations that should be executed sequentially:

```swift
var sequentialOperations = [Operation]()
sequentialOperations.append(AsyncOperation({ (op) in
    print("Executing sequential operation 1")
    op.finish()
}))
sequentialOperations.append(BlockOperation({ 
    print("Executing sequential operation 2")
    //The sequential operations work with any Operation objects, not just AsyncOperations
}))
sequentialOperations.append(BlockOperation({ (op) in
    print("Executing sequential operation 3")
    op.finish()
}))
OperationQueue.background.addSequentialOperations(sequentialOperations, waitUntilFinished: false)
```

Backgroundable also provides a global background operation queue (similar to the existing `OperationQueue.main`):

```swift
OperationQueue.background.addOperation {
    //do something
}
```

This background queue is an instance of the `BackgroundQueue` class, which automatically handles background task identifiers. Whenever an operation is enqueued, a background task identifier is generated and whenever the queue is empty, the queue automatically invalidates it. 

These operations are guaranteed to be executed one after the other.

### Asyncronous Operations

An `AsyncOperation` is an easy way to perform asynchronous tasks in an `OperationQueue`. It's designed to make it easy to perform long-running tasks on an operation queue regardless of how many times its task needs to jump between threads. Only once everything is done, the `AsyncOperation` is removed from the queue. 

Say we have an asynchronous function we'd like to execute in the background:

```swift
self.loadThingsFromTheInternet(callback: { (result, error) in
    //process the result
})
```

If we wrapped this in an `Operation` object, we would have one small problem:

```swift
operationQueue.addOperation(BlockOperation({
    //We're on a background thread now; NICE!
    self.loadThingsFromTheInternet(callback: { (result, error) in
        //process the result
        //god knows in which thread this function returns... 
        //BTW, where's the BlockOperation?
    })
    //But wait... As soon as we call this function, the operation will already be finished and removed from the queue
    //We haven't finished what we wanted to do!
    //And the queue will now start executing its next operation!
}))
```

The `AsyncOperation` class solves this issue by exposing the operation object itself to its execution block and only changing its `isFinished` property once everything is done:

```swift
operationQueue.addOperation(AsyncOperation({ (op) in
    //We're on a background thread now; NICE!
    self.loadThingsFromTheInternet(callback: { (result, error) in
        //process the result
        //then move to the main thread
        onTheMainThread {
            //go to the main thread
            inTheBackground {
                //do more stuff in the background again
                //once everything is done, finish
                op.finish()
                //only now the queue will start working on the next thing
            }
        }
    })
}))
```

Nice, huh?

## Visibility and App States
    
Transform this: 

```swift
class ViewController: UIViewController {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundNotification(_:)), name: .UIApplicationWillResignActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
            do something when the view appears,
            but wait...
        */
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
            
        /*
            do something when the view disappears,
            but wait...
        */
    }
        
    func handleBackgroundNotification(_ notification: Notification) {
        /*
            say the user presses the home button
            now that viewWillDisappear method will never be called and you won't be able to undo the things you wanted...
        */
    }
}
```

**Into this**:

```swift
class ViewController: UIViewController, Visibility {

    open func willChangeVisibility() {
        //NO NEED TO CALL SUPER!
            
        if !self.isVisible { //we're becoming visible, either from navigation or from the app being launched
            // \o/
        } else { //we're becoming invisible
            
        }
    }
        
    open func didChangeVisibility() {
        if self.isVisible { //we're visible
            // \o/
        } else { //we're invisible
            
        }
    }
}
```

**NOTE: ** In order to get this ease of use, please make your `UIViewController` subclass conform to the `Visibility` protocol and implement the following methods:

```swift
deinit {
    self.resignAppStatesHandler()
}

//Visibility
var appStateNotifications: [NSObjectProtocol] = []

public var visible = false

open func willChangeVisibility() {

}

open func didChangeVisibility() {

}

//View Controller Life Cycle
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
```

## Requirements

* iOS 8+
* Swift 3.2+

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

**Swift 3 support**

```
git submodule add -b swift3 --name Backgroundable https://github.com/BellAppLab/Backgroundable.git
```

**Swift 2 support**

```
git submodule add -b swift2 --name Backgroundable https://github.com/BellAppLab/Backgroundable.git
```

Then, navigate to the new Backgroundable folder and drag the `Source` folder into your Xcode project.

## Author

Bell App Lab, apps@bellapplab.com

## License

Backgroundable is available under the MIT license. See the LICENSE file for more info.
