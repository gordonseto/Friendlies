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
    @IBOutlet weak var lastAvailable: UILabel!
    @IBOutlet weak var characterStackView: UIStackView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    func configureCell(user: User){
        if let name = user.displayName {
            displayName.text = name
        }
        if let image = user.profilePhoto {
            profilePhoto.image = image
        }
        if let lastavailable = user.lastAvailable {
            lastAvailable.text = initializeTimeLabel(user.lastAvailable)
        }
        
        arrangeStackViewCharacters(user, characterStackView: self.characterStackView, height: 20)
        
    }
    
    func initializeTimeLabel(lastavailable: NSTimeInterval) -> String {
        var timeDifference = getBroadcastTime(lastavailable)
        var suffix: String = ""
        if timeDifference.1 == "s" {
            suffix = "SECOND"
        }
        if timeDifference.1 == "m" {
            suffix = "MINUTE"
        }
        if timeDifference.1 == "h" {
            suffix = "HOUR"
        }
        if timeDifference.1 == "d" {
            suffix = "DAY"
        }
        if timeDifference.1 == "w" {
            suffix = "WEEK"
        }
        if timeDifference.1 == "Y" {
            suffix = "YEAR"
        }
        var plural: String = ""
        if timeDifference.0 != "1" {
            plural = "S"
        }
        
        return "AVAILABLE \(timeDifference.0) \(suffix)\(plural) AGO"
    }
}
