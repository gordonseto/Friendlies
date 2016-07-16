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
    private var _broadcastDesc: String!
    private var _hasSetup: Bool!
    private var _geolocation: CLLocation!
    private var _time: NSTimeInterval!
    
    var firebase: FIRDatabaseReference!
    
    var key: String {
        return _key
    }
    
    var authorUid: String {
        return _authorUid
    }
    
    var author: User {
        return _author
    }
    
    var broadcastDesc: String {
        return _broadcastDesc
    }
    
    var hasSetup: Bool {
        return _hasSetup
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
        _broadcastDesc = broadcastDesc
        _hasSetup = hasSetup
        _geolocation = geolocation
        _time = time
    }
    
    func sendBroadcast(){
        firebase = FIRDatabase.database().reference()
    }
}