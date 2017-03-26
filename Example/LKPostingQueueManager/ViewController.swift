//
//  ViewController.swift
//  LKPostingQueueManager
//
//  Created by Hiroshi Hashiguchi on 05/30/2015.
//  Copyright (c) 05/30/2015 Hiroshi Hashiguchi. All rights reserved.
//

import UIKit
import LKPostingQueueManager

class ViewController: UIViewController, LKPostingQueueManagerDelegate {
    
    let postingQueueManager = LKPostingQueueManager { (postingEntries, completion, failure) -> Void in
        
        sleep(1)

        let r = arc4random() % 3
        if r == 0 {
            var err:NSError = NSError(domain: "error", code: 12, userInfo: [NSLocalizedDescriptionKey:"Local"])
            failure(err)
            
        } else {
            var skippedPostingEntries = [LKPostingEntry]()
            var completed:Int = 0
            postingEntries.forEach { (postingEntry) in
                if let postingEntry = postingEntry as? SampleEntry {
                    if r == 1 {
                        skippedPostingEntries += [postingEntry]
                    } else {
                        completed += 1
                    }
                }
            }
            print("---- processed: \(completed)/\(postingEntries.count)")
            completion(skippedPostingEntries)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        postingQueueManager.delegate = self
        
        let appearance = LKPostingQueueManager.Appearance()
        appearance.backColor = UIColor.black
        appearance.barColor = UIColor.black
        appearance.titleColor = UIColor.white
        appearance.buttonColor = UIColor.white
        appearance.textColor = UIColor.white
        appearance.cellColor = UIColor.clear
        appearance.cellTextColor = UIColor.white
        appearance.cellDetailTextColor = UIColor.lightGray
        appearance.selectedCellColor = UIColor.blue
        appearance.tableColor = UIColor.black
//        appearance.tableSeparatorColor = UIColor.darkGrayColor()
//        appearance.backColor = UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 0.5)
//        appearance.barColor = UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 0.75)
//        appearance.titleColor = UIColor.whiteColor()
//        appearance.buttonColor = UIColor.whiteColor()
//        appearance.textColor = UIColor.whiteColor()
//        appearance.cellColor = UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 0.5)
//        appearance.cellTextColor = UIColor.whiteColor()
//        appearance.selectedCellColor = UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 0.75)
//        appearance.tableColor = UIColor.blackColor()
//        appearance.tableSeparatorColor = UIColor.darkGrayColor()
        postingQueueManager.appearance = appearance

        NotificationCenter.default.addObserver(self, selector: #selector(self.did(n:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationFinished), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.did(n:)), name: NSNotification.Name(rawValue: kLKPostingQueueManagerNotificationUpdatedEntries), object: nil)
        
        print(postingQueueManager.postingEntries)
        
        var entries = [SampleEntry]()
        for i in 0..<15 {
            let entry = SampleEntry()
            if i == 0 {
                entry.size = 10000
            }
            entry.title = NSString(format: "entry-%@-%02d", NSDate().description, i) as String
            entry.subTitle = "Sub Title .."
            
            if let path = Bundle.main.path(forResource: "test", ofType: "jpg") {
                entry.backImagePath = path
            }
            entries += [entry]
        }
        postingQueueManager.processingUnit = 3
        postingQueueManager.addPostingEntries(entries)
//        postingQueueManager.runningMode = .StopWhenFailed
        postingQueueManager.start()
        
        postingQueueManager.toolbarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func did(n:NSNotification) {
        print(n)
    }

    @IBAction func openView(sender: AnyObject) {
        let viewController = postingQueueManager.instantiateViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    @IBAction func openView2(sender: AnyObject) {
        let viewController = postingQueueManager.instantiateViewController()
        let naviController = UINavigationController(rootViewController: viewController)
        self.present(naviController, animated: true, completion: nil)
    }
    
    func handleRmoveEntry(view: UIView, doRemove:@escaping () -> Void) {
        doRemove()
    }
}

