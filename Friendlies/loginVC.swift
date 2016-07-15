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

class loginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func onFacebookLoginPressed(sender: AnyObject) {
        var login = FBSDKLoginManager()
        login.logInWithReadPermissions(["public_profile"], fromViewController: self) { (result, error) in
            if error != nil {
                print("error")
            } else if result.isCancelled {
                print("cancelled")
            } else {
                print("logged in")
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                    if error != nil {
                        print(error)
                    } else {
                        if let user = FIRAuth.auth()?.currentUser {
                            self.performSegueWithIdentifier("feedVC", sender: nil)
                        } else {
                            print("error with FIR authorization")
                        }
                    }
                }
            }
        }
    }
}

