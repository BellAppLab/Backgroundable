# Backgroundable [![Version](https://img.shields.io/badge/Version-1.4.1-black.svg?style=flat)](#installation) [![License](https://img.shields.io/cocoapods/l/Backgroundable.svg?style=flat)](#license)

[![Platforms](https://img.shields.io/badge/Platforms-iOS|tvOS|macOS|Linux-brightgreen.svg?style=flat)](#installation)
[![Swift support](https://img.shields.io/badge/Swift-4.2%20%7C%205.3-red.svg?style=flat)](#swift-versions-support)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Backgroundable.svg?style=flat&label=CocoaPods)](https://cocoapods.org/pods/Backgroundable)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-orange.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Twitter](https://img.shields.io/badge/Twitter-@BellAppLab-blue.svg?style=flat)](http://twitter.com/BellAppLab)

![Backgroundable](./Images/backgroundable.png)

Backgroundable is a collection of handy classes, extensions and global functions to handle being in the background using Swift.

It's main focus is to add functionalities to existing `Operation`s and `OperationQueue`s, without adding overheads to the runtime (aka it's fast) nor to the developer (aka there's very little to learn).

It's powerful because it's simple.

## Specs

* iOS 10+
* tvOS 10+
* macOS 10.12+
* Swift 4.2+
* Objective-C ready

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

## Operation Queues

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

### Background Queue

Backgroundable also provides a global background operation queue (similar to the existing `OperationQueue.main`):

```swift
OperationQueue.background.addOperation {
    //do something
}
```

This background queue is an instance of the `BackgroundQueue` class, which automatically handles background task identifiers. Whenever an operation is enqueued, a background task identifier is generated and whenever the queue is empty, the queue automatically invalidates it. 

Sequential operations are guaranteed to be executed one after the other.

### Background Queue Delegate

The `BackgroundQueue` class accepts a `BackgroundQueueDelegate`, which is notified whenever the queue `backgroundQueueWillStartOperations(_:)` and when `backgroundQueueDidFinishOperations(_:)`. 

This is quite handy if you want to show the network activity indicator or save a database or anything else really. The sky is the limit!

## Asyncronous Operations

An `AsyncOperation` is an easy way to perform asynchronous tasks in an `OperationQueue`. It's designed to make it easy to perform long-running tasks on an operation queue regardless of how many times its task needs to jump between threads. Only once everything is done, the `AsyncOperation` is removed from the queue. 

Say we have an asynchronous function we'd like to execute in the background:

```swift
self.loadThingsFromTheInternet(callback: { (result, error) in
    //process the result
})
```

If we wrapped this in an `Operation` object, we would have one small problem:

```swift
operationQueue.addOperation(BlockOperation({ [weak self] in
    //We're on a background thread now; NICE!
    self?.loadThingsFromTheInternet(callback: { (result, error) in
        //process the result
        //who knows in which thread this function returns... 
    })
    //Aaaand... As soon as we call the load function, the operation will already be finished and removed from the queue
    //But we haven't finished what we wanted to do!
    //And the queue will now start executing its next operation!
    //Sigh...
}))
```

The `AsyncOperation` class solves this issue by exposing the operation object itself to its execution block and only changing its `isFinished` property once everything is done:

```swift
operationQueue.addOperation(AsyncOperation({ [weak self] (op) in
    //We're on a background thread now; NICE!
    self?.loadThingsFromTheInternet(callback: { (result, error) in
        //process the result
        //then move to the main thread
        onTheMainThread {
            //go to the background
            inTheBackground {
                //do more stuff 
                //once everything is done, finish
                op.finish()
                //only now the queue will start working on the next thing
            }
        }
    })
}))
```

Nice, huh?

### Timeouts

There's no way for an `AsyncOperation` to know when it's done (hence, we need to call `op.finish()` when its work is done). But sometimes, we developers - ahem - forget things. 

Thus, in order to cover for the case where `op.finish()` may never be called (consequently blocking the `OperationQueue`), `AsyncOperation`s come with a timeout (**defaulting to 10 seconds**). After the timeout elapses, the operation is automaticallt finished and removed from the queue. 

It may be the case that your `AsyncOperation`'s workload takes longer than the default timeout. If that's the case, you can define a new timeout like this:

```swift
AsyncOperation(timeout: 20, { (op) in
    //perform very long task
    op.finish()
})
```

Optionally, you can set the `onTimeoutCallback:` when instantiating a new `AsyncOperation` to be notified when your operations times out.

### Cancelations

As per [Apple's documentation](https://developer.apple.com/documentation/foundation/operation/1408418-iscancelled), it's always a good idea to check if your operation has been cancelled during the execution of its closure and shortcircuit it prematurely if needed. For example:

```swift
AsyncOperation({ (op) in 
    //do some work
    
    guard !op.isCancelled else { return } //No need to call finish() in this case
    
    //do some more work
})
```

### Uniqueness Policy

The uniqueness policy dictates whether `AsyncOperation`s with the same `name` should co-exist in a `BackgroundQueue`. This is great for deduplicating operations, for example:

```swift
@IBAction func refresh(_ sender: UIRefreshControl) {
    let op = AsyncOperation(name: "Call to API endpoint /xyz", uniquenessPolicy: .drop) { op in
        //make the call to the API
        op.finish()
    }
    OperationQueue.background.addOperation(op)
}
```

This first time the user activates the refresh control, the operation will be added to the queue as normal, because there are no other operations with the name `"Call to API endpoint /xyz"` there yet. But if the user activates the control again before the first call to the API returns, then the `.drop` policy will make sure that a second operation is not added to the queue, since there's one operation with that name in there already. If `.replace` is set, then the previous operation is cancelled and the new one replaces it. 

Neat! 

## Installation

### Cocoapods

```ruby
pod 'Backgroundable', '~> 1.4'
```

Then `import Backgroundable` where needed.

### Carthage

```swift
github "BellAppLab/Backgroundable" ~> 1.4
```

Then `import Backgroundable` where needed.

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/BellAppLab/Backgroundable", from: "1.4")
]
```

Then `import Backgroundable` where needed.

### Git Submodules

```shell
cd toYourProjectsFolder
git submodule add -b submodule --name Backgroundable https://github.com/BellAppLab/Backgroundable.git
```

Then drag the `Backgroundable` folder into your Xcode project.

## Author

Bell App Lab, apps@bellapplab.com

### Credits

[Logo image](https://thenounproject.com/search/?q=flow&i=1469609#) by [Becris](https://thenounproject.com/Becris) from [The Noun Project](https://thenounproject.com/)

## License

Backgroundable is available under the MIT license. See the LICENSE file for more info.
