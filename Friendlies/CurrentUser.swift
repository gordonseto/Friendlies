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
            firebase.child("users").child(user.uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    if wantsToBeAddedBy.contains({$0[uid] != nil}) {
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
            firebase.child("users").child(uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    print(wantsToBeAddedBy)
                    wantsToBeAddedBy.append([self.user.uid: "unseen"])
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    print("wants to be added by after: \(user["wantsToBeAddedBy"])")
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
                    self.sendFriendNotification("\(self.user.displayName) has sent you a friend request.", uid: uid)
                    addToNotifications(uid, notificationType: "friends", param1: self.user.uid)
                    self.user.downloadUserInfo(){
                        completion()
                    }
            })
        }
    }
    
    func cancelAddRequest(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("users").child(user.uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToAdd = user["wantsToAdd"] as? [String] ?? []
                    print(wantsToAdd)
                    wantsToAdd = wantsToAdd.filter({$0 != uid})
                    user["wantsToAdd"] = wantsToAdd
                    print("wants to add after: \(user["wantsToAdd"])")
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
            })
            firebase.child("users").child(uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    print(wantsToBeAddedBy)
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0[self.user.uid] == nil})
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    print("wants to be added by after: \(user["wantsToBeAddedBy"])")
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
                    self.user.downloadUserInfo(){
                        completion()
                    }
            })
        }
    }
    
    func acceptAddRequest(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("users").child(user.uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0[uid] == nil})
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    var friends = user["friends"] as? [String] ?? []
                    if !friends.contains(uid){
                        friends.append(uid)
                    }
                    user["friends"] = friends
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
            })
            firebase.child("users").child(uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToAdd = user["wantsToAdd"] as? [String] ?? []
                    wantsToAdd = wantsToAdd.filter({$0 != self.user.uid})
                    user["wantsToAdd"] = wantsToAdd
                    var friends = user["friends"] as? [String] ?? []
                    if !friends.contains(self.user.uid) {
                        friends.append(self.user.uid)
                    }
                    user["friends"] = friends
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
                    self.sendFriendNotification("\(self.user.displayName) has accepted your friend request.", uid: uid)
                    addToNotifications(uid, notificationType: "friends", param1: self.user.uid)
                    removeFromNotifications(self.user.uid, notificationType: "friends", param1: uid)
                    self.user.downloadUserInfo(){
                        completion()
                    }
            })
        }
    }
    
    func removeUser(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("users").child(user.uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var friends = user["friends"] as? [String] ?? []
                    friends = friends.filter({$0 != uid})
                    user["friends"] = friends
                    var wantsToAdd = user["wantsToAdd"] as? [String] ?? []
                    wantsToAdd = wantsToAdd.filter({$0 != uid})
                    user["wantsToAdd"] = wantsToAdd
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0[uid] == nil})
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
            })
            firebase.child("users").child(uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var friends = user["friends"] as? [String] ?? []
                    friends = friends.filter({$0 != self.user.uid})
                    user["friends"] = friends
                    var wantsToAdd = user["wantsToAdd"] as? [String] ?? []
                    wantsToAdd = wantsToAdd.filter({$0 != self.user.uid})
                    user["wantsToAdd"] = wantsToAdd
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0[self.user.uid] == nil})
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
                    self.user.downloadUserInfo(){
                        completion()
                    }
            })
        }
    }
    
    func hideAddRequest(uid: String, completion: ()->()) {
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("users").child(user.uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [[String: String]] ?? [[String:String]]()
                    if let index = wantsToBeAddedBy.indexOf({$0[uid] != nil}) {
                        wantsToBeAddedBy[index][uid] = "seen"
                    }
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    currentData.value = user
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
                }, andCompletionBlock: { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("WANTS TO ADD FAILED")
                    }
                    removeFromNotifications(uid, notificationType: "friends", param1: self.user.uid)
                    self.user.downloadUserInfo(){
                        completion()
                    }
            })
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