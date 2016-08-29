//
//  NotificationsManager.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-27.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation

import Foundation
import FirebaseDatabase
import FirebaseAuth
import UIKit

class NotificationsManager {
    static let sharedInstance = NotificationsManager()
    private init() {}
    
    func sendNotification(toUserUid: String, hasSound: Bool, groupId: String, message: String, deeplink: String){
        if let pushClient = BatchClientPush(apiKey: BATCH_API_KEY, restKey: BATCH_REST_KEY) {
            
                pushClient.sandbox = false
                if hasSound {
                    pushClient.customPayload = ["aps": ["badge": 1, "content-available": 1]]
                } else {
                    pushClient.customPayload = ["aps": ["badge": 1, "sound": NSNull(), "content-available": 1]]
                }
                pushClient.groupId = groupId
                pushClient.message.title = "Friendlies"
                pushClient.message.body = message
                pushClient.recipients.customIds = [toUserUid]
                pushClient.deeplink = deeplink
                
                pushClient.send { (response, error) in
                    if let error = error {
                        print("Something happened while sending the push: \(response) \(error.localizedDescription)")
                    } else {
                        print("Push sent \(response)")
                    }
                }
        } else {
            print("Error while initializing BatchClientPush")
        }
    }
    
    func addToNotifications(uid: String, notificationType: String, param1: String){
        let firebase = FIRDatabase.database().reference()
        firebase.child("notifications").child(uid).child(notificationType).child(param1).setValue(true)
    }
    
    func removeFromNotifications(uid: String, notificationType: String, param1: String){
        let firebase = FIRDatabase.database().reference()
        firebase.child("notifications").child(uid).child(notificationType).child(param1).setValue(nil)
    }
    
    func removeAllNotificationsOfType(uid: String, notificationType: String){
        let firebase = FIRDatabase.database().reference()
        firebase.child("notifications").child(uid).child(notificationType).setValue(nil)
    }
    
    func updateTabBar(tabBarController: UITabBarController){
        print("update tab bar")

        if let uid = FIRAuth.auth()?.currentUser?.uid {
            getUsersNotifications(uid){(var notifications) in
                if notifications["friends"] == "0" {
                    notifications["friends"] = nil
                }
                if notifications["follows"] == "0" {
                    notifications["follows"] = nil
                }
                if notifications["messages"] == "0" {
                    notifications["messages"] = nil
                }
                tabBarController.tabBar.items?[FEED_INDEX].badgeValue = notifications["follows"]
                tabBarController.tabBar.items?[MESSAGES_INDEX].badgeValue = notifications["messages"]
                tabBarController.tabBar.items?[FRIENDS_INDEX].badgeValue = notifications["friends"]
            }
        }
    }
    
    func clearTabBarBadgeAtIndex(index: Int, tabBarController: UITabBarController){
        print("clear tab bar")
        if tabBarController.tabBar.items?[index].badgeValue != nil {
            print("tab bar is not nil")
            tabBarController.tabBar.items?[index].badgeValue = nil
            if let uid = FIRAuth.auth()?.currentUser?.uid {
                let firebase = FIRDatabase.database().reference()
                var notificationType: String = ""
                if index == FEED_INDEX {
                    notificationType = "follows"
                }
                if index == MESSAGES_INDEX {
                    notificationType = "messages"
                }
                if index == FRIENDS_INDEX {
                    notificationType = "friends"
                }
                firebase.child("notifications").child(uid).child(notificationType).setValue(nil)
            }
        }
    }
    
    func getUsersNotifications(uid: String, completion:([String: String])->()){
        let firebase = FIRDatabase.database().reference()
        firebase.child("notifications").child(uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            let friends = snapshot.value!["friends"] as? [String: Bool] ?? [:]
            let follows = snapshot.value!["follows"] as? [String: Bool] ?? [:]
            let messages = snapshot.value!["messages"] as? [String: Bool] ?? [:]
            completion(["friends": "\(friends.count)", "follows": "\(follows.count)", "messages": "\(messages.count)"])
        })
    }
    
    func goToCertainView(deepLink: String, tabBarController: UITabBarController){
        print("go to certain view")
        let queryArray = deepLink.componentsSeparatedByString("/")
        let queryType = queryArray[2]
        if queryType == "follows" {
            goToFeed(tabBarController)
        } else if queryType == "friends" {
            let otherUserUid = queryArray[3]
            goToFriendsList(tabBarController)
        } else if queryType == "messages" {
            let conversationId = queryArray[3]
            let otherUserUid = queryArray[4]
            goToConversation(conversationId, otherUserUid: otherUserUid, tabBarController: tabBarController)
        }
    }
    
    func goToFeed(tabBarController: UITabBarController){
        tabBarController.selectedIndex = FEED_INDEX
    }
    
    func goToFriendsList(tabBarController: UITabBarController){
        tabBarController.selectedIndex = FRIENDS_INDEX
    }
    
    
    func goToConversation(conversationId: String, otherUserUid: String, tabBarController: UITabBarController) {
        tabBarController.selectedIndex = MESSAGES_INDEX
        if let messagesNVC = tabBarController.viewControllers![MESSAGES_INDEX] as? UINavigationController {
            if let messagesVC = messagesNVC.viewControllers[0] as? messagesListVC {
                if let user = FIRAuth.auth()?.currentUser {
                    let item: NSDictionary = [
                        "conversationId": conversationId,
                        "otherUserUid": otherUserUid,
                        "senderId": user.uid,
                        "senderDisplayName": user.displayName!
                    ]
                    if let topVC = messagesNVC.topViewController as? chatVC {
                        if !(topVC.conversationId == conversationId) {
                            messagesVC.performSegueWithIdentifier("chatVCFromDeepLink", sender: item)
                        }
                    } else {
                        messagesVC.performSegueWithIdentifier("chatVCFromDeepLink", sender: item)
                    }
                }
            }
        }
    }
    
}