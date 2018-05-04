//
//  User.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 20/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import Firebase
import HyperTrack

struct User {
    let firebaseId: String
    let phone: String
    var name: String?
    let rating: Int?        //TODO: get it from firebase
    let imageUrl: String?
    var tripCollectionId: String?
}

enum UserKeys: String {
    case name = "userName"
}

extension User {
    
    static func createUser(withFBUser user: FirebaseAuth.User?) -> User? {
        if let phone = user?.phoneNumber, let firebaseId = user?.uid {
            let name = UserDefaults.standard.string(forKey: UserKeys.name.rawValue)
            let user = User.init(firebaseId: firebaseId, phone: phone, name: name, rating: nil, imageUrl: nil, tripCollectionId: nil)
            return user
        }
        return nil
    }
    
    static func defaultUser() -> User? {
        let user = Auth.auth().currentUser
        return createUser(withFBUser: user)
    }
    
    mutating func updateCollectionId(collectionId: String) {
        self.tripCollectionId = collectionId
        DataService.instance.updateTripCollectionId(forUser: self, collectionId: collectionId)
    }
    
    mutating func updateUser(fromFBSnapShot snapshot: DataSnapshot) {
        if let dict = snapshot.value as? Dictionary<String, AnyObject> {
            if let name = dict["name"] as? String {
                self.name = name
            }
            if let tripCollectionId = dict["trip_collection_id"] as? String {
                self.tripCollectionId = tripCollectionId
            }
        }
    }
    
    mutating func endTrip() {
        DataService.instance.deleteTripCollectionId(forUser: self)
        self.tripCollectionId = nil
    }
    
    
}
