//
//  friendsListVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-18.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseDatabase

class friendsListVC: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, FriendsListCellDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var currentUser: User!
    var friendsKeys = [String]()
    var friends = [User]()
    var filteredUsers = [User]()
    var allUsers = [User]()
    var wantsToBeAddedByKeys = [String]()
    var wantsToBeAddedBy = [User]()
    var friendsAndWantsToBeAddedBy = [User]()
    
    var activityIndicator: UIActivityIndicatorView!
    var loadingLabel: UILabel!
    var refreshControl: UIRefreshControl!
    
    var downloadedImages = [String: UIImage]()
    var pendingDownloads = [Int: String]()
    var uidsBeingDownloaded = [String]()
    
    var inSearchMode: Bool = false
    var firebase: FIRDatabaseReference!
    var isDownloadingPeople: Bool = false
    
    var noFriendsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = true
        self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        
        self.hideKeyboardWhenTappedAround()
        
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = self
        
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
        
        noFriendsLabel = UILabel(frame: CGRectMake(0, 0, 220, 120))
        
        firebase = FIRDatabase.database().reference()
      
        getCurrentUsersFriends()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tabBarController?.tabBar.hidden = false
        self.navigationController?.navigationBarHidden = true

    }
    
    func getCurrentUsersFriends(){
        if friends.count == 0 {
            self.startLoadingAnimation(self.activityIndicator, loadingLabel: self.loadingLabel, viewToAdd: self.tableView)
            removeBackgroundMessage(noFriendsLabel)
        }
        CurrentUser.sharedInstance.getCurrentUser(){
            if let user = CurrentUser.sharedInstance.user {
                self.currentUser = CurrentUser.sharedInstance.user
                
                removeAllNotificationsOfType(self.currentUser.uid, notificationType: "friends")
                self.updateTabBarBadge("friends")
                self.updateIconBadge()
                
                if let friendskeys = self.currentUser.friends {
                    self.friendsKeys = []
                    self.friends = []
                
                    self.friendsKeys = friendskeys
                    self.getFriendProfiles()
                }
            }
        }
    }
    
    func getFriendProfiles(){
        if friendsKeys.count == 0 {
            getCurrentUsersWantsToBeAddedBy()
        }
        for friendKey in friendsKeys {
            var user = User(uid: friendKey)
            user.downloadUserInfo(){
                self.friends.append(user)
                if self.friends.count == self.friendsKeys.count {
                    self.getCurrentUsersWantsToBeAddedBy()
                }
            }
        }
    }
    
    func getCurrentUsersWantsToBeAddedBy(){
        if let user = currentUser {
            if let wantsToBeAddedByKeys = user.wantsToBeAddedBy {
                self.wantsToBeAddedByKeys = []
                self.wantsToBeAddedBy = []
                
                for wantsToBeAddedByKey in wantsToBeAddedByKeys {
                    for (uid, value) in wantsToBeAddedByKey {
                        if value == "unseen" {
                            self.wantsToBeAddedByKeys.append(uid)
                        }
                    }
                }
                self.getWantsToBeAddedByProfiles()
            }
        }
    }
    
    func getWantsToBeAddedByProfiles() {
        if wantsToBeAddedByKeys.count == 0 {
            doneGettingProfiles()
        }
        for wantsToBeAddedByKey in wantsToBeAddedByKeys {
            var user = User(uid: wantsToBeAddedByKey)
            user.downloadUserInfo() {
                self.wantsToBeAddedBy.append(user)
                if self.wantsToBeAddedBy.count == self.wantsToBeAddedByKeys.count {
                    self.doneGettingProfiles()
                }
            }
        }
    }
    
    func doneGettingProfiles(){
        print(friends)
        print(wantsToBeAddedBy)
        friendsAndWantsToBeAddedBy = wantsToBeAddedBy + friends
        stopLoadingAnimation(activityIndicator, loadingLabel: loadingLabel)
        self.refreshControl.endRefreshing()
        tableView.reloadData()
        if !inSearchMode {
            if friendsAndWantsToBeAddedBy.count == 0 {
                displayBackgroundMessage("You have not added any friends!", label: noFriendsLabel, viewToAdd: tableView)
            } else {
                removeBackgroundMessage(noFriendsLabel)
            }
        }
    }
    
    func AcceptButtonPressed(uid: String) {
        CurrentUser.sharedInstance.acceptAddRequest(uid){
            self.getCurrentUsersFriends()
            self.friendsListAction()
        }
    }
    
    func DeclineButtonPressed(uid: String) {
        CurrentUser.sharedInstance.hideAddRequest(uid){
            self.getCurrentUsersFriends()
            self.friendsListAction()
        }
    }
    
    func friendsListAction(){
        updateTabBarBadge("friends")
        updateIconBadge()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FriendsListCell", forIndexPath: indexPath) as! FriendsListCell
        cell.delegate = self
        cell.isFriendRequest = false
        cell.lastAvailable.text = ""
        
        var user: User!
        if !inSearchMode {
            if indexPath.row < wantsToBeAddedBy.count {
                cell.isFriendRequest = true
            }
            user = friendsAndWantsToBeAddedBy[indexPath.row]
        } else {
            user = filteredUsers[indexPath.row]
        }
        getUser(user, indexPath: indexPath)
        cell.configureCell(user)
        return cell
    }
    
    func getUser(user: User, indexPath: NSIndexPath){
        if downloadedImages[user.uid] == nil {
            if uidsBeingDownloaded.contains(user.uid) {
                print("pending download for \(user.displayName)")
                pendingDownloads[indexPath.row] = user.uid
            } else {
                print("downloading \(user.displayName)")
                uidsBeingDownloaded.append(user.uid)
                pendingDownloads[indexPath.row] = user.uid
                user.getUserProfilePhoto() {
                    user.downloadUserInfo(){
                        self.downloadedImages[user.uid] = user.profilePhoto
                        for (index, uid) in self.pendingDownloads {
                            if uid == user.uid {
                                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                                if indexPath.row < self.tableView.numberOfRowsInSection(0) {
                                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                }
                            }
                        }
                        if let index = self.uidsBeingDownloaded.indexOf(user.uid) {
                            self.uidsBeingDownloaded.removeAtIndex(index)
                        }
                    }
                }
            }
        } else {
            user.profilePhoto = downloadedImages[user.uid]
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var user: User!
        if inSearchMode{
            user = filteredUsers[indexPath.row]
        } else {
            user = friendsAndWantsToBeAddedBy[indexPath.row]
        }
        if let user = user {
            if let currentuser = CurrentUser.sharedInstance.user {
                performSegueWithIdentifier("profileVCFromFriends", sender: user)
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if inSearchMode {
            return filteredUsers.count
        } else {
            return friendsAndWantsToBeAddedBy.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
            inSearchMode = false
            //view.endEditing(true)
            tableView.reloadData()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.capitalizedString
            filteredUsers = wantsToBeAddedBy.filter({$0.displayName.rangeOfString(lower) != nil})
            tableView.reloadData()
            if !isDownloadingPeople {
                isDownloadingPeople = true
                self.firebase.child("displayNames").observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                    print(snapshot)
                    for child in snapshot.children {
                        if let child = child as? FIRDataSnapshot {
                            if let uid = child.value!["uid"] as? String {
                                if let facebookid = child.value!["facebookId"] as? String {
                                    let user = User(uid: uid)
                                    user.displayName = child.key
                                    user.facebookId = facebookid
                                    self.allUsers.append(user)
                                }
                            }
                        }
                    }
                    self.filteredUsers = self.allUsers.filter({$0.displayName.rangeOfString(lower) != nil})
                    self.tableView.reloadData()
                })
            } else {
                if allUsers.count != 0 {
                    self.filteredUsers = self.allUsers.filter({$0.displayName.rangeOfString(lower) != nil})
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func refreshView(sender: AnyObject){
        getCurrentUsersFriends()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let currentuser = CurrentUser.sharedInstance.user {
            if segue.identifier == "profileVCFromFriends" {
                if let destinationVC = segue.destinationViewController as? profileVC {
                    super.prepareForSegue(segue, sender: sender)
                    destinationVC.user = sender as! User
                    destinationVC.notFromTabBar = true
                }
            }
        }
    }
    
}
