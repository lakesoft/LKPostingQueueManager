import Foundation
import FBNetworkReachability
import LKTaskCompletion
import LKQueue

public let kLKPostingQueueManagerNotificationUpdatedEntries = "LKPostingQueueManagerNotificationUpdatedEntrries"
public let kLKPostingQueueManagerNotificationWillPostEntry = "LKPostingQueueManagerNotificationWillPostEntry"
public let kLKPostingQueueManagerNotificationDidPostEntry = "LKPostingQueueManagerNotificationDidPostEntry"
public let kLKPostingQueueManagerNotificationDidAddEntry = "LKPostingQueueManagerNotificationDidAddEntry"
public let kLKPostingQueueManagerNotificationFailed = "LKPostingQueueManagerNotificationFailed"
public let kLKPostingQueueManagerNotificationStarted = "LKPostingQueueManagerNotificationStarted"
public let kLKPostingQueueManagerNotificationFinished = "LKPostingQueueManagerNotificationFinished"


public class LKPostingQueueManager: NSObject {
    
    //---------------
    // MARK: - Appearance
    //---------------
    public class Appearance {
        public var backColor:UIColor?
        public var barColor:UIColor?
        public var titleColor:UIColor?
        public var buttonColor:UIColor?
        public var textColor:UIColor?

        public var tableColor:UIColor?
        public var tableSeparatorColor:UIColor?
        public var cellColor:UIColor?
        public var cellTextColor:UIColor?
        public var selectedCellColor:UIColor?
        
        public init() {
        }
    }
    public var appearance:Appearance = Appearance()

    // TODO: エラー表示があった方がわかりやすい
    // TODO: (2) エラーログ、２行目以降がタップしても反応しない
    // TODO: (2) 個別送信への対応
    
    //---------------
    // MARK: - Definitions
    //---------------
    public enum RunningMode {
        case SkipFailedEntry, StopWhenFailed
    }
    
    // MARK: Members
    public var runningMode: RunningMode = .SkipFailedEntry

    private var _running: Bool = false
    public var running: Bool {
        set(running) {
            objc_sync_enter(self)
            _running = running
            objc_sync_exit(self)
        }
        get {
            var running: Bool?
            objc_sync_enter(self)
            running = _running
            objc_sync_exit(self)
            return running!
        }
    }
    
    public var postingEntries:[LKPostingEntry] {
        var postingEntries = [LKPostingEntry]()
        for queueEntry in queue.entries() {
            if let tmp = queueEntry.info as? LKPostingEntry {
                postingEntries += [tmp]
            }
        }
        return postingEntries
    }
    
    public func log(index: Int) -> String {
        if let queueEntry = queue.entryAtIndex(index) {
            if let logs = queueEntry.logs {
                if logs.count > 0 {
                    return logs[0] as! String
                }
            }
        }
        return "no log"
    }
    
    public func hasLogExisted(index: Int) -> Bool {
        if let queueEntry = queue.entryAtIndex(index) {
            if let logs = queueEntry.logs {
                return logs.count > 0
            }
        }
        return false
    }
    
    public var count:Int {
        return Int(queue.count())
    }
    
    public var queue:LKQueue {
        return LKQueueManager.defaultManager().queueWithName(queueName)
    }
    
    
    // MARK: Initializers and Factories
    let queueName = "LKPostingQueueManager"
    let handler:(LKPostingEntry, completion:()->Void, failure:(NSError)->Void)->Void

    public init(handler:(LKPostingEntry, completion:()->Void, failure:(NSError)->Void)->Void) {
        self.handler = handler
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatedNetwork:", name: FBNetworkReachabilityDidChangeNotification, object: nil)
        
        FBNetworkReachability.sharedInstance().startNotifier()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: API
    public func addPostingEntries(postingEntries:[LKPostingEntry]) {
        for postingEntry in postingEntries {
            queue.addEntryWithInfo(postingEntry, tagName: nil)
        }
        notify(kLKPostingQueueManagerNotificationDidAddEntry)
        notify(kLKPostingQueueManagerNotificationUpdatedEntries)
    }
    
    func isContinute(forced:Bool) -> Bool {
        if (!FBNetworkReachability.sharedInstance().reachable) {
            return false;
        }

        if forced {
            return true;
        } else {
            switch LKPostingQueueTransmitMode.defaultMode() {
            case .Auto:
                return true
            case .Wifi:
                if FBNetworkReachability.sharedInstance().connectionMode == FBNetworkReachabilityConnectionMode.ReachableWiFi {
                    return true;
                }
                break
            case .Manual:
                break
            }
        }
        return false;
    }
    
    public func start(forced:Bool=false) {
        
        // cheking status
        if queue.count() == 0 || running || !isContinute(forced) {
            return
        }
        
        // initializations
        running = true
        queue.resumeAllEntries()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        notify(kLKPostingQueueManagerNotificationStarted)
        
        NSLog("start")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationStarted, object: nil)
        })
        
        // start posting
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            var stop: Bool = false

            while !stop {
                if let queueEntry = self.queue.getEntryForProcessing() {
                    var processingIndex:Int = 0
                    for queueEntry in self.queue.entries() {
                        if queueEntry.state.value == LKQueueEntryStateProcessing.value {
                            break
                        }
                        processingIndex++
                    }
                    notify(kLKPostingQueueManagerNotificationWillPostEntry, processingIndex)
                    NSLog("will post")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationWillPostEntry, object: processingIndex)
                    })


                    let postingEntry = queueEntry.info as! LKPostingEntry
                    self.handler(postingEntry,
                        completion:{ ()->Void in
                            postingEntry.cleanup()
                            self.queue.changeEntry(queueEntry, toState: LKQueueEntryStateFinished)
                            self.queue.removeEntry(queueEntry)
                            notify(kLKPostingQueueManagerNotificationDidPostEntry, processingIndex)
                            notify(kLKPostingQueueManagerNotificationUpdatedEntries)
                        },
                        failure:{ (error:NSError)->Void in
                            NSLog("[ERROR] %@", error.description)
                            queueEntry.addLog(error.description)
                            self.queue.changeEntry(queueEntry, toState: LKQueueEntryStateSuspending)
                            notify(kLKPostingQueueManagerNotificationFailed, processingIndex)
                            NSLog("failed")
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationFailed, object: processingIndex)
                            })
                            if self.runningMode == .StopWhenFailed {
                                stop = true
                            }
                        }
                    )
                } else {
                    stop = true
                    break
                }
                
                if !self.isContinute(forced) {
                    stop = true
                    break
                }
            }
            
            // end posting
            LKTaskCompletion.sharedInstance().endBackgroundTask()
            self.running = false
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false;
            });
            notify(kLKPostingQueueManagerNotificationFinished)
        })
    }
    
    // MARK: Privates (Notification)
    func updatedNetwork(notification:NSNotification) {
        NSLog("[INFO] network changed: %@", notification)
    }
    
    // MARK: GUI
    public func instantiateViewController() -> LKPostingQueueViewController {
        let storyboard = UIStoryboard(name: "LKPostingQueueManager", bundle: postingQueueManagerBundle())
        let viewController = storyboard.instantiateInitialViewController() as! LKPostingQueueViewController
        viewController.postingQueueManager = self
        return viewController
    }
}

// MARK: - Functions

public func postingQueueManagerBundle() -> NSBundle {
    let frameworkBundle = NSBundle(forClass: LKPostingQueueManager.self)
    let path = frameworkBundle.pathForResource("LKPostingQueueManager", ofType: "bundle")!
    let bundle = NSBundle(path: path)!
    return bundle
}

func notify(name:String) {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil)
    })
}

func notify(name:String, index:Int) {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: index)
    })
}

