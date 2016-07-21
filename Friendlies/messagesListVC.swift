//
//  messagesListVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-20.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseDatabase

class messagesListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var firebase: FIRDatabaseReference!
    var currentUser: User!
    var conversationPreviews = [ConversationPreview]()
    var conversationsDownloaded = 0
    
    var activityIndicator: UIActivityIndicatorView!
    var loadingLabel: UILabel!
    var refreshControl: UIRefreshControl!
    
    var downloadedImages = [String: UIImage]()
    var pendingDownloads = [Int: String]()
    var uidsBeingDownloaded = [String]()
    
    var noMessagesLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = true
        self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        
        self.hideKeyboardWhenTappedAround()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        loadingLabel = UILabel(frame: CGRectMake(0, 0, 100, 30))
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.tableView.addSubview(refreshControl)
        self.tableView.scrollEnabled = true
        self.tableView.alwaysBounceVertical = true
        self.tableView.delaysContentTouches = false
        
        noMessagesLabel = UILabel(frame: CGRectMake(0, 0, 220, 120))
        
        firebase = FIRDatabase.database().reference()
        
        getCurrentUserConversations()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tabBarController?.tabBar.hidden = false
        self.navigationController?.navigationBarHidden = true
    }
            

    func getCurrentUserConversations() {
        if self.conversationPreviews.count == 0 {
            self.startLoadingAnimation(self.activityIndicator, loadingLabel: self.loadingLabel, viewToAdd: self.tableView)
            self.removeBackgroundMessage(self.noMessagesLabel)
        }
        CurrentUser.sharedInstance.getCurrentUser(){
            if let user = CurrentUser.sharedInstance.user {
                self.currentUser = user
                self.conversationsDownloaded = 0
                self.conversationPreviews = []
                if let conversations = self.currentUser.conversations {
                    if conversations.count == 0 {
                        self.doneRetreivingConversations()
                    } else {
                        for (conversationId, value) in conversations {
                            self.downloadConversationInfo(conversationId) {
                                self.conversationsDownloaded++
                                if self.conversationsDownloaded == conversations.count {
                                    self.doneRetreivingConversations()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func downloadConversationInfo(conversationId: String, completion: ()->()) {
        firebase.child("conversationInfos").child(conversationId).observeEventType(.Value, withBlock: { (snapshot) in
            guard let uids = snapshot.value!["uids"] as? [String: String] else { return }
            guard let displayNames = snapshot.value!["displayNames"] as? [String] else { return }
            guard let facebookIds = snapshot.value!["facebookIds"] as? [String] else { return }
            let lastMessage = snapshot.value!["lastMessage"] as? String ?? ""
            guard let lastMessageTime = snapshot.value!["lastMessageTime"] as? NSTimeInterval else { return }
            
            if let index = self.conversationPreviews.indexOf({$0.conversationId == snapshot.key}) {
                //if self.conversationPreviews[index].lastMessageTime != lastMessageTime {
                    let newConversationPreview = self.createNewConversationPreview(conversationId, uids: uids, displayNames: displayNames, facebookIds: facebookIds, lastMessage: lastMessage, lastMessageTime: lastMessageTime)
                    self.conversationPreviews.removeAtIndex(index)
                    self.conversationPreviews.append(newConversationPreview)
                    print(lastMessage)
                    print(self.conversationPreviews)
                    self.doneRetreivingConversations()
                //}
            } else {
                let newConversationPreview = self.createNewConversationPreview(conversationId, uids: uids, displayNames: displayNames, facebookIds: facebookIds, lastMessage: lastMessage, lastMessageTime: lastMessageTime)
                self.conversationPreviews.append(newConversationPreview)
                print(lastMessage)
                print(self.conversationPreviews)
                completion()
            }
        })
    }
    
    func doneRetreivingConversations() {
        sortConversationPreviews()
    }
    
    func sortConversationPreviews(){
        conversationPreviews.sortInPlace{(preview1: ConversationPreview, preview2: ConversationPreview) -> Bool in
            preview1.lastMessageTime > preview2.lastMessageTime
        }
        stopLoadingAnimation(activityIndicator, loadingLabel: loadingLabel)
        self.refreshControl.endRefreshing()
        tableView.reloadData()
        if conversationPreviews.count == 0 {
            displayBackgroundMessage("You have no messages!", label: noMessagesLabel, viewToAdd: tableView)
        } else {
            removeBackgroundMessage(noMessagesLabel)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessagesListCell", forIndexPath: indexPath) as!MessagesListCell
        let conversationPreview = conversationPreviews[indexPath.row]
        getConversationPhoto(conversationPreview, indexPath: indexPath)
        cell.configureCell(conversationPreview)
        return cell
    }
    
    func getConversationPhoto(conversationPreview: ConversationPreview, indexPath: NSIndexPath){
        if downloadedImages[conversationPreview.uid] == nil {
            if uidsBeingDownloaded.contains(conversationPreview.uid) {
                print("pending download for \(conversationPreview.displayName)")
                pendingDownloads[indexPath.row] = conversationPreview.uid
            } else {
                print("downloading \(conversationPreview.displayName)")
                uidsBeingDownloaded.append(conversationPreview.uid)
                pendingDownloads[indexPath.row] = conversationPreview.uid
                conversationPreview.getUserProfilePhoto() {
                    self.downloadedImages[conversationPreview.uid] = conversationPreview.profilePhoto
                    for (index, uid) in self.pendingDownloads {
                        if uid == conversationPreview.uid {
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            if indexPath.row < self.tableView.numberOfRowsInSection(0) {
                                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                            }
                        }
                    }
                    if let index = self.uidsBeingDownloaded.indexOf(conversationPreview.uid) {
                        self.uidsBeingDownloaded.removeAtIndex(index)
                    }
                }
            }
        } else {
            conversationPreview.profilePhoto = downloadedImages[conversationPreview.uid]
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversationPreview = conversationPreviews[indexPath.row]
        if let conversationId = conversationPreview.conversationId {
            performSegueWithIdentifier("chatVC", sender: conversationPreview)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationPreviews.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func createNewConversationPreview(conversationId: String, uids: [String: String], displayNames: [String], facebookIds: [String], lastMessage: String, lastMessageTime: NSTimeInterval) -> ConversationPreview {
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
    
        let newConversationPreview = ConversationPreview(conversationId: conversationId, uid: uid, displayName: displayName, facebookId: facebookId, lastMessage: lastMessage, lastMessageTime: lastMessageTime, seen: seen)
        
        return newConversationPreview
    }
    
    func refreshView(sender: AnyObject){
        getCurrentUserConversations()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chatVC" {
            if let destinationVC = segue.destinationViewController as? chatVC {
                if let conversationPreview = sender as? ConversationPreview {
                    if let uid = conversationPreview.uid {
                        if let conversationId = conversationPreview.conversationId {
                            destinationVC.senderId = currentUser.uid
                            destinationVC.senderDisplayName = currentUser.displayName
                            destinationVC.otherUser = User(uid: conversationPreview.uid)
                            destinationVC.conversationId = conversationId
                        }
                    }
                }
            }
        }
    }
}


