//
//  DataService.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 11/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation

import Firebase
import FirebaseDatabase
import HyperTrack


typealias CompletionBlock           = (Bool, Error?) -> Void
typealias TripReceivedBlock         = (Trip?)        -> Void
typealias DriverDataReceivedBlock   = (DataSnapshot) -> Void

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
    
    func createDriver(uid: String, name: String, phone: String, carDetails: String, completionHandler: @escaping CompletionBlock) {
        let dict = prepareDriverDict(name: name, phone: phone, carDetails: carDetails)
        createFirebaseDriver(uid: uid, data: dict) { [weak self](isCreated, error) in
            if isCreated == false {
                completionHandler(isCreated, error)
            } else {
                self?.createHyperTrackDriver(uid: uid, name: name, phone: phone, completionHandler: completionHandler)
            }
        }
    }
    
    func delete(trip: Trip, forDriver driver: Driver, completionHandler: @escaping CompletionBlock) {
        trips.child(driver.firebaseId).removeValue { (error, ref) in
            if error == nil {
                completionHandler(true, error)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    func fetchDriverDetails(forDriverId driverId: String, completionHandler: @escaping (DataSnapshot) -> ()) {
        drivers.observeSingleEvent(of: DataEventType.value, with:  { (snapshot) in
            //TODO: What happen on network failure here ?
            completionHandler(snapshot)
        })
    }
    
    func updateTripCollectionId(forUserId userId: String, collectionId: String) {
        users.child(userId).child("trip_collection_id").setValue(collectionId)
    }
    
    func updateDriverOnRide(onRide: Bool, forDriverId driverId: String) {
        drivers.child(driverId).child("is_on_ride").setValue(onRide)
    }
    
    // MARK: Listeners
    
    func listenForTrip(forDriver driver: Driver, tripReceived: @escaping TripReceivedBlock) {
        _tripHandle = trips.child(driver.firebaseId).observe(.value, with: { (snapshot) in
            let trip = Trip.createTrip(fromSnapshot: snapshot)
            tripReceived(trip)
        })
        
    }
    
    func stopListeningForTrip() {
        if let tripHandle = _tripHandle {
            trips.removeObserver(withHandle: tripHandle)
            _tripHandle = nil
        }
    }
    
    // MARK: Private Methods
    
    private func createFirebaseDriver(uid: String, data: Dictionary<String, Any>, completionHandler: @escaping CompletionBlock) {
        drivers.child(uid).updateChildValues(data) { (error, ref) in
            if error == nil {
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    private func createHyperTrackDriver(uid: String, name: String, phone: String, completionHandler: @escaping CompletionBlock) {
        HyperTrack.getOrCreateUser(name: name, phone: phone, uniqueId: uid) { (user, error) in
            if user != nil {
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    private func prepareDriverDict(name: String, phone: String, carDetails: String) -> Dictionary<String, Any> {
        var dict = [String: Any]()
        dict["name"] = name
        dict["phone"] = phone
        dict["car_details"] = carDetails
        return dict
    }
    
}

