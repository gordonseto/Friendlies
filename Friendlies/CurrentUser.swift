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
    
    func checkFriendStatus(uid: String, completion: (FriendsStatus)->()){
        if let user = user {
            user.getFriendsInfo(){
                self.user = user
                var friendsStatus: FriendsStatus!
                if let friends = user.friends {
                    if let wantsToAdd = user.wantsToAdd {
                        if let wantsToBeAddedBy = user.wantsToBeAddedBy {
                            if friends[uid] != nil {
                                friendsStatus = FriendsStatus.Friends
                            } else if wantsToAdd[uid] != nil {
                                friendsStatus = FriendsStatus.WantsToAdd
                            } else if wantsToBeAddedBy[uid] != nil {
                                friendsStatus = FriendsStatus.WantsToBeAddedBy
                            } else {
                                friendsStatus = FriendsStatus.NotFriends
                            }
                            completion(friendsStatus)
                        }
                    }
                }
            }
        }
    }
    
    func sendAddRequestToUser(uid: String, completion: ()->()){
        if let user = user {
            checkFriendStatus(uid, completion: {(friendsStatus) in
                if friendsStatus == FriendsStatus.WantsToBeAddedBy {
                    self.acceptAddRequest(uid){
                        completion()
                    }
                } else {
                    self.firebase = FIRDatabase.database().reference()
                    let time = NSDate().timeIntervalSince1970
                    self.firebase.child("friendsInfo").child(user.uid).child("wantsToAdd").child(uid).setValue(true)
                    self.firebase.child("friendsInfo").child(uid).child("wantsToBeAddedBy").child(user.uid).setValue("unseen")
                    self.sendFriendNotification("\(self.user.displayName) has sent you a friend request.", uid: uid)
                    addToNotifications(uid, notificationType: "friends", param1: self.user.uid)
                    self.user.downloadUserInfo(){
                        self.user.getFriendsInfo(){
                            completion()
                        }
                    }
                }
            })
        }
    }
    
    func cancelAddRequest(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("friendsInfo").child(user.uid).child("wantsToAdd").child(uid).setValue(nil)
            firebase.child("friendsInfo").child(uid).child("wantsToBeAddedBy").child(user.uid).setValue(nil)
            self.user.downloadUserInfo(){
                self.user.getFriendsInfo(){
                    completion()
                }
            }
        }
    }
    
    func acceptAddRequest(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("friendsInfo").child(user.uid).child("friends").child(uid).setValue(true)
            firebase.child("friendsInfo").child(uid).child("friends").child(user.uid).setValue(true)
            firebase.child("friendsInfo").child(uid).child("wantsToAdd").child(user.uid).setValue(nil)
            firebase.child("friendsInfo").child(user.uid).child("wantsToBeAddedBy").child(uid).setValue(nil)
            self.sendFriendNotification("\(self.user.displayName) has accepted your friend request.", uid: uid)
            addToNotifications(uid, notificationType: "friends", param1: self.user.uid)
            removeFromNotifications(self.user.uid, notificationType: "friends", param1: uid)
            self.user.downloadUserInfo(){
                self.user.getFriendsInfo(){
                    completion()
                }
            }
        }
    }
    
    func removeUser(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("friendsInfo").child(user.uid).child("friends").child(uid).setValue(nil)
            firebase.child("friendsInfo").child(uid).child("friends").child(user.uid).setValue(nil)
            self.user.downloadUserInfo(){
                self.user.getFriendsInfo(){
                    completion()
                }
            }
        }
    }
    
    func hideAddRequest(uid: String, completion: ()->()) {
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("friendsInfo").child(user.uid).child("wantsToBeAddedBy").child(uid).setValue("seen")
            completion()
        }
    }
    
    func followUser(uid: String, completion: ()->()){
        if let user = user {
            guard self.user.uid != nil else { return }
            firebase = FIRDatabase.database().reference()
            firebase.child("followInfo").child(uid).child("followers").child(user.uid).setValue(true)
            completion()
        }
    }
    
    func unFollowUser(uid: String, completion: ()->()) {
        if let user = user {
            guard self.user.uid != nil else { return }
            firebase = FIRDatabase.database().reference()
            firebase.child("followInfo").child(uid).child("followers").child(user.uid).setValue(nil)
            completion()
        }
    }
    
    func sendFriendNotification(message: String, uid: String){
        sendNotification(uid, hasSound: false, groupId: "friendNotifications", message: message, deeplink: "friendlies://friends/\(self.user.uid)")
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