//
//  currentUser.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-18.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation
import FirebaseDatabase

class CurrentUser {
    
    var user: User!
    var firebase: FIRDatabaseReference!
    
    static let sharedInstance = CurrentUser()
    private init() {}
    
    func getCurrentUser(completion: ()->()){
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String{
            user = User(uid: uid)
            user.downloadUserInfo(){
            completion()
            }
        }
    }
    
    func sendAddRequestToUser(uid: String, completion: ()->()){
        if let user = user {
            firebase = FIRDatabase.database().reference()
            firebase.child("users").child(user.uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [String] ?? []
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
            firebase.child("users").child(uid).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var user = currentData.value as? [String: AnyObject] {
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [String] ?? []
                    print(wantsToBeAddedBy)
                    wantsToBeAddedBy.append(self.user.uid)
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
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [String] ?? []
                    print(wantsToBeAddedBy)
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0 != self.user.uid})
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
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [String] ?? []
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0 != uid})
                    user["wantsToBeAddedBy"] = wantsToBeAddedBy
                    var friends = user["friends"] as? [String] ?? []
                    friends.append(uid)
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
                    friends.append(self.user.uid)
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
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [String] ?? []
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0 != uid})
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
                    var wantsToBeAddedBy = user["wantsToBeAddedBy"] as? [String] ?? []
                    wantsToBeAddedBy = wantsToBeAddedBy.filter({$0 != self.user.uid})
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

}