//
//  SettingsVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-08.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import SloppySwiper
import FirebaseAuth
import FBSDKLoginKit

class SettingsVC: UIViewController {

    var swiper: SloppySwiper!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationcontroller = self.navigationController {
            swiper = SloppySwiper(navigationController: navigationcontroller)
            navigationcontroller.delegate = swiper
        }
    }

    @IBAction func onBackButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func onBroadcastSettingsPressed(sender: UITapGestureRecognizer) {
        performSegueWithIdentifier("broadcastSettingsVC", sender: nil)
    }
    
    @IBAction func onBlockingSettingsPressed(sender: UITapGestureRecognizer) {
        performSegueWithIdentifier("blockingSettingsVC", sender: nil)
    }
    
    @IBAction func onViewTutorialPressed(sender: UITapGestureRecognizer) {
    }
    
    @IBAction func onLogoutPressed(sender: AnyObject) {
        confirmLogout()
    }
    
    func confirmLogout(){
        let alertController = UIAlertController(title: "Are you sure you want to logout?", message: nil, preferredStyle: .ActionSheet)
        
        let logoutAction = UIAlertAction(title: "Logout", style: .Destructive) { action -> Void in
            self.logoutUser()
        }
        alertController.addAction(logoutAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func logoutUser(){
        CurrentUser.sharedInstance.user = nil
        try! FIRAuth.auth()!.signOut()
        if let tabBarController: UITabBarController = self.view.window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = FEED_INDEX
            if let feedNVC = tabBarController.viewControllers![FEED_INDEX] as? UINavigationController {
                if let feedVC = feedNVC.viewControllers[0] as? feedVC {
                    feedVC.presentLoginVC()
                }
            }
        }
    }
}
