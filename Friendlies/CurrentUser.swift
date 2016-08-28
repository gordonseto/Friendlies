//
//  currentUser.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-18.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Batch
import FirebaseAuth

class CurrentUser {
    
    var user: User!
    var firebase: FIRDatabaseReference!
    
    var isLoggedIn: Bool {
        if let _ = FIRAuth.auth()?.currentUser?.uid {
            return true
        } else {
            return false
        }
    }
    
    static let sharedInstance = CurrentUser()
    private init() {}
    
    func getCurrentUser(completion: ()->()){
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            user = User(uid: uid)
            user.downloadUserInfo(){ user in
                if let _ = user.displayName {
                    print(user.displayName)
                    completion()
                }
            }
        }
    }
    
}