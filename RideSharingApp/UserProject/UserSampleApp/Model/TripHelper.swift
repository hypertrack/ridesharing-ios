//
//  Driver.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 01/05/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation

enum UserDefaultKeys: String {
    case driverId = "driverId"
    case actionId = "actionId.drop"
}

class TripHelper {
    
    static func getCurrentTripDriverId() -> String? {
        let driverId = UserDefaults.standard.string(forKey: UserDefaultKeys.driverId.rawValue)
        
        return driverId
    }
    
    static func saveCurrentTripDriverId(driverId: String) {
        UserDefaults.standard.set(driverId, forKey: UserDefaultKeys.driverId.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    static func resetCurrentTripDriverId() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.driverId.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    static func getLastTripActionId() -> String? {
        let actionId = UserDefaults.standard.string(forKey: UserDefaultKeys.actionId.rawValue)
        
        return actionId
    }
    
    static func saveLastTripActionId(actionId: String) {
        UserDefaults.standard.set(actionId, forKey: UserDefaultKeys.actionId.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    static func resetLastTripActionId() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.actionId.rawValue)
        UserDefaults.standard.synchronize()
    }
}
