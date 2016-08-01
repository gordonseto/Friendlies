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

class CurrentUser {
    
    var user: User!
    var firebase: FIRDatabaseReference!
    
    static let sharedInstance = CurrentUser()
    private init() {}
    
    func getCurrentUser(completion: ()->()){
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String{
            user = User(uid: uid)
            user.downloadUserInfo(){
                print(self.user.displayName)
                completion()
            }
        }
    }
    
    func sendAddRequestToUser(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            let time = NSDate().timeIntervalSince1970
            firebase.child("friendsInfo").child(user.uid).child("wantsToAdd").child(uid).setValue(true)
            firebase.child("friendsInfo").child(uid).child("wantsToBeAddedBy").child(user.uid).setValue("unseen")
            self.sendFriendNotification("\(self.user.displayName) has sent you a friend request.", uid: uid)
            addToNotifications(uid, notificationType: "friends", param1: self.user.uid)
            self.user.downloadUserInfo(){
                self.user.getFriendsInfo(){
                    completion()
                }
            }
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
    
    func sendFriendNotification(message: String, uid: String){
        if let pushClient = BatchClientPush(apiKey: BATCH_DEV_API_KEY, restKey: BATCH_REST_KEY) {
            
            getNumberOfNotifications(uid){ (sum) in
                pushClient.sandbox = false
                pushClient.customPayload = ["aps": ["badge": sum, "sound": NSNull(), "content-available": 1]]
                pushClient.groupId = "friendNotifications"
                pushClient.message.title = "Friendlies"
                pushClient.message.body = message
                pushClient.recipients.customIds = [uid]
                pushClient.deeplink = "friendlies://friends/\(uid)"
                
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
    
    /*
    func addConversationToUnreadMessages(conversationId: String) {
        firebase = FIRDatabase.database().reference()
        if let uid = user.uid {
            firebase.child("userInfos").child(uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var userInfo = currentData.value as? [String: AnyObject] {
                var unreadConversations = user["unreadConversations"] as? [String] ?? []
                if wantsToBeAddedBy.contains(uid) {
                    self.acceptAddRequest(uid){
                        self.user.downloadUserInfo(){
                            completion()
                        }
                    }
                } else {
                    var wantsToAdd = user["wantsToAdd"] as? [String] ?? []
                    print(wantsToAdd)
                    wantsToAdd.append(uid)
                    user["wantsToAdd"] = wantsToAdd
                    print("wants to add after: \(user["wantsToAdd"])")
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
            }
            return FIRTransactionResult.successWithValue(currentData)
            }, andCompletionBlock: { (error, committed, snapshot) in
                if let error = error {
                    print(error.localizedDescription)
                    print("WANTS TO ADD FAILED")
                }
            })
        }
    }
 */

}