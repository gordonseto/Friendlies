//
//  BroadcastCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-16.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase
import FirebaseAuth

protocol BroadcastCellDelegate: class {
    func onTextViewEditing(textView: UITextView)
    func onRemoveButtonPressed(broadcast: Broadcast, button: UIButton)
}

class BroadcastCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var userPhoto: profilePhoto!
    @IBOutlet weak var characterStackView: UIStackView!
    @IBOutlet weak var broadcastDesc: UITextView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var setupLabel: UILabel!
    @IBOutlet weak var setupSwitch: UISwitch!
    @IBOutlet weak var removeButton: UIButton!
    
    var broadcast: Broadcast!
    
    var firebase: FIRDatabaseReference!
    
    weak var delegate: BroadcastCellDelegate!
    
    let MAX_TEXT = 80
    
    var isAuthor: Bool = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func configureCell(broadcast: Broadcast) {
        if let author = broadcast.user {
        self.broadcast = broadcast

            broadcastDesc.delegate = self
        
            displayName.text = broadcast.user.displayName
            gamerTag.text = broadcast.user.gamerTag
            broadcastDesc.text = broadcast.broadcastDesc
            timeLabel.text = "\(getBroadcastTime(broadcast.time).0)\(getBroadcastTime(broadcast.time).1)"
            userPhoto.image = broadcast.user.profilePhoto
            
            arrangeStackViewCharacters(author, characterStackView: self.characterStackView, height: 20)
            
            broadcastDesc.keyboardAppearance = UIKeyboardAppearance.Dark
        
            setupSwitch.on = broadcast.hasSetup
            setupSwitch.transform = CGAffineTransformMakeScale(0.5, 0.5)
            
            if let uid = FIRAuth.auth()?.currentUser?.uid {
                if uid == broadcast.authorUid {
                    isAuthor = true
                    enableEditing()
                    removeButton.hidden = false
                } else {
                    isAuthor = false
                    disableEditing()
                    removeButton.hidden = true
                }
            } else {
                isAuthor = false
                disableEditing()
            }
            
            if broadcast.hasSetup {
                setupLabel.textColor = UIColor(red: 38.0/255.0, green: 255.0/255.0, blue: 60.0/255.0, alpha: 1.0)
            } else {
                setupLabel.textColor = UIColor.lightGrayColor()
            }
            
            if !isAuthor {
                setupLabel.alpha = 0.6
            } else {
                setupLabel.alpha = 1.0
            }
            
            removeButton.userInteractionEnabled = true
        }
    }
    
    func enableEditing(){
        setupSwitch.userInteractionEnabled = true
        broadcastDesc.userInteractionEnabled = true
        broadcastDesc.editable = true
        setupSwitch.enabled = true
    }
    
    func disableEditing(){
        setupSwitch.userInteractionEnabled = false
        broadcastDesc.userInteractionEnabled = false
        broadcastDesc.editable = false
        setupSwitch.enabled = false
    }
    
    func findDistanceFrom(userLocation: CLLocation) {
        let distance = userLocation.distanceFromLocation(broadcast.geolocation)
        distanceLabel.text = "\(Int(distance/1000.0)) km away"
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        
        delegate?.onTextViewEditing(textView)

        textView.textColor = UIColor.whiteColor()
        textView.font = UIFont(name: textView.font!.fontName, size: 16)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        broadcast.broadcastDesc = textView.text
        textView.textColor = UIColor.lightGrayColor()
        textView.font = UIFont(name: textView.font!.fontName, size: 14)
        firebase = FIRDatabase.database().reference()
        firebase.child("broadcasts").child(broadcast.key).child("broadcastDesc").setValue(broadcast.broadcastDesc)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let maxtext: Int = MAX_TEXT
        //If the text is larger than the maxtext, the return is false
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return textView.text.characters.count + (text.characters.count - range.length) <= maxtext
    }
    
    @IBAction func onSwitchChanged(sender: AnyObject){
        broadcast.hasSetup = setupSwitch.on
        if broadcast.hasSetup {
            setupLabel.textColor = UIColor(red: 38.0/255.0, green: 255.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        } else {
            setupLabel.textColor = UIColor.lightGrayColor()
        }
        
        if !isAuthor {
            setupLabel.alpha = 0.6
        } else {
            setupLabel.alpha = 1.0
        }
        
        firebase = FIRDatabase.database().reference()
        firebase.child("broadcasts").child(broadcast.key).child("hasSetup").setValue(broadcast.hasSetup)
        
        NSUserDefaults.standardUserDefaults().setObject(setupSwitch.on, forKey: "HAS_SETUP")
    }
    
    @IBAction func onRemovePressed(sender: UIButton){
        delegate?.onRemoveButtonPressed(broadcast, button: sender)
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
