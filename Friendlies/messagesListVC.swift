//
//  messagesListVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-20.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseDatabase

class messagesListVC: UIViewController {
    
    var firebase: FIRDatabaseReference!
    var currentUser: User!
    var conversationPreviews = [conversationPreview]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = true
        self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        
        self.hideKeyboardWhenTappedAround()
        
        firebase = FIRDatabase.database().reference()
        
        getCurrentUserConversations()
    }

    func getCurrentUserConversations() {
        CurrentUser.sharedInstance.getCurrentUser(){
            if let user = CurrentUser.sharedInstance.user {
                self.currentUser = user
                if let conversations = self.currentUser.conversations {
                    for (conversationId, value) in conversations {
                        self.downloadConversationInfo(conversationId)
                    }
                }
            }
        }
    }
    
    func downloadConversationInfo(conversationId: String) {
        firebase.child("conversationInfos").child(conversationId).observeEventType(.Value, withBlock: { (snapshot) in
            guard let uids = snapshot.value!["uids"] as? [String: String] else { return }
            guard let displayNames = snapshot.value!["displayNames"] as? [String] else { return }
            guard let facebookIds = snapshot.value!["facebookIds"] as? [String] else { return }
            let lastMessage = snapshot.value!["lastMessage"] as? String ?? ""
            guard let lastMessageTime = snapshot.value!["lastMessageTime"] as? NSTimeInterval else { return }
            
            let newConversationPreview = self.createNewConversationPreview(conversationId, uids: uids, displayNames: displayNames, facebookIds: facebookIds, lastMessage: lastMessage, lastMessageTime: lastMessageTime)
            
            if let index = self.conversationPreviews.indexOf({$0.conversationId == snapshot.key}) {
                self.conversationPreviews.removeAtIndex(index)
                self.conversationPreviews.append(newConversationPreview)
            } else {
                self.conversationPreviews.append(newConversationPreview)
            }
            print(lastMessage)
            print(self.conversationPreviews)
        })
    }
    
    func createNewConversationPreview(conversationId: String, uids: [String: String], displayNames: [String], facebookIds: [String], lastMessage: String, lastMessageTime: NSTimeInterval) -> conversationPreview {
        var uid = self.currentUser.uid
        var seen: Bool = false
        for (UID, value) in uids {
            if UID != self.currentUser.uid {
                uid = UID
            } else {
                if value == "seen" {
                    seen = true
                } else {
                    seen = false
                }
            }
        }
        var displayName = self.currentUser.displayName
        for dn in displayNames {
            if dn != self.currentUser.displayName {
                displayName = dn
            }
        }
        var facebookId = self.currentUser.facebookId
        for fi in facebookIds {
            if fi != self.currentUser.facebookId {
                facebookId = fi
            }
        }
    
        let newConversationPreview = conversationPreview(conversationId: conversationId, uid: uid, displayName: displayName, facebookId: facebookId, lastMessage: lastMessage, lastMessageTime: lastMessageTime, seen: seen)
        
        return newConversationPreview
    }
}
    

