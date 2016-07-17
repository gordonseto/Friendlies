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
    private var _uid: String!
    private var _displayName: String!
    private var _gamerTag: String!
    private var _characters: [String]!
    private var _lastAvailable: NSTimeInterval!
    
    var uid: String {
        return _uid
    }
    
    var displayName: String! {
        return _displayName
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
    
    init(uid: String) {
        _uid = uid
    }
    
    func downloadUserInfo(completion: () -> ()) {
        let firebase = FIRDatabase.database().reference()
        firebase.child("users").child(_uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            self._displayName = snapshot.value!["displayName"] as? String ?? ""
            self._gamerTag = snapshot.value!["gamerTag"] as? String ?? ""
            self._characters = snapshot.value!["characters"] as? [String] ?? []
            self.facebookId = snapshot.value!["facebookId"] as? String ?? ""
            self._lastAvailable = snapshot.value!["lastAvailable"] as? NSTimeInterval ?? nil
            print("downloaded \(self._displayName)")
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