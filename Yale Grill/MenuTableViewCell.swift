//
//  MenuTableViewCell.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 8/17/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var menuItemDescription: UILabel!
    @IBOutlet weak var menuItemTitle: UILabel!
    @IBOutlet weak var menuItemImage: UIImageView!
    @IBOutlet weak var background: UIView!
    
    var delegate: MenuTableViewController?
    
    func setItemInfo(itemDetails : [String : Any]) {
        menuItemImage.image = itemDetails["image"] as? UIImage
        menuItemTitle.text = itemDetails["title"] as? String
        menuItemDescription.text = itemDetails["description"] as? String
    }

    override func awakeFromNib() {
        background.layer.borderWidth = 2
        background.layer.borderColor = UIColor(hex: "#e8e8e8").cgColor
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
