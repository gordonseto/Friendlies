//
//  messagesListCell.swift
//  Friendlies
//
//  Created by Gordon Seto on 2016-07-20.
//  Copyright © 2016 gordonseto. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class MessagesListCell: UITableViewCell {

    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var conversationPhoto: profilePhoto!
    @IBOutlet weak var messageText: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
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
        if let time = conversationPreview.lastMessageTime {
            print(time)
            timeLabel.text = getMessageListDateString(time)
        }
        
        if !conversationPreview.seen {
            messageText.font = UIFont(name: "HelveticaNeue-Bold", size: 15)
            messageText.textColor = UIColor.whiteColor()
            timeLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 15)
            timeLabel.textColor = UIColor.whiteColor()
        } else {
            messageText.font = UIFont(name: "HelveticaNeue", size: 15)
            messageText.textColor = UIColor.lightGrayColor()
            timeLabel.font = UIFont(name: "HelveticaNeue", size: 15)
            timeLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
    func getMessageListDateString(time: NSTimeInterval) -> String {
        let currentDate = NSDate()
        let date = NSDate(timeIntervalSince1970: time)
        let sharedFormatter = JSQMessagesTimestampFormatter()
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.setLocalizedDateFormatFromTemplate("YY")
        let currentYear = dateFormatter.stringFromDate(currentDate)
        let messageYear = dateFormatter.stringFromDate(date)
        
        dateFormatter.setLocalizedDateFormatFromTemplate("DD")
        let currentNum = dateFormatter.stringFromDate(currentDate)
        let dateNum = dateFormatter.stringFromDate(date)
        
        if currentYear == messageYear {
        
            if dateNum == currentNum {  //same day, display time
                return sharedFormatter.timeForDate(date)
            }
            
            if Int(currentNum)! - Int(dateNum)! < 4 { //within 4 days, display day of week
                dateFormatter.setLocalizedDateFormatFromTemplate("EE")
                return dateFormatter.stringFromDate(date)
            }
        }
        
        dateFormatter.dateStyle = .MediumStyle  //display month day
        var monthDay = dateFormatter.stringFromDate(date)
        monthDay = monthDay.componentsSeparatedByString(",")[0]
        print(monthDay)
        return monthDay
    }
}
