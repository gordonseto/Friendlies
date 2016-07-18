//
//  profileVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseAuth

enum FriendsStatus: Int, CustomStringConvertible {
    case Friends, NotFriends, WantsToAdd, WantsToBeAddedBy
    
    var blueButtonLabel: String {
        let labels = [
            "REMOVE FRIEND",
            "ADD AS A FRIEND",
            "PENDING FRIEND REQUEST",
            "ACCEPT FRIEND REQUEST"
        ]
        
        return labels[rawValue]
    }
    
    var description: String {
        return blueButtonLabel
    }
    
    func addInteraction(uid: String, completion: ()->()) {
        switch rawValue {
        case 0:
            CurrentUser.sharedInstance.removeUser(uid){
                completion()
            }
        case 1:
            CurrentUser.sharedInstance.sendAddRequestToUser(uid){
                completion()
            }
        case 2:
            CurrentUser.sharedInstance.cancelAddRequest(uid){
                completion()
            }
        case 3:
            CurrentUser.sharedInstance.acceptAddRequest(uid){
                completion()
            }
        default: break
        }
    }
}

class profileVC: UIViewController {

    @IBOutlet weak var userPhoto: profilePhoto!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var lastAvailable: UILabel!
    
    @IBOutlet weak var character1: UIImageView!
    @IBOutlet weak var character2: UIImageView!
    @IBOutlet weak var character3: UIImageView!
    @IBOutlet weak var character4: UIImageView!
    @IBOutlet weak var character5: UIImageView!
    
    @IBOutlet weak var characterStackView: UIStackView!
    
    @IBOutlet weak var yellowButton: friendliesButton!
    @IBOutlet weak var blueButton: friendliesButton!
    @IBOutlet weak var redButton: friendliesButton!
    
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var ownProfile: Bool = false
    var user: User!
    var currentUser: User!
    var uid: String!
    
    var refreshControl: UIRefreshControl!
    
    var fromFeed: Bool = false
    
    var friendsStatus: FriendsStatus!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.scrollView.addSubview(refreshControl)
        self.scrollView.scrollEnabled = true
        self.scrollView.alwaysBounceVertical = true
        
        scrollView.delaysContentTouches = false
        
        if let user = user {
            if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                if user.uid == uid {
                    ownProfile = true
                }
            }
            initializeView()
        } else {
            if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                CurrentUser.sharedInstance.getCurrentUser(){
                    self.user = CurrentUser.sharedInstance.user
                    self.ownProfile = true
                    self.settingsButton.hidden = false
                    self.initializeView()
                }
            }
        }
        
        if ownProfile {
            settingsButton.hidden = false
        }
        
        if fromFeed {
            backButton.hidden = false
        }
    }
    
    func downloadUserAndInitializeView() {
        
        user.downloadUserInfo() {
            self.initializeView()
        }
    }
    
    func initializeView(){
        if let name = self.user.displayName {
            self.displayName.text = name
        }
        if let tag = self.user.gamerTag {
            self.gamerTag.text = tag
        }
        
        arrangeStackViewCharacters(self.user, characterStackView: self.characterStackView, height: 25)
        
        if self.userPhoto.image == nil {
            self.user.getUserProfilePhoto(){
                self.userPhoto.image = self.user.profilePhoto
            }
        }
        
        if let lastavailable = self.user.lastAvailable {
            self.initializeTimeLabel(lastavailable)
        }
        
        if !ownProfile {
            getCurrentUser()
        }
    }
    
    func getCurrentUser(){
        CurrentUser.sharedInstance.getCurrentUser(){
            self.currentUser = CurrentUser.sharedInstance.user
            self.checkFriendsStatus()
        }
    }
    
    func checkFriendsStatus() {
        if let friends = currentUser.friends {
            if let wantsToAdd = currentUser.wantsToAdd {
                if let wantsToBeAddedBy = currentUser.wantsToBeAddedBy {
                    if friends.contains(user.uid) {
                        friendsStatus = FriendsStatus.Friends
                    } else if wantsToAdd.contains(user.uid) {
                        friendsStatus = FriendsStatus.WantsToAdd
                    } else if wantsToBeAddedBy.contains(user.uid) {
                        friendsStatus = FriendsStatus.WantsToBeAddedBy
                    } else {
                        friendsStatus = FriendsStatus.NotFriends
                    }
                    updateButtonLabels()
                }
            }
        }
    }
    
    func updateButtonLabels(){
        blueButton.setTitle(friendsStatus.blueButtonLabel, forState: .Normal)
    }

    @IBAction func onYellowPressed(sender: AnyObject) {
    }
    
    @IBAction func onBluePressed(sender: AnyObject) {
        if let friendsStatus = friendsStatus {
            blueButton.userInteractionEnabled = false
            friendsStatus.addInteraction(self.user.uid){
                self.checkFriendsStatus()
                self.blueButton.userInteractionEnabled = true
            }
        }
    }
    
    @IBAction func onRedPressed(sender: AnyObject) {
    }
    
    @IBAction func onSettingsPressed(sender: AnyObject) {
        if user != nil {
            performSegueWithIdentifier("editProfileVC", sender: nil)
        }
    }
    
    @IBAction func onBackButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileVC" {
            var destinationVC = segue.destinationViewController as! editProfileVC
            destinationVC.user = user
        }
    }
    
    func refreshView(sender: AnyObject){
        downloadUserAndInitializeView()
        self.refreshControl.endRefreshing()
    }
    
    func initializeTimeLabel(lastavailable: NSTimeInterval){
        var timeDifference = getBroadcastTime(lastavailable)
        var suffix: String = ""
        if timeDifference.1 == "s" {
            suffix = "SECOND"
        }
        if timeDifference.1 == "m" {
            suffix = "MINUTE"
        }
        if timeDifference.1 == "h" {
            suffix = "HOUR"
        }
        if timeDifference.1 == "d" {
            suffix = "DAY"
        }
        if timeDifference.1 == "w" {
            suffix = "WEEK"
        }
        if timeDifference.1 == "Y" {
            suffix = "YEAR"
        }
        var plural: String = ""
        if timeDifference.0 != "1" {
            plural = "S"
        }
        
        lastAvailable.text = "AVAILABLE \(timeDifference.0) \(suffix)\(plural) AGO"
    }
}

func arrangeStackViewCharacters(user: User, characterStackView: UIStackView, height: CGFloat){
    for stackView in characterStackView.subviews {
        stackView.removeFromSuperview()
    }
    
    if let characters = user.characters {
        for character in characters {
            let imageView = UIImageView()
            imageView.image = UIImage(named: character)
            imageView.heightAnchor.constraintEqualToConstant(height).active = true
            imageView.widthAnchor.constraintEqualToConstant(height).active = true
            characterStackView.addArrangedSubview(imageView)
        }
    }
}
