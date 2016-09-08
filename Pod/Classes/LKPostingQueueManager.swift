// backlog
// - display error label
// - send any queue

// TODO:
// シチュエーション
// ・詳細を開いている間に、そのキューが送信対象となる
// ・削除ボタンを開いている時に、そのキューが送信対象となる
// → 送信対象になった時に下記を実施
//    1. 削除ボタンを閉じる
//    2. 詳細画面を閉じる
// ・ネット接続時に自動的に再送信する（ON/OFF制御できるようにする）
//
// READMEを書くべし!!（自分のため）
    
    
import Foundation
import FBNetworkReachability
import LKTaskCompletion
import LKQueue

public let kLKPostingQueueManagerNotificationUpdatedEntries = "LKPostingQueueManagerNotificationUpdatedEntrries"
public let kLKPostingQueueManagerNotificationWillPostEntries = "LKPostingQueueManagerNotificationWillPostEntries"
public let kLKPostingQueueManagerNotificationDidPostEntries = "LKPostingQueueManagerNotificationDidPostEntries"
public let kLKPostingQueueManagerNotificationDidAddEntries = "LKPostingQueueManagerNotificationDidAddEntries"
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
        public var cellDetailTextColor:UIColor?
        public var selectedCellColor:UIColor?
        
        public init() {
        }
    }
    public var appearance:Appearance = Appearance()

    //---------------
    // MARK: - Definitions
    //---------------
    public enum RunningMode {
        case SkipFailedEntry, StopWhenFailed
    }
    public enum State {
        case Operating, Stopping
    }
    public var processingUnit: UInt = 1 {
        didSet {
            if processingUnit == 0 {
                processingUnit = 1
            }
        }
    }

    // MARK: Members
    public var runningMode: RunningMode = .SkipFailedEntry

    private var _state: State = .Stopping
    public var state: State {
        return _state
    }

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
    
    public var toolbarHidden: Bool = false
    
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
    let handler:([LKPostingEntry], completion:([LKPostingEntry])->Void, failure:(NSError)->Void)->Void

    public init(handler:([LKPostingEntry], completion:([LKPostingEntry])->Void, failure:(NSError)->Void)->Void) {
        self.handler = handler
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatedNetwork:", name: FBNetworkReachabilityDidChangeNotification, object: nil)
        
        FBNetworkReachability.sharedInstance().startNotifier()
        
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "updated:", name: kLKPostingQueueManagerNotificationUpdatedEntries, object: nil)
    }
    
    func updated(notification:NSNotification) {
        UIApplication.sharedApplication().applicationIconBadgeNumber = NSInteger(queue.count())
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: API
    public static func setup() {
        let settings = UIUserNotificationSettings(
            forTypes: UIUserNotificationType.Badge,
            categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings);
    }

    public func addPostingEntries(postingEntries:[LKPostingEntry]) {
        for postingEntry in postingEntries {
            queue.addEntryWithInfo(postingEntry, tagName: nil)
        }
        notify(kLKPostingQueueManagerNotificationDidAddEntries)
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
    
    public func start() {
        _state = .Operating
        resume()
    }
    public func stop() {
        _state = .Stopping
    }
    
    public func resume(forced:Bool=false) {
        
        // checking state
        if _state == .Stopping {
            return
        }
        
        // cheking status
        if queue.count() == 0 || running || !isContinute(forced) {
            return
        }

        // initializations
        running = true
        queue.resumeAllEntries()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        notify(kLKPostingQueueManagerNotificationStarted)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationStarted, object: nil)
        })
        
        // start posting
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            var stop: Bool = false

            while !stop {
                let processingEntries = self.getProcessingEntries()
                if processingEntries.count == 0 {
                    stop = true
                    break
                }
                
                let postingEntries = self.getPostingEntries(processingEntries)

                var wait:Bool = true
                self.handler(postingEntries,
                    
                    completion:{ (skippedPostingEntries)->Void in
                        var completedIndexes = [Int]()
                        processingEntries.forEach({ (processingEntry) in
                            if skippedPostingEntries.contains(processingEntry.postingEntry) {
                                self.queue.changeEntry(processingEntry.queueEntry, toState: LKQueueEntryStateWating)
                            } else {
                                completedIndexes += [processingEntry.index]
                                processingEntry.postingEntry.cleanup()
                                self.queue.changeEntry(processingEntry.queueEntry, toState: LKQueueEntryStateFinished)
                                self.queue.removeEntry(processingEntry.queueEntry)
                            }
                        })
                        if completedIndexes.count > 0 {
                            notify(kLKPostingQueueManagerNotificationDidPostEntries, indexes: completedIndexes)
                        }
                        notify(kLKPostingQueueManagerNotificationUpdatedEntries)
                        wait = false
                    },
                    
                    failure:{ (error:NSError)->Void in
                        NSLog("[ERROR] %@", error.description)
                        var indexes = [Int]()
                        processingEntries.forEach({ (processingEntry) in
                            processingEntry.queueEntry.addLog(error.localizedDescription)
                            self.queue.changeEntry(processingEntry.queueEntry, toState: LKQueueEntryStateSuspending)
                            indexes += [processingEntry.index]
                        })
                        
                        notify(kLKPostingQueueManagerNotificationFailed, indexes: indexes)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationFailed, object: indexes)
                        })
                        if self.runningMode == .StopWhenFailed {
                            stop = true
                        }
                        wait = false
                    })
                    
                while wait {
                    NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
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
    
    struct LKProcessingEntry {
        let queueEntry: LKQueueEntry
        let postingEntry: LKPostingEntry
        let index: Int
    }
    
    func getPostingEntries(processingEntries: [LKProcessingEntry]) -> [LKPostingEntry] {
        return processingEntries.map({ (processingEntry) -> LKPostingEntry in
            processingEntry.postingEntry
        })
    }

    func getProcessingEntries() -> [LKProcessingEntry] {
        var processingEntries = [LKProcessingEntry]()

        for _ in 0..<processingUnit {
            if let queueEntry:LKQueueEntry = self.queue.getEntryForProcessing(),
                postingEntry = queueEntry.info as? LKPostingEntry {

                var index:Int = 0
                for e in self.queue.entries() {
                    let entry = e as! LKQueueEntry
                    if entry == queueEntry {
                        break
                    }
                    index += 1
                }
                
                let processingEntry = LKProcessingEntry(queueEntry: queueEntry, postingEntry: postingEntry, index: index)
                
                processingEntries += [processingEntry]

//                notify(kLKPostingQueueManagerNotificationWillPostEntries, index: processingIndex)
                //                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //                        NSNotificationCenter.defaultCenter().postNotificationName(kLKPostingQueueManagerNotificationWillPostEntry, object: processingIndex)
                //                    })
            } else {
                break
            }
        }
        return processingEntries
    }
    
    // MARK: Privates (Notification)
    func updatedNetwork(notification:NSNotification) {
        print("[INFO] network changed:\(notification.object)")

        if let r = notification.object as? FBNetworkReachability {
            let mode = LKPostingQueueTransmitMode.defaultMode()
            switch r.connectionMode {
            case .ReachableWiFi:
                if mode == .Wifi || mode == .Auto {
                    resume()
                }
            case .ReachableWWAN:
                if mode == .Auto {
                    resume()
                }
            default:
                break
            }
        }
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

func notify(name:String, indexes:[Int]) {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: indexes)
    })
}

