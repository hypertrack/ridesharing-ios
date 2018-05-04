//
//  Trip.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 13/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

struct Trip {
    //TODO: Refactoring
    // required
    let pickup:         Location
    let drop:           Location
    var isTripAccepted: Bool
    let userDetails:    UserDetails
    // optionals
    var hyperTrackInfo: HyperTrackActionInfo?
}


struct Location {
    let coordinate:     CLLocationCoordinate2D
    let displayAddress:  String?
}

struct HyperTrackActionInfo {
    let collectionId:   String
    var pickupActionId: String?
    var dropActionId:   String?
    // TODO: Hyper Track Parsing
}

struct UserDetails {
    let phone: String?
    let name: String
    let rating: Double?
    let imageUrl: String?
    let firebaseId: String
}

extension UserDetails {
    static func createUserDetails(fromUserDetailsDict dict: Dictionary<String, AnyObject>?) -> UserDetails? {
        guard let dict = dict else {
            return nil
        }
        guard let name = dict["name"] as? String,
              let fbId = dict["id"]  as? String else {
            return nil
        }
        let phone = dict["phone"] as? String
        let rating = dict["rating"] as? Double
        let imageUrl = dict["image_url"] as? String
        let userDetails = UserDetails(phone: phone, name: name, rating: rating, imageUrl: imageUrl, firebaseId: fbId)
        return userDetails
    }
}

extension HyperTrackActionInfo {
    static func createHyperTrackActionInfo(fromHyperTrackDict dict: Dictionary<String, AnyObject>?) -> HyperTrackActionInfo? {
        guard let dict = dict else {
            return nil
        }
        guard let collectionId = dict["collection_id"] as? String else {
            return nil
        }
        let pickup = dict["pickup_action_id"] as? String
        let drop   = dict["drop_action_id"] as? String
        
        let hyperTrackActionInfo = HyperTrackActionInfo(collectionId: collectionId, pickupActionId: pickup, dropActionId: drop)
        
        return hyperTrackActionInfo
    }
}

//TODO: User Object


extension Location {
    static func createLocation(fromLocationDict dict: Dictionary<String, AnyObject>?) -> Location? {
        guard  let dict = dict else {
            return nil
        }
        guard let coordinateDict = dict["coordinate"] as? Dictionary<String, Double>,
              let latitude  = coordinateDict["latitude"],
              let longitude = coordinateDict["longitude"]
        else {
            return nil
        }
        let displayAddress = dict["display_address"] as? String
        let location = Location(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), displayAddress: displayAddress)
        return location
    }
}

extension Trip {
    static func createTrip(fromSnapshot snapshot: DataSnapshot) -> Trip? {
        guard let tripDict = snapshot.value as? Dictionary<String, AnyObject> else {
            return nil
        }
        guard let pickup = Location.createLocation(fromLocationDict: tripDict["pickup"] as? Dictionary<String, AnyObject>),
            let drop   = Location.createLocation(fromLocationDict: tripDict["drop"] as? Dictionary<String, AnyObject>),
            let userDetails = UserDetails.createUserDetails(fromUserDetailsDict: tripDict["user_info"] as? Dictionary<String, AnyObject>)
            else {
                return nil
        }
        
        
        let isTripAccepted      = tripDict["trip_is_accepted"] as? Bool ?? false
        let htActionDict        = tripDict["hypertrack"] as? Dictionary<String, AnyObject>
        let htActionInfo        = HyperTrackActionInfo.createHyperTrackActionInfo(fromHyperTrackDict: htActionDict)
        
        let trip = Trip.init(pickup: pickup, drop: drop, isTripAccepted: isTripAccepted, userDetails: userDetails, hyperTrackInfo: htActionInfo)
        return trip
    }
    
    func updateDriverInfo(forDriverId driverId: String, forName name: String, forCarDetails carDetails: String) {
        let path = driverId + "/" + "driver_info"
        var dict = Dictionary<String, AnyObject>()
        dict["name"] = name as AnyObject
        dict["car_details"] = carDetails as AnyObject
        DataService.instance.trips.child(path).setValue(dict)
    }
    
    mutating func updateAcceptTrip(forCollectionId collectionId: String, pickupActionId actionId: String, driverId: String) {
        let path = driverId + "/" + "hypertrack"
        var dict = Dictionary<String, AnyObject>()
        dict["collection_id"] = collectionId as AnyObject
        dict["pickup_action_id"] = actionId as AnyObject
        // TODO: Do we need completion closure ?
        DataService.instance.trips.child(path).setValue(dict)
        self.hyperTrackInfo = HyperTrackActionInfo(collectionId: collectionId, pickupActionId: actionId, dropActionId: nil)
    }
    
    mutating func updateStartTrip(forDropActionId actionId: String, driverId: String) {
        let path = driverId + "/" + "hypertrack" + "/drop_action_id"
//        var dict = Dictionary<String, AnyObject>()
//        dict["collection_id"] = collectionId as AnyObject
//        dict["drop_action_id"] = actionId as AnyObject
        // TODO: Do we need completion closure ?
        DataService.instance.trips.child(path).setValue(actionId)
        self.hyperTrackInfo?.dropActionId = actionId
        //self.hyperTrackInfo = HyperTrackActionInfo(collectionId: collectionId, pickupActionId: actionId, dropActionId: nil)
    }
    
}
