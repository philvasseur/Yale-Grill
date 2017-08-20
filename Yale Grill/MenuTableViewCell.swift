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
        background.layer.borderWidth = 1
        background.layer.borderColor = UIColor(hex: "#dbd9d9").cgColor
        super.awakeFromNib()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if(highlighted) {
            background.backgroundColor = UIColor(hex: "#dbd9d9")
        } else {
            background.backgroundColor = UIColor.white
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if(selected) {
            background.backgroundColor = UIColor(hex: "#dbd9d9x")
        } else {
            background.backgroundColor = UIColor.white
        }
    }
}
