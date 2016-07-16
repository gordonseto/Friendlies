//
//  profilePhoto.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class profilePhoto: UIImageView {

    override func awakeFromNib() {
        self.layer.cornerRadius = 0.5 * self.bounds.size.width
        self.clipsToBounds = true
    }

}
