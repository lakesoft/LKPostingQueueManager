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
     
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "did:", name: kLKPostingQueueManagerNotificationFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "did:", name: kLKPostingQueueManagerNotificationUpdated, object: nil)
        
        println(postingQueueManager.postingEntries)

        var entries = [SampleEntry]()
        for i in 0..<5 {
            let entry = SampleEntry()
            entry.title = NSString(format: "entry-%@-%02d", NSDate().description, i) as String
            entries += [entry]
        }
        postingQueueManager.addPostingEntries(entries)
        postingQueueManager.start(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func did(n:NSNotification) {
        println(n)
    }

}

