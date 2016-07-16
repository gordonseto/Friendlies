//
//  friendliesTextField.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class friendliesTextField: UITextField {

    override func awakeFromNib() {
        self.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
    }

}
