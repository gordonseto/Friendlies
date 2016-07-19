//
//  Broadcast.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-16.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

class Broadcast {
    
    private var _key: String!
    private var _authorUid: String!
    private var _author: User!
    private var _geolocation: CLLocation!
    private var _time: NSTimeInterval!
    
    var hasSetup: Bool = false
    var broadcastDesc: String = ""
    var user: User!
    
    var firebase: FIRDatabaseReference!
    
    var key: String {
        return _key
    }
    
    var authorUid: String {
        return _authorUid
    }
    
    var geolocation: CLLocation {
        return _geolocation
    }
    
    var time: NSTimeInterval {
        return _time
    }
    
    init(key: String, authorUid: String, broadcastDesc: String, hasSetup: Bool, geolocation: CLLocation, time: NSTimeInterval) {
        _key = key
        _authorUid = authorUid
        self.broadcastDesc = broadcastDesc
        self.hasSetup = hasSetup
        _geolocation = geolocation
        _time = time
    }
    
    func getUser(completion: ()->()){
        if let authoruid = _authorUid {
            user = User(uid: authoruid)
            user.downloadUserInfo() {
                completion()
            }
        }
    }
    
}