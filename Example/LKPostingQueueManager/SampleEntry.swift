//
//  SampleEntry.swift
//  LKPostingQueueManager
//
//  Created by Hiroshi Hashiguchi on 2015/05/30.
//  Copyright (c) 2015年 CocoaPods. All rights reserved.
//

import UIKit
import LKPostingQueueManager

class SampleEntry: LKPostingEntry {

    var title:String?
    
    override func cleanup() {
        println("cleanup...")
    }
    
}
