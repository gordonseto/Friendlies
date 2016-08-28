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
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        UITabBar.appearance().backgroundColor = UIColor.blackColor()
        
        Batch.startWithAPIKey(BATCH_API_KEY)
        
        FIRApp.configure()
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        
        Fabric.with([Crashlytics.self])
    
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String: AnyObject] {
                if let deepLink = notification["com.batch"]?["l"] as? String {
                    NotificationsManager.sharedInstance.goToCertainView(deepLink, tabBarController: tabBarController)
                }
            } else {
                NotificationsManager.sharedInstance.updateTabBar(tabBarController)
            }
        }
        
        print("did finish launching with options")
        
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
        BatchPush.dismissNotifications()
        print("did become active")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            if application.applicationState == UIApplicationState.Active {
                //print("application state active")
                NotificationsManager.sharedInstance.updateTabBar(tabBarController)
            } else if application.applicationState == UIApplicationState.Background {
                //print("application state background")
                NotificationsManager.sharedInstance.updateTabBar(tabBarController)
            } else if application.applicationState == UIApplicationState.Inactive {
                //print("application state inactive")
                print(userInfo)
                if let deepLink = userInfo["com.batch"]?["l"] as? String {
                    NotificationsManager.sharedInstance.goToCertainView(deepLink, tabBarController: tabBarController)
                }
            }
        }
        completionHandler(.NewData)
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

