//
//  feedVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseAuth

class feedVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let user = FIRAuth.auth()?.currentUser {
            print(user.displayName)
            print(user.photoURL)
        }
    }


}
