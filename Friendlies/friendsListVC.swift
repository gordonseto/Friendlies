//
//  friendsListVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-18.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseDatabase

class friendsListVC: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var currentUser: User!
    var friendsKeys = [String]()
    var friends = [User]()
    var filteredUsers = [User]()
    var allUsers = [User]()
    
    var activityIndicator: UIActivityIndicatorView!
    var loadingLabel: UILabel!
    var refreshControl: UIRefreshControl!
    
    var downloadedImages = [String: UIImage]()
    var pendingDownloads = [Int: String]()
    var uidsBeingDownloaded = [String]()
    
    var inSearchMode: Bool = false
    var firebase: FIRDatabaseReference!
    var isDownloadingPeople: Bool = false
    
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
        
        firebase = FIRDatabase.database().reference()
      
        getCurrentUsersFriends()
    }
    
    func getCurrentUsersFriends(){
        if friends.count == 0 {
            self.startLoadingAnimation(self.activityIndicator, loadingLabel: self.loadingLabel, viewToAdd: self.tableView)
        }
        CurrentUser.sharedInstance.getCurrentUser(){
            if let user = CurrentUser.sharedInstance.user {
                self.currentUser = CurrentUser.sharedInstance.user
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
        for friendKey in friendsKeys {
            var user = User(uid: friendKey)
            user.downloadUserInfo(){
                self.friends.append(user)
                if self.friends.count == self.friendsKeys.count {
                    self.doneGettingProfiles()
                }
            }
        }
    }
    
    func doneGettingProfiles(){
        print(friends)
        stopLoadingAnimation(activityIndicator, loadingLabel: loadingLabel)
        self.refreshControl.endRefreshing()
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FriendsListCell", forIndexPath: indexPath) as! FriendsListCell
        var user: User!
        if !inSearchMode {
            user = friends[indexPath.row]
        } else {
            user = filteredUsers[indexPath.row]
        }
        getProfilePhoto(user, indexPath: indexPath)
        cell.configureCell(user)
        return cell
    }
    
    func getProfilePhoto(user: User, indexPath: NSIndexPath){
        if self.downloadedImages[user.uid] == nil {
            if uidsBeingDownloaded.contains(user.uid) {
                pendingDownloads[indexPath.row] = user.uid
            } else {
                print("downloading \(user.displayName)")
                uidsBeingDownloaded.append(user.uid)
                pendingDownloads[indexPath.row] = user.uid
                user.getUserProfilePhoto() {
                    self.downloadedImages[user.uid] = user.profilePhoto
                    for (index, uid) in self.pendingDownloads {
                        if uid == user.uid {
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                        }
                    }
                    if let index = self.uidsBeingDownloaded.indexOf(user.uid) {
                        self.uidsBeingDownloaded.removeAtIndex(index)
                    }
                }
            }
        } else {
            user.profilePhoto = downloadedImages[user.uid]
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if inSearchMode {
            return filteredUsers.count
        } else {
            return friends.count
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
            filteredUsers = friends.filter({$0.displayName.rangeOfString(lower) != nil})
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
                                    self.filteredUsers = self.allUsers.filter({$0.displayName.rangeOfString(lower) != nil})
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
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
    
}
