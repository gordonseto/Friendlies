//
//  profileVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseAuth
import SloppySwiper

enum FriendsStatus: Int, CustomStringConvertible {
    case Friends, NotFriends, WantsToAdd, WantsToBeAddedBy
    
    var blueButtonLabel: String {
        let labels = [
            "REMOVE FRIEND",
            "ADD AS A FRIEND",
            "CANCEL FRIEND REQUEST",
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

enum FollowStatus: Int, CustomStringConvertible {
    case Follower, NotFollower
    
    var redButtonLabel: String {
        let labels = [
            "UNFOLLOW USER",
            "FOLLOW USER"
        ]
        
        return labels[rawValue]
    }
    
    var description: String {
        return redButtonLabel
    }
    
    func followInteraction(uid: String, completion: ()->()){
        switch rawValue {
        case 0:
            CurrentUser.sharedInstance.unFollowUser(uid){
                completion()
            }
        case 1:
            CurrentUser.sharedInstance.followUser(uid){
                completion()
            }
        default: break
        }
    }
}

class profileVC: UIViewController, UIViewControllerTransitioningDelegate {

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
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var ownProfile: Bool = false
    var user: User!
    var currentUser: User!
    var uid: String!
    
    var refreshControl: UIRefreshControl!
    
    var fromChat: Bool = false
    var notFromTabBar: Bool = false
    
    var friendsStatus: FriendsStatus!
    var followStatus: FollowStatus!
    
    var swiper: SloppySwiper!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        //self.navigationController?.interactivePopGestureRecognizer!.delegate = nil;
        if let navigationcontroller = self.navigationController {
            swiper = SloppySwiper(navigationController: navigationcontroller)
            navigationcontroller.delegate = swiper
        }
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        self.scrollView.addSubview(refreshControl)
        self.scrollView.scrollEnabled = true
        self.scrollView.alwaysBounceVertical = true
        
        scrollView.delaysContentTouches = false
        
        if let user = user {
            if let uid = FIRAuth.auth()?.currentUser?.uid {
                if user.uid == uid {
                    ownProfile = true
                }
            }
            initializeView()
        } else {
            if let uid = FIRAuth.auth()?.currentUser?.uid {
                CurrentUser.sharedInstance.getCurrentUser(){
                    self.user = CurrentUser.sharedInstance.user
                    self.ownProfile = true
                    self.settingsButton.hidden = false
                    self.initializeView()
                }
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.hidden = false
    }
    
    func downloadUserAndInitializeView() {
        
        user.downloadUserInfo() {
            self.initializeView()
        }
    }
    
    func initializeView(){
        
        if ownProfile {
            settingsButton.hidden = false
            moreButton.hidden = true
        } else {
            settingsButton.hidden = true
            moreButton.hidden = false
        }
        
        if notFromTabBar {
            backButton.hidden = false
        }
        
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
            lastAvailable.text = self.initializeTimeLabel(lastavailable)
        }
        
        if !ownProfile {
            getCurrentUser()
        }
    }
    
    func getCurrentUser(){
        CurrentUser.sharedInstance.getCurrentUser(){
            guard let user = CurrentUser.sharedInstance.user else { return }
            self.currentUser = user
            self.checkFriendsStatus(){
                self.updateButtonLabels()
            }
            self.checkFollowStatus(){
                self.updateButtonLabels()
            }
        }
    }
    
    func checkFriendsStatus(completion: ()->()){
        if let uid = self.user.uid {
            CurrentUser.sharedInstance.checkFriendStatus(uid, completion: {(friendsStatus) in
                self.currentUser = CurrentUser.sharedInstance.user
                self.friendsStatus = friendsStatus
                completion()
            })
        }
    }
    
    func checkFollowStatus(completion: ()->()){
        if let uid = self.user.uid {
            self.user.getFollowers(){
                if let followers = self.user.followers {
                    guard let uid = self.currentUser.uid else { return }
                    if followers[uid] != nil {
                        self.followStatus = FollowStatus.Follower
                    } else {
                        self.followStatus = FollowStatus.NotFollower
                    }
                    completion()
                }
            }
        }
    }
    
    func updateButtonLabels(){
        if let friendsStatus = self.friendsStatus {
            blueButton.setTitle(friendsStatus.blueButtonLabel, forState: .Normal)
        } else {
            blueButton.setTitle("", forState: .Normal)
        }
        if let followStatus = self.followStatus {
            redButton.setTitle(followStatus.redButtonLabel, forState: .Normal)
        } else {
            redButton.setTitle("", forState: .Normal)
        }
        yellowButton.setTitle("SEND A MESSAGE", forState: .Normal)
    }

    @IBAction func onYellowPressed(sender: AnyObject) {
        performSegueWithIdentifier("chatVCFromProfile", sender: nil)
    }
    
    @IBAction func onBluePressed(sender: AnyObject) {
        if let friendsStatus = friendsStatus {
            blueButton.userInteractionEnabled = false
            friendsStatus.addInteraction(self.user.uid){
                self.checkFriendsStatus(){
                    self.updateButtonLabels()
                    self.blueButton.userInteractionEnabled = true
                }
            }
        }
    }
    
    @IBAction func onRedPressed(sender: AnyObject) {
        if let followStatus = followStatus {
            redButton.userInteractionEnabled = false
            followStatus.followInteraction(self.user.uid){
                self.checkFollowStatus(){
                    self.updateButtonLabels()
                    self.redButton.userInteractionEnabled = true
                }
            }
        }
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
    
    @IBAction func onMoreButtonPressed(sender: AnyObject) {
        openAlertController()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileVC" {
            var destinationVC = segue.destinationViewController as! editProfileVC
            destinationVC.user = user
        } else if segue.identifier == "chatVCFromProfile" {
            var destinationVC = segue.destinationViewController as! chatVC
            destinationVC.otherUser = user
            destinationVC.senderId = currentUser.uid
            destinationVC.senderDisplayName = currentUser.displayName
        }
    }
    
    
    func refreshView(sender: AnyObject){
        downloadUserAndInitializeView()
        self.refreshControl.endRefreshing()
    }
    
    func openAlertController(){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let reportAction = UIAlertAction(title: "Report", style: .Destructive) { action -> Void in
            let reportVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewControllerWithIdentifier("ReportVC") as! ReportVC
            reportVC.userUid = self.user.uid
            self.presentViewController(reportVC, animated: true, completion: nil)
        }
        alertController.addAction(reportAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func initializeTimeLabel(lastavailable: NSTimeInterval) -> String {
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
        
        return "AVAILABLE \(timeDifference.0) \(suffix)\(plural) AGO"
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
