//
//  LKPostingQueueMode.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/06/22.
//
//

import UIKit

public enum LKPostingQueueTransmitMode:Int {
    case Auto
    case Wifi
    case Manual
    
    public func description() -> String  {
        switch self {
        case Auto:
            return NSLocalizedString("Mode.Auto", bundle:postingQueueManagerBundle(), comment:"")
        case Wifi:
            return NSLocalizedString("Mode.Wifi", bundle:postingQueueManagerBundle(), comment:"")
        case Manual:
            return NSLocalizedString("Mode.Manual", bundle:postingQueueManagerBundle(), comment:"")
        }
    }
    
    public static func defaultMode() -> LKPostingQueueTransmitMode {
        if let intObj = NSUserDefaults.standardUserDefaults().objectForKey("LKPostingQueueTransmitMode") as? Int {
            if let mode = LKPostingQueueTransmitMode(rawValue: intObj) {
                return mode
            }
        }
        return .Auto
    }
    
    public func saveAsDefault() {
        NSUserDefaults.standardUserDefaults().setObject(self.rawValue, forKey: "LKPostingQueueTransmitMode")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
