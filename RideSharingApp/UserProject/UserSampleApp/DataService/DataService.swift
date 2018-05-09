//
//  DataService.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 20/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation

import Firebase
import FirebaseDatabase
import HyperTrack


typealias TripResult = (success: Bool, trip: Trip?, driverId: String?)
typealias CompletionBlock           = (Bool, Error?) -> Void
typealias TripReceivedBlock         = (TripResult)   -> Void

let base = Database.database().reference()

class DataService: NSObject {
    static let instance = DataService()
    
    private var _ref = base
    private var _drivers = base.child("drivers")
    private var _trips = base.child("trips")
    private var _users = base.child("users")
    
    private var _tripHandle: DatabaseHandle? = nil
    
    var ref: DatabaseReference {
        return _ref
    }
    
    var drivers: DatabaseReference {
        return _drivers
    }
    
    var trips: DatabaseReference {
        return _trips
    }
    
    var users: DatabaseReference {
        return _users
    }
    
    // MARK: Create Operations
    
    func createUser(uid: String, name: String, phone: String, completionHandler: @escaping CompletionBlock) {
        let dict = prepareUserDict(name: name, phone: phone)
        createFirebaseUser(uid: uid, data: dict) {(isCreated, error) in
            completionHandler(isCreated, error)
        }
    }
    
    func updateTripCollectionId(forUser user: User, collectionId: String) {
        users.child(user.firebaseId).updateChildValues(["trip_collection_id": collectionId])
    }
    
    func deleteTripCollectionId(forUser user: User) {
        users.child(user.firebaseId).child("trip_collection_id").removeValue()
    }
    
    func observeUser(forUser user: User, completionColsure: @escaping (DataSnapshot) -> ()) {
        users.child(user.firebaseId).observe(.value, with: { (snapshot) in
            completionColsure(snapshot)
        })
    }
    
    func findDriver(forPickup pickup: Location, drop: Location, user: User, completionColsure: @escaping TripReceivedBlock) {
        //TODO: Logic improvement
        var tripResult = TripResult(success: false, trip: nil, driverId: nil)
        drivers.observeSingleEvent(of: .value, with: { (snapshot) in
            let drivers = snapshot.value as? [String : NSDictionary] ?? [:]
            var driverId: String? = nil
            var driverName: String? = nil
            var carDetails: String? = nil
            var driverPhone: String? = nil
            for driver in drivers {
                let driverDict = driver.value
                let isOnRide = driverDict.value(forKey: "is_on_ride") as? Bool ?? false
                let phone    = driverDict.value(forKey: "phone") as? String ?? ""
                // For development environment, and easy testing
                // making one to one mapping of driver and rider
                // poking only that driver which has same phone no as user
                // set this value as true
                let searchSameNumber = false
                if isOnRide == false {
                    // driver which is not on ride found
                    if searchSameNumber == true {
                        if phone == user.phone {
                            // our driver found
                            driverId = driver.key
                            driverName = driverDict.value(forKey: "name") as? String
                            carDetails = driverDict.value(forKey: "car_details") as? String
                            driverPhone = phone
                            break
                        }
                    } else {
                        // our driver found
                        driverId = driver.key
                        driverName = driverDict.value(forKey: "name") as? String
                        carDetails = driverDict.value(forKey: "car_details") as? String
                        driverPhone = phone
                        break
                    }
                }
            }
            if driverId == nil {
                completionColsure(tripResult)
                return
            }
            // poke him
            // create a trip object
            let tripDict = self.tripDict(forPickup: pickup, drop: drop, user: user, driverName: driverName, carDetails: carDetails, driverPhone: driverPhone)
            // save the trip details in firebase
            self.trips.child(driverId!).updateChildValues(tripDict, withCompletionBlock: { (error, ref) in
                if let _ = error {
                    completionColsure(tripResult)
                    return
                }
                // trip object is created, driver is poked, now wait for driver to accept it
                self._tripHandle = self.trips.child(driverId!).observe(.value, with: { (snapshot) in
                    // driver accepted it
                    // TODO: More condition checks to ensure driver has accepted the trip
                    let trip = Trip.createTrip(fromSnapshot: snapshot)
                    if let trip = trip, trip.hyperTrackInfo?.collectionId != nil, trip.hyperTrackInfo?.pickupActionId != nil {
                        self.stopListeningForTrip()
                        tripResult.success = true
                        tripResult.trip = trip
                        tripResult.driverId = driverId
                        completionColsure(tripResult)
                    }
                })
            })
        })
    }
    
    func stopListeningForTrip() {
//        if let tripHandle = _tripHandle {
//            trips.removeObserver(withHandle: tripHandle)
//            _tripHandle = nil
//        }
        trips.removeAllObservers()
    }
    
    func listenForTrip(forDriverId driverId: String, tripReceived: @escaping TripReceivedBlock) {
        _tripHandle = trips.child(driverId).observe(.value, with: { (snapshot) in
            let trip = Trip.createTrip(fromSnapshot: snapshot)
            let result = TripResult(success: false, trip: trip, driverId: driverId)
            tripReceived(result)
        })
    }
    
    
    private func tripDict(forPickup pickup: Location, drop: Location, user: User, driverName: String?, carDetails: String?, driverPhone: String?) -> Dictionary<String, AnyObject> {
        var dict: [String: AnyObject] = [:]
        dict["pickup"] = pickup.firebaseData() as AnyObject
        dict["drop"] = drop.firebaseData() as AnyObject
        
        var userInfoDict: [String: AnyObject] = [:]
        /*
         user_info
         guard let name = dict["name"] as? String,
         let htId = dict["id"]  as? String else {
         return nil
         }
         let phone = dict["phone"] as? String
         let rating = dict["rating"] as? Double
         let imageUrl = dict["image_url"] as? String
         */
        let name = user.name ?? ""
        userInfoDict["name"] = name as AnyObject
        userInfoDict["id"] = user.firebaseId as AnyObject
        userInfoDict["phone"] = user.phone as AnyObject
        //TODO: Rating and imageUrl Integrationuse
        dict["user_info"] = userInfoDict as AnyObject
        
        var driverInfoDict : Dictionary<String, AnyObject> = [:]
        if let name = driverName {
            driverInfoDict["name"] = name as AnyObject
        }
        if let carDetails = carDetails {
            driverInfoDict["car_details"] = carDetails as AnyObject
        }
        if let phone = driverPhone {
            driverInfoDict["phone"] = phone as AnyObject
        }
        
        dict["driver_info"] = driverInfoDict as AnyObject
        
        return dict
    }
    
    // MARK: Listeners
    
    
    
    // MARK: Private Methods
    private func createFirebaseUser(uid: String, data: Dictionary<String, Any>, completionHandler: @escaping CompletionBlock) {
        users.child(uid).updateChildValues(data) { (error, ref) in
            if error == nil {
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    private func prepareUserDict(name: String, phone: String) -> Dictionary<String, Any> {
        var dict = [String: Any]()
        dict["name"] = name
        dict["phone"] = phone
        return dict
    }
    
}
