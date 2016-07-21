//
//  ViewController.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseDatabase
import Batch

class loginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func onFacebookLoginPressed(sender: AnyObject) {
        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default
        
        var login = FBSDKLoginManager()
        login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
            
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
            
            if error != nil {
                print(error)
            } else if result.isCancelled {
                print("cancelled")
            } else {
                print("logged in")
                print(result.token.userID)
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    if error != nil {
                        print(error)
                    } else {
                        if let user = FIRAuth.auth()?.currentUser {
                            NSUserDefaults.standardUserDefaults().setObject(user.uid, forKey: "USER_UID")
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            let firebase = FIRDatabase.database().reference()
                            firebase.child("users").child(user.uid).child("facebookId").setValue(result.token.userID)
                            firebase.child("users").child(user.uid).child("displayName").setValue(user.displayName!)
                            firebase.child("displayNames").child(user.displayName!).child("uid").setValue(user.uid)
                            firebase.child("displayNames").child(user.displayName!).child("facebookId").setValue(result.token.userID)
                            
                            let editor = BatchUser.editor()
                            editor.setIdentifier(user.uid)
                            editor.save()
                            
                            self.dismissViewControllerAnimated(true, completion: nil)
                        } else {
                            print("error with FIR authorization")
                        }
                    }
                }
            }
        }
    }
}

