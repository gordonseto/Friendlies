//
//  General.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-09-04.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import Foundation

func arrangeStackViewCharacters(user: User, characterStackView: UIStackView, height: CGFloat){
    for stackView in characterStackView.subviews {
        stackView.removeFromSuperview()
    }
    
    if let characters = user.characters {
        for character in characters {
            let imageView = UIImageView()
            imageView.image = UIImage(named: character)
            imageView.heightAnchor.constraintEqualToConstant(height).active = true
            imageView.widthAnchor.constraintEqualToConstant(height).active = true
            characterStackView.addArrangedSubview(imageView)
        }
    }
}

func getBroadcastTime(time: NSTimeInterval) -> (value: String, unit: String) {
    if time == 0 {
        return ("", "")
    }
    let currentTime = NSDate().timeIntervalSince1970
    var timeDifference = currentTime - time
    if timeDifference < 60 { // seconds
        return ("\(Int(timeDifference))", "s")
    } else {
        timeDifference /= 60.0
        if timeDifference < 60 { //minutes
            return ("\(Int(timeDifference))", "m")
        } else {
            timeDifference /= 60.0
            if timeDifference < 24 { //hours
                return ("\(Int(timeDifference))", "h")
            } else {
                timeDifference /= 24.0
                if timeDifference < 7 { //days
                    return ("\(Int(timeDifference))", "d")
                } else {
                    timeDifference /= 7.0
                    if timeDifference < 52.0 { //weeks
                        return ("\(Int(timeDifference))", "w")
                    } else {
                        return ("\(Int(timeDifference))", "y") //years
                    }
                }
            }
        }
    }
}