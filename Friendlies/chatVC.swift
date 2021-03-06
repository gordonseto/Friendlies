
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
    var conversationInfoRef: FIRDatabaseReference!
    
    var conversationId: String!
    
    var userIsTypingRef: FIRDatabaseReference!
    var usersTypingQuery: FIRDatabaseQuery!
    
    var avatars = [String: JSQMessagesAvatarImage]()
    
    var isLookingAtMessage: Bool = true
    
    let MESSAGE_LOAD_INCREMENT: UInt = 30
    var currentEndingKey = "-ZZZZZZZZZZZZZZZZZZZ"
    
    /*
    private var localTyping = false
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedBackground()
        
        self.tabBarController?.tabBar.hidden = true
        
        self.navigationController?.navigationBarHidden = false
        
        self.view.backgroundColor = UIColor(red: 17.0/255.0, green: 17.0/255.0, blue: 17.0/255.0, alpha: 7.0)
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 15.0/255.0, green: 15.0/255.0, blue: 15.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        self.collectionView.backgroundColor = UIColor(red: 17.0/255.0, green: 17.0/255.0, blue: 17.0/255.0, alpha: 1.0)
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.inputToolbar.contentView.textView.keyboardAppearance = UIKeyboardAppearance.Dark
        self.inputToolbar.contentView.backgroundColor = UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0)
        self.inputToolbar.contentView.textView.textColor = UIColor.darkGrayColor()
        self.inputToolbar.contentView.textView.placeHolderTextColor = UIColor.darkGrayColor()
        self.inputToolbar.contentView.leftBarButtonItem = nil
        self.inputToolbar.contentView.leftBarButtonItemWidth = self.inputToolbar.contentView.rightBarButtonItemWidth * 0.25
        
        self.collectionView.delaysContentTouches = false

        if let user = CurrentUser.sharedInstance.user {
            currentUser = user
            if otherUser.displayName == nil {
                otherUser.downloadUserInfo(){_ in 
                    self.beginSetup()
                }
            } else {
                beginSetup()
            }
            
        } else {
            CurrentUser.sharedInstance.getCurrentUser(){
                self.currentUser = CurrentUser.sharedInstance.user
                if self.otherUser.displayName == nil {
                    self.otherUser.downloadUserInfo(){_ in 
                        self.beginSetup()
                    }
                } else {
                    self.beginSetup()
                }
            }
        }
        
    }
    
    func beginSetup(){
        firebase = FIRDatabase.database().reference()
        messagesRef = firebase.child("messages")
        currentUserConversationRef = firebase.child("users").child(currentUser.uid).child("conversations")
        otherUserConversationRef = firebase.child("users").child(otherUser.uid).child("conversations")
        
        if otherUser != nil {
            addNavigationButtons()
        }
        
        if currentUser != nil {
            if otherUser != nil {
                setupBubbles()
                if conversationId == nil {
                    getConversation() {
                        self.setupConversation()
                    }
                } else {
                    setupConversation()
                }
            }
        }
    }
    
    
    func setupConversation(){
        //setupAvatars()
        getMessages()
        getPastMessages(){
            self.scrollToBottomAnimated(true)
        }
        //observeTyping()
    }
    
    func getMessages() {
        if let conversationId = self.conversationId {
            conversationInfoRef = firebase.child("conversationInfos").child(conversationId)
            var messagesLoaded = 0
            firebase.child("messages").child(conversationId).queryLimitedToLast(1).observeEventType(.ChildAdded, withBlock: { (snapshot) in
                
                if let message = self.getMessageFromSnapshot(snapshot) {
                    messagesLoaded++
                    if messagesLoaded == 1 {
                        self.currentEndingKey = snapshot.key
                    } else {
                        self.messages.append(message)
                    }
                }
                
                if self.isLookingAtMessage {
                    self.conversationInfoRef.child("uids").child(self.currentUser.uid).setValue("seen")
                    NotificationsManager.sharedInstance.removeFromNotifications(self.currentUser.uid, notificationType: "messages", param1: self.conversationId)
                }
                
                self.finishReceivingMessage()
            })
        }
    }
    
    func getPastMessages(completion: ()->()) {
        if let conversationId = self.conversationId {
            firebase.child("messages").child(conversationId).queryOrderedByKey().queryEndingAtValue(currentEndingKey).queryLimitedToLast(MESSAGE_LOAD_INCREMENT + 1).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                var temporaryMessagesArray = [JSQMessage]()
                var skipFirst: Bool = true
                
                if snapshot.childrenCount <= self.MESSAGE_LOAD_INCREMENT {
                    self.showLoadEarlierMessagesHeader = false
                    skipFirst = false
                } else {
                    self.showLoadEarlierMessagesHeader = true
                }
                
                for (index, child) in snapshot.children.enumerate() {
                    if index == 0 && skipFirst {
                        self.currentEndingKey = child.key
                    } else {
                        if let message = self.getMessageFromSnapshot(child as! FIRDataSnapshot){
                            temporaryMessagesArray.append(message)
                        }
                    }
                }
                self.messages = temporaryMessagesArray + self.messages
                self.collectionView.reloadData()
                completion()
            })
        }
    }
    
    func getMessageFromSnapshot(snapshot: FIRDataSnapshot) -> JSQMessage? {
        guard let id = snapshot.value!["senderId"] as? String else { return nil}
        guard let text = snapshot.value!["text"] as? String else { return nil}
        guard let time = snapshot.value!["time"] as? NSTimeInterval else { return nil }
        
        var displayName: String!
        if id == self.senderId {
            displayName = self.currentUser.displayName
        } else {
            displayName = self.otherUser.displayName
        }
        
        let date = NSDate(timeIntervalSince1970: time)
        let message = JSQMessage(senderId: id, senderDisplayName: displayName, date: date, text: text)
        
        return message
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
        getPastMessages(){}
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        isLookingAtMessage = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        isLookingAtMessage = false
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
            noConversationId = true
            conversationId = setupNewConversation()
        } else {
            noConversationId = false
            conversationId = self.conversationId
        }
        
        let itemRef = messagesRef.child(conversationId).childByAutoId()
        
        let time = NSDate().timeIntervalSince1970
        
        let messageItem = [
            "text": text,
            "senderId": senderId,
            "time": time
        ]
        itemRef.setValue(messageItem)
        
        conversationInfoRef.child("lastMessage").setValue(text)
        conversationInfoRef.child("lastMessageTime").setValue(time)
        conversationInfoRef.child("uids").child(currentUser.uid).setValue("seen")
        conversationInfoRef.child("uids").child(otherUser.uid).setValue("unseen")
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        sendMessageNotification(senderDisplayName, message: text)
        NotificationsManager.sharedInstance.addToNotifications(otherUser.uid, notificationType: "messages", param1: conversationId)
        
        finishSendingMessage()
        
        //isTyping = false

        if noConversationId {
            CurrentUser.sharedInstance.user.conversations[conversationId] = true
            self.otherUser.conversations[conversationId] = true
            self.setupConversation()
        }
    
    }
    
    func setupNewConversation() -> String {
        conversationId = currentUserConversationRef.childByAutoId().key
        currentUserConversationRef.child(conversationId).setValue(true)
        otherUserConversationRef.child(conversationId).setValue(true)
        let uids = [currentUser.uid: "unseen", otherUser.uid: "unseen"]
        let displayNames = [currentUser.displayName, otherUser.displayName]
        let facebookIds = [currentUser.facebookId, otherUser.facebookId]
        let newConversation = ["displayNames": displayNames, "facebookIds": facebookIds]
        conversationInfoRef = firebase.child("conversationInfos").child(conversationId)
        conversationInfoRef.setValue(newConversation)
        conversationInfoRef.child("uids").setValue(uids)
        NotificationsManager.sharedInstance.addToNotifications(otherUser.uid, notificationType: "messages", param1: conversationId)
        return conversationId
    }
    /*
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        
        if let text = textView.text {
            isTyping = textView.text != ""
        }
    }
    
    private func observeTyping() {
        if let conversationId = conversationId {
            let typingIndicatorRef = messagesRef.child(conversationId).child("typingIndicator")
            userIsTypingRef = typingIndicatorRef.child(senderId)
            userIsTypingRef.onDisconnectRemoveValue()
            
            usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
            
            usersTypingQuery.observeEventType(.Value, withBlock: { (snapshot) in
                if snapshot.childrenCount == 1 && self.isTyping {
                    return
                }
                
                self.showTypingIndicator = snapshot.childrenCount > 0
                self.scrollToBottomAnimated(true)
            })
        }
    }
 */
    /*
    func setupAvatarImage(name: String, imageUrl: String?, incoming: Bool) {
        let image =
        let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
        let avatarImage = JSQMessagesAvatarFactory.avatarWithImage(image, diameter: diameter)
        avatars[name] = avatarImage
        return
    }
    */
    
    func setupAvatars() {
        if let currentuserpic = currentUser.profilePhoto {
            avatars[currentUser.uid] = JSQMessagesAvatarImageFactory.avatarImageWithImage(currentUser.profilePhoto, diameter: 30)
        } else {
            CurrentUser.sharedInstance.user.getUserProfilePhoto(){
                self.currentUser.profilePhoto = CurrentUser.sharedInstance.user.profilePhoto
                self.avatars[self.currentUser.uid] = JSQMessagesAvatarImageFactory.avatarImageWithImage(self.currentUser.profilePhoto, diameter: 30)
                self.collectionView.reloadData()
            }
        }
        if let otheruserpic = otherUser.profilePhoto {
            avatars[otherUser.uid] = JSQMessagesAvatarImageFactory.avatarImageWithImage(otherUser.profilePhoto, diameter: 30)
        }
    }

    func addNavigationButtons(){
        var titleButton = UIButton()
        titleButton.setTitle(otherUser.displayName, forState: .Normal)
        titleButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        titleButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        titleButton.frame = CGRectMake(0, 0, 100, 44)
        titleButton.addTarget(self, action: "onTitleTapped", forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.titleView = titleButton
        
        var image = UIImage(named: "mapMarker")
        //image = imageWithImage(image!, scaledToSize: CGSizeMake(97.0/7.0, 160.0/7.0))
        var hereButton = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: "onHereButtonPressed")
        self.navigationItem.rightBarButtonItem = hereButton
    }
    
    func onHereButtonPressed() {
        let date = NSDate()
        guard let currentUser = currentUser else { return }
        guard let otherUser = otherUser else { return }
        
        didPressSendButton(nil, withMessageText: "Here", senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: date)
        currentUser.addActivity(otherUser.uid)
        otherUser.addActivity(currentUser.uid)
    }
    
    func onTitleTapped(){
        performSegueWithIdentifier("profileVCFromChat", sender: nil)
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale);
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
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
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.row]
        if indexPath.row == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            let difference = getTimeDifference(messages[indexPath.row - 1].date, endDate: messages[indexPath.row].date)
            if difference > 10 {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            } else {
                return 0
            }
        }
    }
    
    func getTimeDifference(startDate: NSDate, endDate: NSDate) -> Int {
        let calendar = NSCalendar.currentCalendar()
        let datecomponenets = calendar.components(NSCalendarUnit.NSMinuteCalendarUnit, fromDate: startDate, toDate: endDate, options: NSCalendarOptions.MatchFirst)
        let minutes = datecomponenets.minute
        return minutes
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]
        let sharedFormatter = JSQMessagesTimestampFormatter()
        if indexPath.row == 0 {
            return sharedFormatter.attributedTimestampForDate(message.date)
        } else {
            let difference = getTimeDifference(messages[indexPath.row - 1].date, endDate: messages[indexPath.row].date)
            if difference > 10 {
                return sharedFormatter.attributedTimestampForDate(message.date)
            } else {
                return nil
            }
        }
    }
    
    func sendMessageNotification(displayName: String, message: String){
        NotificationsManager.sharedInstance.sendNotification(otherUser.uid, hasSound: true, groupId: "messageNotifications", message: "\(displayName): \(message)", deeplink: "friendlies://messages/\(self.conversationId)/\(self.currentUser.uid)")
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleGreenColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.lightGrayColor())
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "profileVCFromChat" {
            if let destinationVC = segue.destinationViewController as? profileVC {
                destinationVC.user = otherUser
                destinationVC.notFromTabBar = true
            }
        }
    }

}

extension chatVC {
    func hideKeyboardWhenTappedBackground() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
    }
}

extension JSQMessagesLoadEarlierHeaderView {
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        loadButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        loadButton.setTitle("Load Earlier Messages", forState: .Normal)
    }
    
}
 