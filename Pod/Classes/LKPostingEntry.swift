//
//  LKPostingQueueEntry.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/05/30.
//
//

import UIKit
import LKCodingObject

public class LKPostingEntry: LKCodingObject {
   
    public var title: String?
    public var subTitle: String?
    public var size: Int64 = 0
    public var imagePath: String?

    public func cleanup() {
        // should be overridden
    }
    
    public func filePaths() -> [String] {
        // should be overridden
        return [String]()
    }
}
