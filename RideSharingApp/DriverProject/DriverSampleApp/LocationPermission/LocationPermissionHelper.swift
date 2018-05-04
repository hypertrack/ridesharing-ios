//
//  LocationPermissionHelper.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 30/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import HyperTrack

typealias LocationPermissionClosure = (_ success: Bool) -> ()

class LocationPermissionHelper {

    static func locationPermissionStatus(completionHandler: @escaping (LocationPermissionClosure)) {
        if (!HyperTrack.locationServicesEnabled()) {
            // Location permission OS level check
            completionHandler(false)
        } else if (HyperTrack.locationAuthorizationStatus() != .authorizedAlways) {
            // APP Specific Check
            completionHandler(false)
        } else {
            // Motion Check
            if(HyperTrack.isActivityAvailable()){
                // Motion Data Available On Device
                HyperTrack.motionAuthorizationStatus(completionHandler: { (authorized) in
                    if(!authorized){
                        completionHandler (false)
                    }
                })
            }
        }
    }
    
}
