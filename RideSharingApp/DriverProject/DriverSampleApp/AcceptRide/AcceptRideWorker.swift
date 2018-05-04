//
//  AcceptRideWorker.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 16/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import Firebase
import HyperTrack
import CoreLocation

typealias AcceptRideSuccessTouple = (collectionId: String, actionId: String)
typealias AcceptRideSuccessClosure = ((AcceptRideSuccessTouple) -> ())
typealias AcceptRideFailureClosure = ((HTError?) -> ())


class AcceptRiderWorker: NSObject {
    
    func acceptRide(forTrip trip:Trip, successClosure: @escaping AcceptRideSuccessClosure, failureClosure: @escaping AcceptRideFailureClosure) {
        //1. Create Collection id
        let collectionId = UUID().uuidString
        
        //2. HT SDK Create action
        
        //2.1 Create Params
        let params = HTActionParams.default
        params.type = "Pickup"
        params.userId = HyperTrack.getUserId()
        params.collectionId = collectionId
        // TODO: action id to lookup.
        
        //2.2 Create Pickup place
        let placeBuilder = HTPlaceBuilder.init()
        _ = placeBuilder.setLocation(trip.pickup.coordinate)
        if let displayAddress = trip.pickup.displayAddress {
            _ = placeBuilder.setAddress(displayAddress)
        }
        //TODO: Set City, Country, Name
//        _ = placeBuilder.setCity("Bengaluru")
//        _ = placeBuilder.setCountry("India")
//        _ = placeBuilder.setName("Kota Kachori")
        let expectedPlace = placeBuilder.build()
        params.expectedPlace = expectedPlace
        
        //2.3 Create and assign Action
        HyperTrack.createAction(params) { (action, error) in
            //3. On Success
            if let action = action {
                successClosure(collectionId: collectionId, actionId: action.id)
            } else {
                failureClosure(error)
            }
        }
    }
}



