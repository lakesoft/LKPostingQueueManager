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


open class LKPostingQueueManager: NSObject {
    
    //---------------
    // MARK: - Appearance
    //---------------
    open class Appearance {
        open var backColor:UIColor?
        open var barColor:UIColor?
        open var titleColor:UIColor?
        open var buttonColor:UIColor?
        open var textColor:UIColor?

        open var tableColor:UIColor?
        open var tableSeparatorColor:UIColor?
        open var cellColor:UIColor?
        open var cellTextColor:UIColor?
        open var cellDetailTextColor:UIColor?
        open var selectedCellColor:UIColor?
        
        public init() {
        }
    }
    open var appearance:Appearance = Appearance()

    //---------------
    // MARK: - Definitions
    //---------------
    public enum RunningMode {
        case skipFailedEntry, stopWhenFailed
    }
    public enum State {
        case operating, stopping
    }
    open var processingUnit: UInt = 1 {
        didSet {
            if processingUnit == 0 {
                processingUnit = 1
            }
        }
    }

    // MARK: Members
    open var runningMode: RunningMode = .skipFailedEntry

    fileprivate var _state: State = .stopping
    open var state: State {
        return _state
    }

    fileprivate var _running: Bool = false
    open var running: Bool {
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
    
    open var toolbarHidden: Bool = false
    
    open var postingEntries:[LKPostingEntry] {
        var postingEntries = [LKPostingEntry]()
        for queueEntry in queue.entries() {
            if let queueEntry = queueEntry as? LKQueueEntry, let tmp = queueEntry.info as? LKPostingEntry {
                postingEntries += [tmp]
            }
        }
        return postingEntries
    }
    
    open func log(_ index: Int) -> String {
        if let queueEntry = queue.entry(at: index) {
            if let logs = queueEntry.logs {
                if logs.count > 0 {
                    return logs[0] as! String
                }
            }
        }
        return "no log"
    }
    
    open func hasLogExisted(_ index: Int) -> Bool {
        if let queueEntry = queue.entry(at: index) {
            if let logs = queueEntry.logs {
                return logs.count > 0
            }
        }
        return false
    }
    
    open var count:Int {
        return Int(queue.count())
    }
    
    open var queue:LKQueue {
        return LKQueueManager.default().queue(withName: queueName)
    }
    
    
    // MARK: Initializers and Factories
    let queueName = "LKPostingQueueManager"
    let handler:([LKPostingEntry], _ completion:@escaping ([LKPostingEntry])->Void, _ failure:@escaping (NSError)->Void)->Void

    public init(handler:@escaping ([LKPostingEntry], _ completion:@escaping ([LKPostingEntry])->Void, _ failure:@escaping (NSError)->Void)->Void) {
        self.handler = handler
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(LKPostingQueueManager.updatedNetwork(_:)), name: NSNotification.Name(rawValue: FBNetworkReachabilityDidChangeNotification), object: nil)
        
        FBNetworkReachability.sharedInstance().startNotifier()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(LKPostingQueueManager.updated(_:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationUpdatedEntries), object: nil)
    }
    
    func updated(_ notification:Notification) {
        UIApplication.shared.applicationIconBadgeNumber = NSInteger(queue.count())
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: API
    open static func setup() {
        let settings = UIUserNotificationSettings(
            types: UIUserNotificationType.badge,
            categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings);
    }

    open func addPostingEntries(_ postingEntries:[LKPostingEntry]) {
        for postingEntry in postingEntries {
            queue.addEntry(withInfo: postingEntry, tagName: nil)
        }
        notify(kLKPostingQueueManagerNotificationDidAddEntries)
        notify(kLKPostingQueueManagerNotificationUpdatedEntries)
    }
    
    func isContinute(_ forced:Bool) -> Bool {
        if (!FBNetworkReachability.sharedInstance().reachable) {
            return false;
        }

        if forced {
            return true;
        } else {
            switch LKPostingQueueTransmitMode.defaultMode() {
            case .auto:
                return true
            case .wifi:
                if FBNetworkReachability.sharedInstance().connectionMode == FBNetworkReachabilityConnectionMode.reachableWiFi {
                    return true;
                }
                break
            case .manual:
                break
            }
        }
        return false;
    }
    
    open func start() {
        _state = .operating
        resume()
    }
    open func stop() {
        _state = .stopping
    }
    
    open func resume(_ forced:Bool=false) {
        
        // checking state
        if _state == .stopping {
            return
        }
        
        // cheking status
        if queue.count() == 0 || running || !isContinute(forced) {
            return
        }

        // initializations
        running = true
        queue.resumeAllEntries()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        notify(kLKPostingQueueManagerNotificationStarted)
        
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: kLKPostingQueueManagerNotificationStarted), object: nil)
        })
        
        // start posting
        DispatchQueue.global().async(execute: { () -> Void in
            
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
                    
                    { (skippedPostingEntries)->Void in
                        var completedIndexes = [Int]()
                        processingEntries.forEach({ (processingEntry) in
                            if skippedPostingEntries.contains(processingEntry.postingEntry) {
                                self.queue.changeEntry(processingEntry.queueEntry, to: LKQueueEntryStateWating)
                            } else {
                                completedIndexes += [processingEntry.index]
                                processingEntry.postingEntry.cleanup()
                                self.queue.changeEntry(processingEntry.queueEntry, to: LKQueueEntryStateFinished)
                                self.queue.removeEntry(processingEntry.queueEntry)
                            }
                        })
                        if completedIndexes.count > 0 {
                            notify(kLKPostingQueueManagerNotificationDidPostEntries, indexes: completedIndexes)
                        }
                        notify(kLKPostingQueueManagerNotificationUpdatedEntries)
                        wait = false
                    },
                    
                    { (error:NSError)->Void in
                        NSLog("[ERROR] %@", error.description)
                        var indexes = [Int]()
                        processingEntries.forEach({ (processingEntry) in
                            processingEntry.queueEntry.addLog(error.localizedDescription as NSCoding!)
                            self.queue.changeEntry(processingEntry.queueEntry, to: LKQueueEntryStateSuspending)
                            indexes += [processingEntry.index]
                        })
                        
                        notify(kLKPostingQueueManagerNotificationFailed, indexes: indexes)
                        DispatchQueue.main.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: Notification.Name(rawValue: kLKPostingQueueManagerNotificationFailed), object: indexes)
                        })
                        if self.runningMode == .stopWhenFailed {
                            stop = true
                        }
                        wait = false
                    })
                    
                while wait {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
        
                if !self.isContinute(forced) {
                    stop = true
                    break
                }
            }
            
            // end posting
            LKTaskCompletion.sharedInstance().endBackgroundTask()
            self.running = false
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false;
            });
            notify(kLKPostingQueueManagerNotificationFinished)
        })
    }
    
    struct LKProcessingEntry {
        let queueEntry: LKQueueEntry
        let postingEntry: LKPostingEntry
        let index: Int
    }
    
    func getPostingEntries(_ processingEntries: [LKProcessingEntry]) -> [LKPostingEntry] {
        return processingEntries.map({ (processingEntry) -> LKPostingEntry in
            processingEntry.postingEntry
        })
    }

    func getProcessingEntries() -> [LKProcessingEntry] {
        var processingEntries = [LKProcessingEntry]()

        for _ in 0..<processingUnit {
            if let queueEntry:LKQueueEntry = self.queue.getEntryForProcessing(),
                let postingEntry = queueEntry.info as? LKPostingEntry {

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
    func updatedNetwork(_ notification:Notification) {
        print("[INFO] network changed:\(notification.object)")

        if let r = notification.object as? FBNetworkReachability {
            let mode = LKPostingQueueTransmitMode.defaultMode()
            switch r.connectionMode {
            case .reachableWiFi:
                if mode == .wifi || mode == .auto {
                    resume()
                }
            case .reachableWWAN:
                if mode == .auto {
                    resume()
                }
            default:
                break
            }
        }
    }
    
    // MARK: GUI
    open func instantiateViewController() -> LKPostingQueueViewController {
        let storyboard = UIStoryboard(name: "LKPostingQueueManager", bundle: postingQueueManagerBundle())
        let viewController = storyboard.instantiateInitialViewController() as! LKPostingQueueViewController
        viewController.postingQueueManager = self
        return viewController
    }
}

// MARK: - Functions

public func postingQueueManagerBundle() -> Bundle {
    let frameworkBundle = Bundle(for: LKPostingQueueManager.self)
    let path = frameworkBundle.path(forResource: "LKPostingQueueManager", ofType: "bundle")!
    let bundle = Bundle(path: path)!
    return bundle
}

func notify(_ name:String) {
    DispatchQueue.main.async(execute: { () -> Void in
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: nil)
    })
}

func notify(_ name:String, indexes:[Int]) {
    DispatchQueue.main.async(execute: { () -> Void in
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: indexes)
    })
}

