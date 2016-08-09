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
            user.downloadUserInfo(){
                print(self.user.displayName)
                completion()
            }
        }
    }
    
}

func sendNotification(toUserUid: String, hasSound: Bool, groupId: String, message: String, deeplink: String){
    if let pushClient = BatchClientPush(apiKey: BATCH_DEV_API_KEY, restKey: BATCH_REST_KEY) {
        
        getNumberOfNotifications(toUserUid){ (sum) in
            pushClient.sandbox = false
            if hasSound {
                pushClient.customPayload = ["aps": ["badge": sum, "content-available": 1]]
            } else {
                pushClient.customPayload = ["aps": ["badge": sum, "sound": NSNull(), "content-available": 1]]
            }
            pushClient.groupId = groupId
            pushClient.message.title = "Friendlies"
            pushClient.message.body = message
            pushClient.recipients.customIds = [toUserUid]
            pushClient.deeplink = deeplink
            
            pushClient.send { (response, error) in
                if let error = error {
                    print("Something happened while sending the push: \(response) \(error.localizedDescription)")
                } else {
                    print("Push sent \(response)")
                }
            }
        }
        
    } else {
        print("Error while initializing BatchClientPush")
    }
}