//
//  settingsVC.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-15.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import FirebaseDatabase

class editProfileVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userPhoto: profilePhoto!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var gamerTag: friendliesTextField!
    
    @IBOutlet weak var character1: UIButton!
    @IBOutlet weak var character2: UIButton!
    @IBOutlet weak var character3: UIButton!
    @IBOutlet weak var character4: UIButton!
    @IBOutlet weak var character5: UIButton!
    
    
    var user: User!
    let MAX_TEXT = 17
    var characters = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
        
        gamerTag.delegate = self
        
        if let user = user {
            initializeView()
        }
    }
    
    func initializeView() {
        if let name = user.displayName {
            userName.text = name
        }
        if let photo = user.profilePhoto {
            userPhoto.image = photo
        }
        if let tag = user.gamerTag {
            gamerTag.text = tag
        }
        if let characters = user.characters {
            self.characters = characters
            updateChosenCharacters()
        }
    }

    @IBAction func onDonePressed(sender: AnyObject) {
        if let uid = NSUserDefaults.standardUserDefaults().objectForKey("USER_UID") as? String {
            let firebase = FIRDatabase.database().reference()
            if let tag = gamerTag.text {
                firebase.child("users").child(uid).child("gamerTag").setValue(tag)
            }
            firebase.child("users").child(uid).child("characters").setValue(characters)
            if let navController = self.navigationController {
                let pVC = self.navigationController?.viewControllers[0] as! profileVC
                pVC.initializeViewWithUser()
                navController.popViewControllerAnimated(true)
            }
        }
    }
    
    @IBAction func onCancelPressed(sender: AnyObject) {
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func onChosenCharacterTapped(sender: UIButton) {
        let tag = sender.tag
        if tag < characters.count {
            characters.removeAtIndex(tag)
            let delay = 0.01 * Double(NSEC_PER_SEC)
            self.updateChosenCharacters()
        }
    }
    
    @IBAction func onCharacterTapped(sender: UIButton) {
        if characters.count < MAX_CHOSEN_CHARACTERS {
            let tag = "\(sender.tag)"
            if !characters.contains(tag){
                characters.append(tag)
                updateChosenCharacters()
            }
        }
    }
    
    func updateChosenCharacters() {
        let delay = 0.01 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            if self.characters.indices.contains(0) {
                self.character1.imageView?.image = UIImage(named: self.characters[0])
            } else {
                self.character1.imageView?.image = UIImage(named: "default_character")
            }
            if self.characters.indices.contains(1) {
                self.character2.imageView?.image = UIImage(named: self.characters[1])
            } else {
                self.character2.imageView?.image = UIImage(named: "default_character")
            }
            if self.characters.indices.contains(2) {
                self.character3.imageView?.image = UIImage(named: self.characters[2])
            } else {
                self.character3.imageView?.image = UIImage(named: "default_character")
            }
            if self.characters.indices.contains(3) {
                self.character4.imageView?.image = UIImage(named: self.characters[3])
            } else {
                self.character4.imageView?.image = UIImage(named: "default_character")
            }
            if self.characters.indices.contains(4) {
                self.character5.imageView?.image = UIImage(named: self.characters[4])
            } else {
                self.character5.imageView?.image = UIImage(named: "default_character")
            }
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.placeholder = nil
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.placeholder = "No Tag Entered"
    }
    
    func textField(textField: UITextField,shouldChangeCharactersInRange range: NSRange,replacementString string: String) -> Bool
    {
        let maxtext: Int = MAX_TEXT
        
        guard let text = textField.text else { return true }
        
        if string == "\n" {
            textField.resignFirstResponder()
            return false
        }
        
        let newLength = text.characters.count + string.characters.count - range.length
        if newLength > MAX_TEXT {
            return false
        } else {
            return true
        }
    }
    
}
