//
//  TripWorker.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 20/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import HyperTrack


//TODO: Single closure
typealias TripStartedSuccess = (HTAction) -> ()
typealias TripFail = (HTError?) -> ()

typealias TripCompleted = (success: Bool, error: HTError?)
typealias TripCompletedClosure = (TripCompleted) -> ()

class TripWorker {
    
    func startTrip(forCollectionId collectionId: String, trip: Trip, pickupActionId: String, successClosure: @escaping TripStartedSuccess, failureClosure: @escaping TripFail) {
        let params = HTActionParams.default
        params.type = "Drop"
        params.userId = HyperTrack.getUserId()
        params.collectionId = collectionId
        // TODO: action id to lookup.
        
        //2.2 Create Pickup place
        let placeBuilder = HTPlaceBuilder.init()
        _ = placeBuilder.setLocation(trip.drop.coordinate)
        if let displayAddress = trip.drop.displayAddress {
            _ = placeBuilder.setAddress(displayAddress)
        }
        
        let expectedPlace = placeBuilder.build()
        params.expectedPlace = expectedPlace
        
        //2.3 Create and assign Action
        HyperTrack.createAction(params) { (action, error) in
            //3. On Success
            if let dropAction = action {
                HyperTrack.completeActionInSync(pickupActionId, completionHandler: { (action, error) in
                    if let _ = action {
                        successClosure(dropAction)
                    } else {
                        failureClosure(error)
                    }
                })
            } else {
                failureClosure(error)
            }
        }
    }
    
    func endTrip(forCollectionId collectionId: String, trip: Trip, dropActionId: String?, completionClosure: @escaping TripCompletedClosure) {
        if let actionId = dropActionId {
            HyperTrack.completeActionInSync(actionId) { (action, error) in
                var success = false
                if let action = action {
                    success = (action.status == "completed") ? true : false
                }
                completionClosure(TripCompleted(success: success, error: error))
            }
        } else {
            completionClosure(TripCompleted(success: true, error: nil))
        }
    }
    
}
