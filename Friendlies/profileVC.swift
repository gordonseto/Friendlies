//
//  profileVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseAuth

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
    
    @IBOutlet weak var messageButton: friendliesButton!
    @IBOutlet weak var addButton: friendliesButton!
    @IBOutlet weak var blockButton: friendliesButton!
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var ownProfile: Bool = true
    var user: User!
    var uid: String!
    
    var refreshControl: UIRefreshControl!

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
            initializeViewWithUser()
        } else {
            if ownProfile {
                if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
                    user = User(uid: uid)
                    initializeViewWithUser()
                }
            }
        }
        
        if ownProfile {
            settingsButton.hidden = false
        }
    }
    
    func initializeViewWithUser() {
        
        user.downloadUserInfo() {
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
        
        }
    }
    

    @IBAction func onMessagePressed(sender: AnyObject) {
    }
    @IBAction func onAddPressed(sender: AnyObject) {
    }
    @IBAction func onBlockPressed(sender: AnyObject) {
    }
    
    @IBAction func onSettingsPressed(sender: AnyObject) {
        if user != nil {
            performSegueWithIdentifier("editProfileVC", sender: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileVC" {
            var destinationVC = segue.destinationViewController as! editProfileVC
            destinationVC.user = user
        }
    }
    
    func refreshView(sender: AnyObject){
        initializeViewWithUser()
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
