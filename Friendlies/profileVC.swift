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
        for stackView in characterStackView.subviews {
            stackView.removeFromSuperview()
        }
        user.downloadUserInfo() {
            if let name = self.user.displayName {
                self.displayName.text = name
            }
            if let tag = self.user.gamerTag {
                self.gamerTag.text = tag
            }
            if let characters = self.user.characters {
                for character in characters {
                    let imageView = UIImageView()
                    imageView.image = UIImage(named: character)
                    imageView.heightAnchor.constraintEqualToConstant(30).active = true
                    imageView.widthAnchor.constraintEqualToConstant(30).active = true
                    self.characterStackView.addArrangedSubview(imageView)
                }
            }
            if self.userPhoto.image == nil {
                self.user.getUserProfilePhoto(){
                    self.userPhoto.image = self.user.profilePhoto
                }
            }
        }
    }
    

    @IBAction func onMessagePressed(sender: AnyObject) {
        let lvc = generateLoginVC()
        self.presentViewController(lvc, animated: true, completion: nil)
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
}
