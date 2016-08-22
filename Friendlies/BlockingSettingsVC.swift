//
//  BlockingSettingsVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-08.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SloppySwiper

class BlockingSettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, BlockingSettingsCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var isBlocking: [String: Bool]!
    var blockedUsers: [User]!
    
    var currentUser: User!
    
    var swiper: SloppySwiper!
    
    var firebase: FIRDatabaseReference!
    
    var noBlockedUsersLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationcontroller = self.navigationController {
            swiper = SloppySwiper(navigationController: navigationcontroller)
            navigationcontroller.delegate = swiper
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.delaysContentTouches = false
        
        noBlockedUsersLabel = UILabel(frame: CGRectMake(0, 0, 220, 120))
        
        blockedUsers = []
        
        getBlockedUsers()
    }
    
    func getBlockedUsers(){
        if let user = CurrentUser.sharedInstance.user {
            self.currentUser = user
            self.currentUser.getBlockedInfo(){
                self.isBlocking = self.currentUser.isBlocking
                self.getBlockedInfo()
            }
        } else {
            CurrentUser.sharedInstance.getCurrentUser(){
                self.currentUser = CurrentUser.sharedInstance.user
                self.currentUser.getBlockedInfo(){
                    self.isBlocking = self.currentUser.isBlocking
                    self.getBlockedInfo()
                }
            }
        }
    }
    
    func getBlockedInfo(){
        blockedUsers = []
        for (uid, _) in isBlocking {
            let user = User(uid: uid)
            user.downloadUserInfo(){_ in 
                self.blockedUsers.append(user)
                if self.blockedUsers.count == self.isBlocking.count {
                    self.doneRetreivingUsers()
                }
            }
        }
        if isBlocking.count == 0 {
            tableView.reloadData()
            displayBackgroundMessage("You have not blocked any users.", label: noBlockedUsersLabel, viewToAdd: tableView)
        }
    }
    
    func doneRetreivingUsers(){
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BlockingSettingsCell", forIndexPath: indexPath) as! BlockingSettingsCell
        let user = blockedUsers[indexPath.row]
        cell.delegate = self
        cell.configureCell(user)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func blockUser(uid: String) {
        currentUser.blockUser(uid){}
    }
    
    func unblockUser(uid: String) {
        currentUser.unBlockUser(uid){}
    }

    @IBAction func onBackButtonPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }

}
