//
//  ViewController.swift
//  LKPostingQueueManager
//
//  Created by Hiroshi Hashiguchi on 05/30/2015.
//  Copyright (c) 05/30/2015 Hiroshi Hashiguchi. All rights reserved.
//

import UIKit
import LKPostingQueueManager

class ViewController: UIViewController {
    
    let postingQueueManager = LKPostingQueueManager { (postingEntry, completion, failure) -> Void in
        
        if let entry = postingEntry as? SampleEntry {
            println("Processing: \(entry.title)")
            sleep(1)
            completion()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        var appearance = LKPostingQueueManager.Appearance()
        appearance.backColor = UIColor.blackColor()
        appearance.barColor = UIColor.blackColor()
        appearance.titleColor = UIColor.whiteColor()
        appearance.buttonColor = UIColor.whiteColor()
        appearance.textColor = UIColor.whiteColor()
        appearance.cellColor = UIColor.clearColor()
        appearance.cellTextColor = UIColor.lightGrayColor()
        appearance.tableColor = UIColor.blackColor()
        appearance.tableSeparatorColor = UIColor.darkGrayColor()
        postingQueueManager.appearance = appearance

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "did:", name: kLKPostingQueueManagerNotificationFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "did:", name: kLKPostingQueueManagerNotificationUpdated, object: nil)
        
        println(postingQueueManager.postingEntries)

        var entries = [SampleEntry]()
        for i in 0..<3 {
            let entry = SampleEntry()
            if i == 0 {
                entry.size = 10000
            }
            entry.title = NSString(format: "entry-%@-%02d", NSDate().description, i) as String
            entries += [entry]
        }
        postingQueueManager.addPostingEntries(entries)
        postingQueueManager.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func did(n:NSNotification) {
        println(n)
    }

    @IBAction func openView(sender: AnyObject) {
        let viewController = postingQueueManager.instantiateViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    @IBAction func openView2(sender: AnyObject) {
        let viewController = postingQueueManager.instantiateViewController()
        let naviController = UINavigationController(rootViewController: viewController)
        self.presentViewController(naviController, animated: true, completion: nil)
    }
}

