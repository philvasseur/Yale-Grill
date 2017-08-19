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
    var menuItem : MenuItem!
    
    func setItemInfo(item : MenuItem) {
        menuItemImage.image = item.image
        menuItemTitle.text = item.title
        menuItemDescription.text = item.info
    }

    override func awakeFromNib() {
        background.layer.borderWidth = 2
        background.layer.borderColor = UIColor(hex: "#e8e8e8").cgColor
        super.awakeFromNib()
    }
}
