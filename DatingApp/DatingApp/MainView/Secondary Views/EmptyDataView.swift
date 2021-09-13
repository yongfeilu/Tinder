//
//  EmptyDataView.swift
//  DatingApp
//
//  Created by 卢勇霏 on 6/3/21.
//

import UIKit

protocol EmptyDataViewDelegate {
    func didClickReloadButton()
}

class EmptyDataView: UIView {

    //MARK:  - IBOutlets
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    
    //MARK:  - Vars
    var delegate: EmptyDataViewDelegate?
    
    //MARK:  - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("EmptyDataView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    
    @IBAction func reloadButtonPressed(_ sender: Any) {
        delegate?.didClickReloadButton()
    }
}
