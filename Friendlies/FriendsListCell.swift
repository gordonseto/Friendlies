//
//  friendsListCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-18.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

protocol FriendsListCellDelegate: class {
    func AcceptButtonPressed(uid: String)
    func DeclineButtonPressed(uid: String)
}

class FriendsListCell: UITableViewCell {

    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var lastAvailable: UILabel!
    @IBOutlet weak var characterStackView: UIStackView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    var isFriendRequest: Bool = false
    var uid: String!
    weak var delegate: FriendsListCellDelegate!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    func configureCell(user: User){
        
        uid = user.uid
        
        if let name = user.displayName {
            displayName.text = name
        }
        if let image = user.profilePhoto {
            profilePhoto.image = image
        }
        
        if isFriendRequest {
            lastAvailable.text = "WANTS TO ADD YOU"
            lastAvailable.textColor = UIColor.whiteColor()
            acceptButton.hidden = false
            declineButton.hidden = false
            
            for stackView in characterStackView.subviews {
                stackView.removeFromSuperview()
            }
            
        } else {
            lastAvailable.textColor = UIColor.darkGrayColor()
            if let lastavailable = user.lastAvailable {
                lastAvailable.text = initializeTimeLabel(user.lastAvailable)
            }
            
            acceptButton.hidden = true
            declineButton.hidden = true
            
            arrangeStackViewCharacters(user, characterStackView: self.characterStackView, height: 20)
        }
        
    }

    @IBAction func onAcceptButtonPressed(sender: AnyObject) {
        if let uid = uid {
            delegate?.AcceptButtonPressed(uid)
        }
    }
    @IBAction func onDeclineButtonPressed(sender: AnyObject) {
        if let uid = uid {
            delegate?.DeclineButtonPressed(uid)
        }
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
