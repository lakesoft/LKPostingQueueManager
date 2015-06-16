import Foundation
import FBNetworkReachability
import LKTaskCompletion
import LKQueue

public let kLKPostingQueueManagerNotificationUpdated = "LKPostingQueueManagerNotificationUpdated"
public let kLKPostingQueueManagerNotificationPostedEntry = "LKPostingQueueManagerNotificationPostedEntry"
public let kLKPostingQueueManagerNotificationAddedEntry = "LKPostingQueueManagerNotificationAddedEntry"
public let kLKPostingQueueManagerNotificationFinished = "LKPostingQueueManagerNotificationFinished"


public class LKPostingQueueManager: NSObject {
    
    //
    public class Appearance {
        public var backColor:UIColor?
        public var barColor:UIColor?
        public var titleColor:UIColor?
        public var buttonColor:UIColor?

        public var tableColor:UIColor?
        public var tableSeparatorColor:UIColor?
        public var cellColor:UIColor?
        public var cellTextColor:UIColor?
        
        public init() {
        }
    }
    public var appearance:Appearance = Appearance()

    // MARK: Definitions
    public enum Result {
        case NotFinished, Succeeded, Failed
    }
    
    // MARK: Members
    public var result: Result = .NotFinished

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
        notify(kLKPostingQueueManagerNotificationAddedEntry)
    }
    
    public func start(forced:Bool) {
        
        // cheking status
        if (!FBNetworkReachability.sharedInstance().reachable) {
            return;
        }
        if queue.count() == 0 {
            return;
        }
        if result == .Failed && !forced {
            return
        }
        if running {
            return
        }
        
        // initializations
        running = true
        queue.resumeAllEntries()
        notify(kLKPostingQueueManagerNotificationUpdated)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // start posting
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            while self.queue.count() > 0 {
                self.result = .NotFinished
                
                if let queueEntry = self.queue.getEntryForProcessing() {
                    let postingEntry = queueEntry.info as! LKPostingEntry
                    self.handler(postingEntry,
                        completion:{ ()->Void in
                            self.result = .Succeeded
                            postingEntry.cleanup()
                            self.queue.changeEntry(queueEntry, toState: LKQueueEntryStateFinished)
                            self.queue.removeEntry(queueEntry)
                            notify(kLKPostingQueueManagerNotificationPostedEntry)
                        },
                        failure:{ (error:NSError)->Void in
                            NSLog("[ERROR] %@", error.description)
                            self.result = .Failed
                            queueEntry.logs = [error.localizedDescription]
                            self.queue.changeEntry(queueEntry, toState: LKQueueEntryStateSuspending)
                        }
                    )
                }
                
                while self.result == .NotFinished {
                    sleep(1)
                }
                if self.result == .Failed {
                    break
                }
                sleep(3)
            }
            
            // end posting
            LKTaskCompletion.sharedInstance().endBackgroundTask()
            self.running = false
            notify(kLKPostingQueueManagerNotificationUpdated)
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
    public func instantiateViewController() -> LKPostingQueueTableViewController {
        let storyboard = UIStoryboard(name: "LKPostingQueueManager", bundle: postingQueueManagerBundle())
        let viewController = storyboard.instantiateInitialViewController() as! LKPostingQueueTableViewController
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

