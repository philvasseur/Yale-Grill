//
//  MenuItemViewController.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 8/18/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit

class MenuItemViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var menuItemImage: UIImageView!
    @IBOutlet weak var menuItemInfo: UILabel!
    @IBOutlet weak var textBackground: UIView!
    @IBOutlet weak var quantityBackground: UIView!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var optionsCollectionView: UICollectionView!
    
    var menuItem : MenuItem!
    var placedOrder : Orders?
    var options : [String : Bool]? = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuItemImage.image = menuItem.image
        menuItemInfo.text = menuItem.info
        quantityLabel.text = menuItem.quantities[0]
        for option in menuItem.options {
            options?[option] = true
        }
        self.title = menuItem.title
        
        textBackground.layer.borderWidth = 1
        textBackground.layer.borderColor = UIColor(hex: "#e8e8e8").cgColor
        quantityBackground.layer.borderWidth = 1
        quantityBackground.layer.borderColor = UIColor(hex: "#e8e8e8").cgColor
        
        stepper.maximumValue = Double(menuItem.quantities.count - 1)
        
        optionsCollectionView.delegate = self
        optionsCollectionView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard (sender as? UIButton) != nil else { return }
        options = options?.count == 0 ? nil : options
        placedOrder = Orders(_userID: GIDSignIn.sharedInstance().currentUser.userID!, _name: GIDSignIn.sharedInstance().currentUser.profile.name!, _foodServing: quantityLabel.text!, _options: options, _grill: Constants.selectedDiningHall)
    }

    @IBAction func quantityChanged(_ sender: UIStepper) {
        quantityLabel.text = menuItem.quantities[Int(sender.value)]
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath as IndexPath) as! OptionCollectionViewCell
        let option = menuItem.options[indexPath.row]
        cell.setCellLabel(option: option, isChecked: options?[option] ?? true)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuItem.options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! OptionCollectionViewCell
        cell.check()
        options?[cell.optionLabel.text ?? ""] = !(options?[cell.optionLabel.text ?? ""] ?? false)
    }
    
    
}
