//
//  BlockedSettingsCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-08-08.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

protocol BlockingSettingsCellDelegate: class {
    func unblockUser(uid: String)
    func blockUser(uid: String)
}

class BlockingSettingsCell: UITableViewCell {

    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var blockButton: UIButton!
    
    weak var delegate: BlockingSettingsCellDelegate!
    
    var user: User!
    var isBlocked: Bool = true
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    func configureCell(user: User){
        self.user = user
        displayName.text = user.displayName
    }
    
    @IBAction func onBlockButtonPressed(sender: AnyObject) {
        if isBlocked{
            isBlocked = false
            delegate?.unblockUser(user.uid)
            blockButton.setTitle("BLOCK", forState: .Normal)
        } else {
            isBlocked = true
            delegate?.blockUser(user.uid)
            blockButton.setTitle("UNBLOCK", forState: .Normal)
        }
    }
}
