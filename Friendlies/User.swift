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
    private var _friends: [String]!
    private var _wantsToAdd: [String]!
    private var _wantsToBeAddedBy: [[String: String]]!
    private var _conversations: [String: Bool]!
    
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
    
    var friends: [String]! {
        return _friends
    }
    
    var wantsToAdd: [String]! {
        return _wantsToAdd
    }
    
    var wantsToBeAddedBy: [[String: String]]! {
        return _wantsToBeAddedBy
    }
    
    var conversations: [String: Bool]! {
        return _conversations
    }
    
    init(uid: String) {
        _uid = uid
    }
    
    func downloadUserInfo(completion: () -> ()) {
        let firebase = FIRDatabase.database().reference()
        firebase.child("users").child(_uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            self.displayName = snapshot.value!["displayName"] as? String ?? ""
            self._gamerTag = snapshot.value!["gamerTag"] as? String ?? ""
            self._characters = snapshot.value!["characters"] as? [String] ?? []
            self.facebookId = snapshot.value!["facebookId"] as? String ?? ""
            self._lastAvailable = snapshot.value!["lastAvailable"] as? NSTimeInterval ?? nil
            self._friends = snapshot.value!["friends"] as? [String] ?? []
            self._wantsToAdd = snapshot.value!["wantsToAdd"] as? [String] ?? []
            self._wantsToBeAddedBy = snapshot.value!["wantsToBeAddedBy"] as? [[String: String]] ?? [[:]]
            self._conversations = snapshot.value!["conversations"] as? [String: Bool] ?? [:]
            print("downloaded \(self.displayName)")
            completion()
        }) { (error) in
            print("error retreiving user")
            completion()
        }
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
    
}

func addToNotifications(uid: String, notificationType: String, param1: AnyObject){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(notificationType).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
        if var notificationTypeArray = currentData.value as? [String]! ?? [] {
            if let param1 = param1 as? String {
                if !notificationTypeArray.contains(param1) {
                    notificationTypeArray.append(param1)
                }
                currentData.value = notificationTypeArray
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

func removeFromNotifications(uid: String, notificationType: String, param1: AnyObject){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(notificationType).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
        if var notificationTypeArray = currentData.value as? [String]! ?? [] {
            if let param1 = param1 as? String {
                notificationTypeArray = notificationTypeArray.filter({$0 != param1})
                currentData.value = notificationTypeArray
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

func removeAllNotificationsOfType(uid: String, notificationType: String){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(notificationType).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
        if var notificationTypeArray = currentData.value as? [String]! ?? [] {
            notificationTypeArray = []
            currentData.value = notificationTypeArray
            return FIRTransactionResult.successWithValue(currentData)
        }
        return FIRTransactionResult.successWithValue(currentData)
        }, andCompletionBlock: { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                print("WANTS TO ADD FAILED")
            }
    })
}