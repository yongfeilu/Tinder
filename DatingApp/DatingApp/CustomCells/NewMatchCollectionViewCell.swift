//
//  NewMatchCollectionViewCell.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/1/21.
//

import UIKit

class NewMatchCollectionViewCell: UICollectionViewCell {
    
    //MARK:  - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        
        hideActivityIndicator()
    }
    
    func setupCell(avatarLink: String) {
        showActivityIndicator()
        self.avatarImageView.image = UIImage(named: "avatar")
        FileStorage.downloadImage(imageUrl: avatarLink) { (avatarImage) in
            self.hideActivityIndicator()
            DispatchQueue.main.async {
                self.avatarImageView.image = avatarImage?.circleMasked
            }
        }
    }
    
    private func showActivityIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        }
        
    }
    
}
