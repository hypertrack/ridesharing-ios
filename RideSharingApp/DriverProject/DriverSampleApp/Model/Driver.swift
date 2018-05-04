//
//  Driver.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 11/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import Firebase
import HyperTrack

enum DriverState {
    case lookingForTrip
    case onTrip
    case dontKnow
}

enum DriverKeys: String {
    case name = "name"
    case carDetails = "carDetails"
}

struct Driver {
    let htUserId: String
    let firebaseId: String
    let phone: String
    var name: String?       //TODO: get it from firebase
    var carDetails: String? //TODO: get it from firebase
    let rating: Int?        //TODO: get it from firebase
    let imageUrl: String?   //TODO: get image url
    var state: DriverState  //TODO: compute from fb
    var isOnRide: Bool?
    //TODO: Add more properties
}

extension Driver {
    
    static func createDriver(withFBUser user: User?, hyperTrackUserId: String?) -> Driver? {
        if let phone = user?.phoneNumber, let firebaseId = user?.uid, let hyperTrackUserId = hyperTrackUserId {
            let name = UserDefaults.standard.string(forKey: DriverKeys.name.rawValue)
            let carDetails = UserDefaults.standard.string(forKey: DriverKeys.carDetails.rawValue)
            let driver = Driver.init(htUserId: hyperTrackUserId, firebaseId: firebaseId, phone: phone, name: name, carDetails: carDetails, rating: nil, imageUrl: nil, state: .dontKnow, isOnRide: nil)
            return driver
        }
        return nil
    }
    
    static func defaultDriver() -> Driver? {
        let user = Auth.auth().currentUser
        let htUserId = HyperTrack.getUserId()
        return createDriver(withFBUser: user, hyperTrackUserId: htUserId)
    }
    
    mutating func updateDriver(isOnRide: Bool?) {
        self.isOnRide = isOnRide
        DataService.instance.drivers.child(self.firebaseId).child("is_on_ride").setValue(isOnRide)
    }
    
    mutating func updateDriver(fromSnapshot snapshot: DataSnapshot) {
        if let dict = snapshot.value as? Dictionary<String, AnyObject> {
            if let isOnRide = dict["is_on_ride"] as? Bool {
                self.isOnRide = isOnRide
            } else {
                self.isOnRide = nil
            }
            if let name = dict["name"] as? String {
                self.name = name
            }
            //TODO: Rating integration
            //TODO: If name is changed, update to Hypertrack SDK user object.
        }
    }
    
    mutating func updateDriverOnTrip(onTrip: Bool) {
        DataService.instance.updateDriverOnRide(onRide: onTrip, forDriverId: self.firebaseId)
        self.isOnRide = onTrip
    }
    
    

}
