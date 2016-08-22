//
//  User.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class User {
    
    var facebookId: String!
    var profilePhoto: UIImage!
    var displayName: String!
    private var _uid: String!
    private var _gamerTag: String!
    private var _characters: [String]!
    private var _lastAvailable: NSTimeInterval!
    private var _friends: [String: Bool]!
    private var _wantsToAdd: [String: Bool]!
    private var _wantsToBeAddedBy: [String: String]!
    private var _conversations: [String: Bool]!
    private var _followers: [String: Bool]!
    private var _isBlockedBy: [String: Bool]!
    private var _isBlocking: [String: Bool]!
    private var _onlyFriends: Bool!
    
    var firebase: FIRDatabaseReference!
    
    var uid: String! {
        return _uid
    }
    
    var gamerTag: String! {
        return _gamerTag
    }
    
    var characters: [String]! {
        return _characters
    }
    
    var lastAvailable: NSTimeInterval! {
        return _lastAvailable
    }
    
    var friends: [String: Bool]! {
        return _friends
    }
    
    var wantsToAdd: [String: Bool]! {
        return _wantsToAdd
    }
    
    var wantsToBeAddedBy: [String: String]! {
        return _wantsToBeAddedBy
    }
    
    var conversations: [String: Bool]! {
        return _conversations
    }
    
    var followers: [String: Bool]! {
        return _followers
    }
    
    var isBlocking: [String: Bool]! {
        return _isBlocking
    }

    var isBlockedBy: [String: Bool]! {
        return _isBlockedBy
    }
    
    var totalBlocked: [String: Bool]! {
        var totalBlocked = _isBlockedBy
        for key in _isBlocking.keys {
            totalBlocked[key] = _isBlocking[key]
        }
        return totalBlocked
    }
    
    var onlyFriends: Bool! {
        if _onlyFriends == nil { return false }
        return _onlyFriends
    }
    
    var shouldSeeLastAvailable: Bool = false
    
    var lastBroadcast: String!
    
    init(uid: String) {
        _uid = uid
    }
    
    func downloadUserInfo(completion: () -> ()) {
        guard let uid = _uid else { return }
        firebase = FIRDatabase.database().reference()
        firebase.child("users").child(uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            print(snapshot)
            self.displayName = snapshot.value!["displayName"] as? String ?? ""
            self._gamerTag = snapshot.value!["gamerTag"] as? String ?? ""
            self._characters = snapshot.value!["characters"] as? [String] ?? []
            self.facebookId = snapshot.value!["facebookId"] as? String ?? ""
            self._lastAvailable = snapshot.value!["lastAvailable"] as? NSTimeInterval ?? nil
            self._conversations = snapshot.value!["conversations"] as? [String: Bool] ?? [:]
            self._onlyFriends = snapshot.value!["onlyFriends"] as? Bool ?? false
            self.lastBroadcast = snapshot.value!["lastBroadcast"] as? String ?? "123"
            print("downloaded \(self.displayName)")
            completion()
        }) { (error) in
            print("error retreiving user")
            completion()
        }
    }
    
    func getFriendsInfo(completion: () -> ()) {
        guard let uid = _uid else { return }
        firebase = FIRDatabase.database().reference()
        firebase.child("friendsInfo").child(uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            print(snapshot)
            self._friends = snapshot.value!["friends"] as? [String: Bool] ?? [:]
            self._wantsToAdd = snapshot.value!["wantsToAdd"] as? [String: Bool] ?? [:]
            self._wantsToBeAddedBy = snapshot.value!["wantsToBeAddedBy"] as? [String: String] ?? [:]
            completion()
        })
    }
    
    func getFollowers(completion: ()->()){
        guard let uid = _uid else { return }
        firebase = FIRDatabase.database().reference()
        firebase.child("followInfo").child(uid).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            print(snapshot)
            self._followers = snapshot.value!["followers"] as? [String: Bool] ?? [:]
            completion()
        })
    }
    
    func getBlockedInfo(completion: ()->()){
        guard let uid = _uid else { return }
        firebase = FIRDatabase.database().reference()
        firebase.child("blockInfo").child(uid).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            print(snapshot)
            self._isBlockedBy = snapshot.value!["isBlockedBy"] as? [String: Bool] ?? [:]
            self._isBlocking = snapshot.value!["isBlocking"] as? [String: Bool] ?? [:]
            completion()
        })
    }
    
    func getUserProfilePhoto(completion: () -> ()) {
        if let facebookid = facebookId {
            let url = NSURL(string: "http://graph.facebook.com/\(facebookid)/picture?type=large")
            
            downloadImage(url!) {
                print("downloaded \(self.displayName)'s photo")
                completion()
            }
        }
    }
    
    func checkIfShouldBeAbleToSeeUserDetails(user: User, completion: (Bool)->()) {
        if user.uid == self._uid {
            completion(true)
        } else if user.onlyFriends! {
            user.getFriendsInfo(){
                if user.friends[self._uid] != nil {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        } else {
            completion(true)
        }
    }
    
    func downloadImage(url: NSURL, completion: () -> ()){
        getDataFromUrl(url) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                self.profilePhoto = UIImage(data: data)
                completion()
            }
        }
    }
    
    func getDataFromUrl(url: NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)){
        
        NSURLSession.sharedSession().dataTaskWithURL(url){ (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func addActivity(uid: String){
        let firebase = FIRDatabase.database().reference()
        
        if let uid = self._uid {
            let newActivityRef = firebase.child("activity").child(self._uid).childByAutoId()
            let time = NSDate().timeIntervalSince1970
            let activity = ["uid": uid, "time": time]
            newActivityRef.setValue(activity)
        }
    }
    
    func checkFriendStatus(uid: String, completion: (FriendsStatus)->()){
        getFriendsInfo(){
            var friendsStatus: FriendsStatus!
            if let friends = self._friends {
                if let wantsToAdd = self._wantsToAdd {
                    if let wantsToBeAddedBy = self._wantsToBeAddedBy {
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
    
    func sendAddRequestToUser(uid: String, completion: ()->()){
        checkFriendStatus(uid, completion: {(friendsStatus) in
                if friendsStatus == FriendsStatus.WantsToBeAddedBy {
                    self.acceptAddRequest(uid){
                        completion()
                    }
                } else {
                    self.firebase = FIRDatabase.database().reference()
                    let time = NSDate().timeIntervalSince1970
                    self.firebase.child("friendsInfo").child(self._uid).child("wantsToAdd").child(uid).setValue(true)
                    self.firebase.child("friendsInfo").child(uid).child("wantsToBeAddedBy").child(self._uid).setValue("unseen")
                    self.sendFriendNotification("\(self.displayName) has sent you a friend request.", uid: uid)
                    addToNotifications(uid, notificationType: "friends", param1: self._uid)
                    self.downloadUserInfo(){
                        self.getFriendsInfo(){
                            completion()
                        }
                    }
                }
            })
    }
    
    func cancelAddRequest(uid: String, completion: ()->()){
        firebase = FIRDatabase.database().reference()
        firebase.child("friendsInfo").child(_uid).child("wantsToAdd").child(uid).setValue(nil)
        firebase.child("friendsInfo").child(uid).child("wantsToBeAddedBy").child(_uid).setValue(nil)
        self.downloadUserInfo(){
            self.getFriendsInfo(){
                completion()
            }
        }
    }
    
    func acceptAddRequest(uid: String, completion: ()->()){
        firebase = FIRDatabase.database().reference()
        firebase.child("friendsInfo").child(_uid).child("friends").child(uid).setValue(true)
        firebase.child("friendsInfo").child(uid).child("friends").child(_uid).setValue(true)
        firebase.child("friendsInfo").child(uid).child("wantsToAdd").child(_uid).setValue(nil)
        firebase.child("friendsInfo").child(_uid).child("wantsToBeAddedBy").child(uid).setValue(nil)
        self.sendFriendNotification("\(self.displayName) has accepted your friend request.", uid: uid)
        addToNotifications(uid, notificationType: "friends", param1: self._uid)
        removeFromNotifications(self._uid, notificationType: "friends", param1: uid)
        self.downloadUserInfo(){
            self.getFriendsInfo(){
                completion()
            }
        }
    }
    
    func removeUser(uid: String, completion: ()->()){
        firebase = FIRDatabase.database().reference()
        firebase.child("friendsInfo").child(_uid).child("friends").child(uid).setValue(nil)
        firebase.child("friendsInfo").child(uid).child("friends").child(_uid).setValue(nil)
        self.downloadUserInfo(){
            self.getFriendsInfo(){
                completion()
            }
        }
    }
    
    func hideAddRequest(uid: String, completion: ()->()) {
        firebase = FIRDatabase.database().reference()
        firebase.child("friendsInfo").child(_uid).child("wantsToBeAddedBy").child(uid).setValue("seen")
        completion()
    }
    
    func followUser(uid: String, completion: ()->()){
        guard self._uid != nil else { return }
        firebase = FIRDatabase.database().reference()
        firebase.child("followInfo").child(uid).child("followers").child(_uid).setValue(true)
        completion()
    }
    
    func unFollowUser(uid: String, completion: ()->()) {
        guard self._uid != nil else { return }
        firebase = FIRDatabase.database().reference()
        firebase.child("followInfo").child(uid).child("followers").child(_uid).setValue(nil)
        completion()
    }
    
    func sendFriendNotification(message: String, uid: String){
        sendNotification(uid, hasSound: false, groupId: "friendNotifications", message: message, deeplink: "friendlies://friends/\(self._uid)")
    }
    
    func blockUser(uid: String, completion: ()->()) {
        firebase = FIRDatabase.database().reference()
        firebase.child("blockInfo").child(_uid).child("isBlocking").child(uid).setValue(true)
        firebase.child("blockInfo").child(uid).child("isBlockedBy").child(_uid).setValue(true)
        unFollowUser(uid){}
        removeUsersNotificationsWith(uid)
        completion()
    }
    
    func unBlockUser(uid: String, completion: ()->()){
        firebase = FIRDatabase.database().reference()
        firebase.child("blockInfo").child(_uid).child("isBlocking").child(uid).setValue(nil)
        firebase.child("blockInfo").child(uid).child("isBlockedBy").child(_uid).setValue(nil)
    }
    
    func removeUsersNotificationsWith(uid: String){
        getConversationWith(uid){ (conversationId) in
            removeFromNotifications(self._uid, notificationType: "messages", param1: conversationId)
            removeFromNotifications(uid, notificationType: "messages", param1: conversationId)
        }
        removeFromNotifications(self._uid, notificationType: "friends", param1: uid)
        removeFromNotifications(uid, notificationType: "friends", param1: self._uid)
    }
    
    func getConversationWith(uid: String, completion: (conversationId: String) -> ()){
        downloadUserInfo(){
            let otherUser = User(uid: uid)
            otherUser.downloadUserInfo(){
                if let currentUserConversations = self._conversations {
                    if let otherUserConversations = otherUser.conversations {
                        for (conversationId, _) in currentUserConversations {
                            if otherUserConversations[conversationId] == true {
                                completion(conversationId: conversationId)
                            }
                        }
                    }
                }
            }
        }
    }
}

func addToNotifications(uid: String, notificationType: String, param1: String){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(notificationType).child(param1).setValue(true)
}

func removeFromNotifications(uid: String, notificationType: String, param1: String){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(notificationType).child(param1).setValue(nil)
}

func removeAllNotificationsOfType(uid: String, notificationType: String){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(notificationType).setValue(nil)
}