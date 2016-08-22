//
//  friendliesButton.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class friendliesButton: UIButton {

    override func awakeFromNib() {
        self.layer.cornerRadius = self.bounds.size.height * 0.5
        self.clipsToBounds = true
    }

}
