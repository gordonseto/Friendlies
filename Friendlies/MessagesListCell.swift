//
//  messagesListCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-20.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit

class MessagesListCell: UITableViewCell {

    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var conversationPhoto: profilePhoto!
    @IBOutlet weak var messageText: UILabel!
    
    var conversationPreview: ConversationPreview!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func configureCell(conversationPreview: ConversationPreview){
        self.conversationPreview = conversationPreview
        if let name = conversationPreview.displayName {
            displayName.text = name
        }
        if let message = conversationPreview.lastMessage {
            messageText.text = message
        }
        if let photo = conversationPreview.profilePhoto {
            conversationPhoto.image = photo
        }
    }
}
