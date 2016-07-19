//
//  chatVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-19.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import FirebaseDatabase

class chatVC: JSQMessagesViewController {

    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var currentUser: User!
    var otherUser: User!
    
    var firebase: FIRDatabaseReference!
    var messagesRef: FIRDatabaseReference!
    var currentUserConversationRef: FIRDatabaseReference!
    var otherUserConversationRef: FIRDatabaseReference!
    
    var conversationId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedBackground()
        
        self.tabBarController?.tabBar.hidden = true
        
        self.navigationController?.navigationBarHidden = false
        
        self.navigationController?.navigationBar.barTintColor = UIColor.blackColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.collectionView.backgroundColor = UIColor.blackColor()
        self.inputToolbar.contentView.textView.keyboardAppearance = UIKeyboardAppearance.Dark
        self.inputToolbar.contentView.backgroundColor = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        self.inputToolbar.contentView.textView.textColor = UIColor.darkGrayColor()
        self.inputToolbar.contentView.textView.placeHolderTextColor = UIColor.darkGrayColor()
        currentUser = CurrentUser.sharedInstance.user
        
        firebase = FIRDatabase.database().reference()
        messagesRef = firebase.child("messages")
        currentUserConversationRef = firebase.child("users").child(currentUser.uid).child("conversations")
        otherUserConversationRef = firebase.child("users").child(otherUser.uid).child("conversations")
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        self.tabBarController?.tabBar.hidden = true
        self.navigationController?.navigationBarHidden = false
        
        if currentUser != nil {
            if otherUser != nil {
                title = otherUser.displayName
                setupBubbles()
                getConversation() {
                    self.getMessages()
                }
            }
        }
        
    }
    
    func getMessages() {
        if let conversationId = self.conversationId {
            firebase.child("messages").child(conversationId).observeEventType(.ChildAdded, withBlock: { (snapshot) in
                guard let id = snapshot.value!["senderId"] as? String else { return }
                guard let text = snapshot.value!["text"] as? String else { return }
                
                var displayName: String!
                if id == self.senderId {
                    displayName = self.currentUser.displayName
                } else {
                    displayName = self.otherUser.displayName
                }
                
                self.addMessage(id, displayName: displayName, text: text)
                
                self.finishReceivingMessage()
            })
        }
    }
    
    func getConversation(completion: () -> ()){
        if let currentUserConversations = currentUser.conversations {
            if let otherUserConversations = otherUser.conversations {
                for (conversationId, value) in currentUserConversations {
                    if otherUserConversations[conversationId] == true {
                        self.conversationId = conversationId
                        completion()
                    }
                }
            }
        }
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        var conversationId: String!
        var noConversationId: Bool = true
        
        if self.conversationId == nil {
            conversationId = currentUserConversationRef.childByAutoId().key
            currentUserConversationRef.child(conversationId).setValue(true)
            otherUserConversationRef.child(conversationId).setValue(true)
            self.conversationId = conversationId
        } else {
            noConversationId = false
            conversationId = self.conversationId
        }
        
        let itemRef = messagesRef.child(conversationId).childByAutoId()
        let messageItem = [
            "text": text,
            "senderId": senderId,
        ]
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        
        if noConversationId {
            currentUser.downloadUserInfo(){
                self.getMessages()
            }
        }
    }
    
    func addMessage(id: String, displayName: String, text: String){
        let message = JSQMessage(senderId: id, displayName: displayName, text: text)
        messages.append(message)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.whiteColor()
        }
        
        return cell
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.lightGrayColor())
    }

}

extension chatVC {
    func hideKeyboardWhenTappedBackground() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
    }
}
