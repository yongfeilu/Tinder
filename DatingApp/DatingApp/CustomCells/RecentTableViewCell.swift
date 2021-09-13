//
//  RecentTableViewCell.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/1/21.
//

import UIKit

class RecentTableViewCell: UITableViewCell {

    
    //MARK:  - IBOutlets
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var unreadMessageBackgroundView: UIView!
    @IBOutlet weak var unreadMessageCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        unreadMessageBackgroundView.layer.cornerRadius = unreadMessageBackgroundView.frame.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    func generateCell(recentChat: RecentChat) {
        nameLabel.text = recentChat.receiverName
        lastMessageLabel.text = recentChat.lastMessage
        lastMessageLabel.adjustsFontSizeToFitWidth = true
        
        if recentChat.unreadCounter != 0 {
            self.unreadMessageCountLabel.text = "\(recentChat.unreadCounter)"
            self.unreadMessageCountLabel.isHidden = false
            self.unreadMessageBackgroundView.isHidden = false
        } else {
            self.unreadMessageCountLabel.isHidden = true
            self.unreadMessageBackgroundView.isHidden = true
        }
        setAvatar(avatarLink: recentChat.avatarLink)
        dateLabel.text = timeElapsed(recentChat.date)
        dateLabel.adjustsFontSizeToFitWidth = true
    }
    
    private func setAvatar(avatarLink: String) {
        
        FileStorage.downloadImage(imageUrl: avatarLink) { (avatarImage) in
            if avatarImage != nil {
                DispatchQueue.main.async {
                    self.avatarImageView.image = avatarImage?.circleMasked
                }
            }
        }
    }
    
    func timeElapsed(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        var dateText = ""
        if seconds < 60 {
            dateText = "Just now"
        } else if seconds < 60 * 60 {
            let minutes = Int(seconds / 60)
            let minText = minutes > 1 ? "mins" : "min"
            dateText = "\(minutes) \(minText)"
        } else if seconds < 24 * 60 * 60 {
            let hours = Int(seconds / (60 * 60))
            let hourText = hours > 1 ? "hours" : "hour"
            dateText = "\(hours) \(hourText)"
        } else {
            dateText = date.longDate()
        }
        return dateText
    }
}
