//
//  friendsListCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-18.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class FriendsListCell: UITableViewCell {

    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var profilePhoto: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    func configureCell(user: User){
        if let name = user.displayName {
            displayName.text = name
        }
    }
}
