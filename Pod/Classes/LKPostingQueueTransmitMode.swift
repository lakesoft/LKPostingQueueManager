//
//  LKPostingQueueMode.swift
//  Pods
//
//  Created by Hiroshi Hashiguchi on 2015/06/22.
//
//

import UIKit

public enum LKPostingQueueTransmitMode:Int {
    case auto
    case wifi
    case manual
    
    public func description() -> String  {
        switch self {
        case .auto:
            return NSLocalizedString("Mode.Auto", bundle:postingQueueManagerBundle(), comment:"")
        case .wifi:
            return NSLocalizedString("Mode.Wifi", bundle:postingQueueManagerBundle(), comment:"")
        case .manual:
            return NSLocalizedString("Mode.Manual", bundle:postingQueueManagerBundle(), comment:"")
        }
    }
    
    public static func defaultMode() -> LKPostingQueueTransmitMode {
        if let intObj = UserDefaults.standard.object(forKey: "LKPostingQueueTransmitMode") as? Int {
            if let mode = LKPostingQueueTransmitMode(rawValue: intObj) {
                return mode
            }
        }
        return .auto
    }
    
    public func saveAsDefault() {
        UserDefaults.standard.set(self.rawValue, forKey: "LKPostingQueueTransmitMode")
        UserDefaults.standard.synchronize()
    }
}
