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
    var friendsKeys = [String: Bool]()
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
    
    var updateNotifications: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBarHidden = true
        //self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        
        self.hideKeyboardWhenTappedAround()
        
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = self
        searchBar.keyboardAppearance = UIKeyboardAppearance.Dark
        
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
        downloadedImages = [:]
        pendingDownloads = [:]
        uidsBeingDownloaded = []
        if friendsAndWantsToBeAddedBy.count == 0 {
            if let activityIndicator = self.activityIndicator {
                if let loadingLabel = self.loadingLabel {
                    if let tableView = self.tableView {
                        self.startLoadingAnimation(activityIndicator, loadingLabel: loadingLabel, viewToAdd: tableView)
                        removeBackgroundMessage(noFriendsLabel)
                    }
                }
            }
        }
        CurrentUser.sharedInstance.getCurrentUser(){
            CurrentUser.sharedInstance.user.getFriendsInfo(){
                if let user = CurrentUser.sharedInstance.user {
                    self.currentUser = CurrentUser.sharedInstance.user
                
               // if self.updateNotifications {
                    removeAllNotificationsOfType(self.currentUser.uid, notificationType: "friends")
                    self.updateTabBarBadge("friends")
                    updateIconBadge()
                //}
                    self.updateNotifications = true
                    
                    CurrentUser.sharedInstance.user.getBlockedInfo(){
                        if let friendskeys = self.currentUser.friends {
                            self.friendsKeys = [:]
                            self.friends = []
                
                            self.friendsKeys = friendskeys
                            self.getFriendProfiles()
                        }
                    }
                }
            }
        }
    }
    
    func getFriendProfiles(){
        if friendsKeys.count == 0 {
            getCurrentUsersWantsToBeAddedBy()
        }
        for (friendKey, _) in friendsKeys {
            let user = User(uid: friendKey)
            user.downloadUserInfo(){ _ in
                self.friends.append(user)
                if self.friends.count == self.friendsKeys.count {
                    self.friends.sortInPlace {(friend1: User, friend2: User) -> Bool in
                        friend1.lastAvailable > friend2.lastAvailable
                    }
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
                
                for (wantsToBeAddedByKey, value) in wantsToBeAddedByKeys {
                    if value == "unseen" {
                        self.wantsToBeAddedByKeys.append(wantsToBeAddedByKey)
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
            let user = User(uid: wantsToBeAddedByKey)
            user.downloadUserInfo() { _ in
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
        filterBlockedUsers()
        stopLoadingAnimation(activityIndicator, loadingLabel: loadingLabel)
        self.refreshControl.endRefreshing()
        loadTable()
    }
    
    func filterBlockedUsers(){
        if let totalBlocked = self.currentUser.totalBlocked {
            if inSearchMode {
                filteredUsers = filteredUsers.filter({totalBlocked[$0.uid] == nil})
            } else {
                friendsAndWantsToBeAddedBy = friendsAndWantsToBeAddedBy.filter({totalBlocked[$0.uid] == nil})
            }
        }
    }
    
    func AcceptButtonPressed(uid: String) {
        CurrentUser.sharedInstance.user.acceptAddRequest(uid){
            self.getCurrentUsersFriends()
            self.friendsListAction()
        }
    }
    
    func DeclineButtonPressed(uid: String) {
        CurrentUser.sharedInstance.user.hideAddRequest(uid){
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
        print("\(user.displayName) \(user.shouldSeeLastAvailable)")
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
                    user.downloadUserInfo(){_ in 
                        self.currentUser.checkIfShouldBeAbleToSeeUserDetails(user){ (should) in
                            user.shouldSeeLastAvailable = should
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
    
    func loadTable(){
        tableView.reloadData()
        if !inSearchMode {
            if friendsAndWantsToBeAddedBy.count == 0 {
                displayBackgroundMessage("You have not added any friends!", label: noFriendsLabel, viewToAdd: tableView)
            } else {
                removeBackgroundMessage(noFriendsLabel)
            }
        } else {
            removeBackgroundMessage(noFriendsLabel)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil || searchBar.text == "" {
            inSearchMode = false
            //view.endEditing(true)
            filterBlockedUsers()
            loadTable()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.capitalizedString
            filteredUsers = wantsToBeAddedBy.filter({$0.displayName.rangeOfString(lower) != nil})
            filterBlockedUsers()
            loadTable()
            if !isDownloadingPeople {
                isDownloadingPeople = true
                self.firebase.child("displayNames").observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                    print(snapshot)
                    for child in snapshot.children {
                        if let child = child as? FIRDataSnapshot {
                            if let uid = child.value!["uid"] as? String {
                                if let facebookid = child.value!["facebookId"] as? String {
                                    var user: User!
                                    if let index = self.friends.indexOf({$0.uid == uid}){
                                        user = self.friends[index]
                                    } else {
                                        user = User(uid: uid)
                                        user.displayName = child.key
                                        user.facebookId = facebookid
                                    }
                                    self.allUsers.append(user)
                                }
                            }
                        }
                    }
                    self.filteredUsers = self.allUsers.filter({$0.displayName.rangeOfString(lower) != nil})
                    self.filterBlockedUsers()
                    self.loadTable()
                })
            } else {
                if allUsers.count != 0 {
                    self.filteredUsers = self.allUsers.filter({$0.displayName.rangeOfString(lower) != nil})
                    filterBlockedUsers()
                    self.loadTable()
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
