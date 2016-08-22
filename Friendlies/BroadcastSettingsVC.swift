//
//  BroadcastSettingsVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-09.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import SloppySwiper
import DLRadioButton
import FirebaseDatabase

class BroadcastSettingsVC: UIViewController {

    @IBOutlet weak var everyoneButton: DLRadioButton!
    
    var currentUser: User!
    var onlyFriends: Bool = false
    
    var swiper: SloppySwiper!
    
    var firebase: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationcontroller = self.navigationController {
            swiper = SloppySwiper(navigationController: navigationcontroller)
            navigationcontroller.delegate = swiper
        }
        
        getCurrentUser()
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let currentUser = currentUser {
            if everyoneButton.selected == true {
                firebase = FIRDatabase.database().reference()
                firebase.child("users").child(currentUser.uid).child("onlyFriends").setValue(nil)
            } else {
                firebase = FIRDatabase.database().reference()
                firebase.child("users").child(currentUser.uid).child("onlyFriends").setValue(true)
            }
        }
        CurrentUser.sharedInstance.getCurrentUser(){}
        super.viewWillDisappear(animated)
    }
    
    func getCurrentUser(){
        if let user = CurrentUser.sharedInstance.user {
            currentUser = user
            onlyFriends = currentUser.onlyFriends
            setRadioButtons()
        } else {
            CurrentUser.sharedInstance.getCurrentUser(){
                self.currentUser = CurrentUser.sharedInstance.user
                self.onlyFriends = self.currentUser.onlyFriends
                self.setRadioButtons()
            }
        }
    }
    
    func setRadioButtons(){
        if onlyFriends {
            everyoneButton.selected = false
            everyoneButton.otherButtons[0].selected = true
        } else {
            everyoneButton.selected = true
            everyoneButton.otherButtons[0].selected = false
        }
    }

    @IBAction func onBackButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }

}
