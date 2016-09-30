//
//  LKPostingQueueEntry.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/30.
//
//

import UIKit
import LKCodingObject

open class LKPostingEntry: LKCodingObject {
   
    open var title: String?
    open var subTitle: String?
    open var size: Int64 = 0
    open var backImagePath: String?

    open func cleanup() {
        // should be overridden
    }
    
    open func filePaths() -> [String] {
        // should be overridden
        return [String]()
    }
}
