//
//  BroadcastCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-16.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class BroadcastCell: UITableViewCell {
    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var gamerTag: UILabel!
    @IBOutlet weak var userPhoto: profilePhoto!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var broadcastDesc: UITextView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var setupLabel: UILabel!
    @IBOutlet weak var setupSwitch: UISwitch!
    
    var broadcast: Broadcast!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureCell(broadcast: Broadcast) {
        self.broadcast = broadcast
        setupSwitch.transform = CGAffineTransformMakeScale(0.5, 0.5)
    }
    
    @IBAction func onSwitchChanged(sender: AnyObject){
        print("hi")
    }

}
