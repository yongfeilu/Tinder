//
//  MatchViewController.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/1/21.
//

import UIKit

protocol MatchViewControllerDelegate {
    func didClickSendMessage(to user: FUser)
    func didClickKeepSwiping()
}

class MatchViewController: UIViewController {

    //MARK:  - IBOutlets
    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var heartView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameAgeLabel: UILabel!
    @IBOutlet weak var cityCountryLabel: UILabel!
    
    //MARK:  - Vars
    var user: FUser?
    var delegate: MatchViewControllerDelegate?
    
    //MARK:  - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        if user != nil {
            presentUserData()
        }
    }
    
    //MARK:  - IBActions
    @IBAction func sendMessageButtonPressed(_ sender: Any) {
        delegate?.didClickSendMessage(to: user!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func keepSwipingButtonPressed(_ sender: Any) {
        delegate?.didClickKeepSwiping()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:  - Setup
    
    
    private func setupUI() {
        
        cardBackgroundView.layer.cornerRadius = 10
        heartView.layer.cornerRadius = 10
        heartView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        cardBackgroundView.applyShadow(radius: 8, opacity: 0.2, offset: CGSize(width: 0, height: 2))
    }
    
    private func presentUserData() {
        
        avatarImageView.image = user!.avatar?.circleMasked
        let cityCountry = user!.city + ", " + user!.country
        let nameAge = user!.username + ", \(user!.dateOfBirth.interval(ofComponent: .year, fromDate: Date()))"
        
        nameAgeLabel.text = nameAge
        cityCountryLabel.text = cityCountry
    }
    
}
