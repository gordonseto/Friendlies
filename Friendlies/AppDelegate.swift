//
//  AppDelegate.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import Batch
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        UITabBar.appearance().backgroundColor = UIColor.blackColor()
        
        FIRApp.configure()
        
        Batch.startWithAPIKey(BATCH_DEV_API_KEY)
        BatchPush.registerForRemoteNotifications()
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        print(userInfo["com.batch"])
        print(userInfo["com.batch"]!["l"])
        if let deepLink = userInfo["com.batch"]?["l"] as? String {
            let queryArray = deepLink.componentsSeparatedByString("/")
            let queryType = queryArray[2]
            /*
            if queryType == "friends" {
                refreshFriendsList()
            }
            */
            updateTabBarBadge(queryType)
            updateIconBadge()
        }
        completionHandler(UIBackgroundFetchResult.NewData)
    }
    
    func updateTabBarBadge(queryType: String){
        if let user = FIRAuth.auth()?.currentUser {
            let firebase = FIRDatabase.database().reference()
            firebase.child("notifications").child(user.uid).child(queryType).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                print(snapshot.childrenCount)
                
                var index: Int!
                if queryType == "messages" {
                    index = MESSAGES_INDEX
                } else if queryType == "friends" {
                    index = FRIENDS_INDEX
                } else if queryType == "follows" {
                    index = FEED_INDEX
                }
                if index != nil {
                    if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
                        if snapshot.childrenCount == 0 {
                            tabBarController.tabBar.items?[index].badgeValue = nil
                        } else {
                            tabBarController.tabBar.items?[index].badgeValue = "\(snapshot.childrenCount)"
                        }
                    }
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    /*
    func refreshFriendsList(){
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            if let friendsNVC = tabBarController.viewControllers![FRIENDS_INDEX] as? UINavigationController {
                if let friendsVC = friendsNVC.viewControllers[0] as? friendsListVC {
                    friendsVC.updateNotifications = false
                    friendsVC.getCurrentUsersFriends()
                }
            }
        }
    }*/

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        if url.host == nil {
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        }
        
        let urlString = url.absoluteString
        let queryArray = urlString.componentsSeparatedByString("/")
        let queryType = queryArray[2]
        let query = queryArray[3]
        var queryParameter: String!
        if queryArray.count > 4 {
            queryParameter = queryArray[4]
        }
        print(query as String!)
        
        if queryType == "messages" {
            if let queryParameter = queryParameter {
                goToConversation(query, otherUserUid: queryParameter)
            }
        } else if queryType == "friends" {
            goToFriendsList()
        } else if queryType == "follows" {
            goToFeed()
        }
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func goToFeed(){
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = FEED_INDEX
            if let feedNVC = tabBarController.viewControllers![FEED_INDEX] as? UINavigationController {
                if let feedVC = feedNVC.viewControllers[0] as? feedVC {
                    feedVC.queryBroadcasts()
                }
            }
        }
    }
    
    func goToFriendsList(){
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = FRIENDS_INDEX
            if let friendsNVC = tabBarController.viewControllers![FRIENDS_INDEX] as? UINavigationController {
                if let friendsVC = friendsNVC.viewControllers[0] as? friendsListVC {
                    friendsVC.getCurrentUsersFriends()
                }
            }
        }
    }

    
    func goToConversation(conversationId: String, otherUserUid: String) {
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
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
        //messages.performSegueWithIdentifier("chatVC", sender: item)
    }

}

