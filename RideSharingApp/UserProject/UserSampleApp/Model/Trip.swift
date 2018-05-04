//
//  Trip.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 23/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation

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
    var driverDetails: DriverDetails?
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
    let htId: String
}

struct DriverDetails {
    let name: String
    let carDetails: String
}

extension UserDetails {
    static func createUserDetails(fromUserDetailsDict dict: Dictionary<String, AnyObject>?) -> UserDetails? {
        guard let dict = dict else {
            return nil
        }
        guard let name = dict["name"] as? String,
            let htId = dict["id"]  as? String else {
                return nil
        }
        let phone = dict["phone"] as? String
        let rating = dict["rating"] as? Double
        let imageUrl = dict["image_url"] as? String
        let userDetails = UserDetails(phone: phone, name: name, rating: rating, imageUrl: imageUrl, htId: htId)
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
    
    func firebaseData() -> Dictionary<String, AnyObject> {
        var dict: [String: AnyObject] = [:]
        let coordinate : [String: Double] = ["latitude": self.coordinate.latitude, "longitude": self.coordinate.longitude]
        
        dict["coordinate"] = coordinate as AnyObject
        if let displayAddress = self.displayAddress {
            dict["display_address"] = displayAddress as AnyObject
        }
        
        return dict
    }
}

extension DriverDetails {
    static func createDriverDetails(fromDriverDetailsDict dict: Dictionary<String, AnyObject>?) -> DriverDetails? {
        guard let dict = dict else {
            return nil
        }
        guard let name = dict["name"] as? String, let carDetails = dict["car_details"] as? String else {
            return nil
        }
        let driverDetails = DriverDetails(name: name, carDetails: carDetails)
        return driverDetails
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
        let driverDetailsDict   = tripDict["driver_info"] as? Dictionary<String, AnyObject>
        let driverDetails       = DriverDetails.createDriverDetails(fromDriverDetailsDict: driverDetailsDict)
        
        let trip = Trip.init(pickup: pickup, drop: drop, isTripAccepted: isTripAccepted, userDetails: userDetails, hyperTrackInfo: htActionInfo, driverDetails: driverDetails)
        return trip
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
