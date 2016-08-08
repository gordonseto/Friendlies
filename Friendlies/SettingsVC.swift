//
//  SettingsVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-08.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import SloppySwiper

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
}
