//
//  LikeTableViewCell.swift
//  DatingApp
//
//  Created by 卢勇霏 on 5/31/21.
//

import UIKit

class LikeTableViewCell: UITableViewCell {

    //MARK:  - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    func setupCell(user: FUser) {
        nameLabel.text = user.username
        setAvatar(avatarLink: user.avatarLink)
    }
    
    private func setAvatar(avatarLink: String) {
        FileStorage.downloadImage(imageUrl: avatarLink) { (avatarImage) in
            DispatchQueue.main.async {
                self.avatarImageView.image = avatarImage?.circleMasked
            }
            
        }
    }
    
    
}
