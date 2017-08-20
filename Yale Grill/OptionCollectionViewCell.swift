//
//  OptionCollectionViewCell.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 8/19/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit

class OptionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var checkbox: UIImageView!
    
    var unchecked = UIImage(named: "unchecked")
    var checked = UIImage(named: "checked")
    var isChecked: Bool!
    
    func check() {
        isChecked = !isChecked
        if(isChecked) {
            checkbox.image = checked
        } else {
            checkbox.image = unchecked
        }
    }
    
    func setCellLabel(option: String, isChecked: Bool) {
        optionLabel.text = option
        self.isChecked = isChecked
        if(isChecked) {
            checkbox.image = checked
        } else {
            checkbox.image = unchecked
        }
    }
}
