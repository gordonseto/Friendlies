//
//  friendliesView.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-08.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class friendliesView: UIView {

    override func awakeFromNib() {
        
        var topBorder = CALayer()
        topBorder.frame = CGRect(x: 0.0, y: 0.0, width: self.frame.size.width, height: 1.0)
        topBorder.backgroundColor = UIColor.blackColor().CGColor
        
        self.layer.addSublayer(topBorder)
        
        var bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0.0, y: self.frame.size.height, width: self.frame.size.width, height: 1.0)
        bottomBorder.backgroundColor = UIColor.blackColor().CGColor
        
        self.layer.addSublayer(bottomBorder)
    }
}
