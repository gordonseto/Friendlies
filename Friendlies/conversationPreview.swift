//
//  conversationPreview.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-20.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation

class conversationPreview {
    
    private var _conversationId: String!
    private var _uid: String!
    private var _displayName: String!
    private var _facebookId: String!
    private var _lastMessage: String!
    private var _lastMessageTime: NSTimeInterval!
    private var _seen: Bool!
    var profilePhoto: UIImage!
    
    var conversationId: String! {
        return _conversationId
    }
    
    var uid: String! {
        return _uid
    }
    
    var displayName: String! {
        return _displayName
    }
    
    var facebookId: String! {
        return _facebookId
    }
    
    var lastMessage: String! {
        return _lastMessage
    }

    var lastMessageTime: NSTimeInterval {
        return _lastMessageTime
    }
    
    var seen: Bool! {
        return _seen
    }
    
    init(conversationId: String, uid: String, displayName: String, facebookId: String, lastMessage: String, lastMessageTime: NSTimeInterval, seen: Bool) {
        _conversationId = conversationId
        _uid = uid
        _displayName = displayName
        _facebookId = facebookId
        _lastMessage = lastMessage
        _lastMessageTime = lastMessageTime
        _seen = seen
    }
    
    func getUserProfilePhoto(completion: () -> ()) {
        if let facebookid = _facebookId {
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