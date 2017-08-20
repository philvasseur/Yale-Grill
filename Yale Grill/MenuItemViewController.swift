//
//  MenuItemViewController.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 8/18/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit

class MenuItemViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var menuItemImage: UIImageView!
    @IBOutlet weak var menuItemInfo: UILabel!
    @IBOutlet weak var textBackground: UIView!
    @IBOutlet weak var quantityBackground: UIView!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var optionsTableView: UITableView!
    
    var menuItem : MenuItem!
    var placedOrder : Orders?
    var options : [String : Bool]? = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuItemImage.image = menuItem.image
        menuItemInfo.text = menuItem.info
        quantityLabel.text = menuItem.quantities[0]
        for option in menuItem.options! {
            options?[option] = true
        }
        self.title = menuItem.title
        
        textBackground.layer.borderWidth = 1
        textBackground.layer.borderColor = UIColor(hex: "#e8e8e8").cgColor
        quantityBackground.layer.borderWidth = 1
        quantityBackground.layer.borderColor = UIColor(hex: "#e8e8e8").cgColor
        
        stepper.maximumValue = Double(menuItem.quantities.count - 1)
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        optionsTableView.tableFooterView = UIView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard (sender as? UIButton) != nil else { return }
        options = options?.count == 0 ? nil : options
        placedOrder = Orders(_userID: GIDSignIn.sharedInstance().currentUser.userID!, _name: GIDSignIn.sharedInstance().currentUser.profile.name!, _foodServing: quantityLabel.text!, _options: options, _grill: Constants.selectedDiningHall)
    }

    @IBAction func quantityChanged(_ sender: UIStepper) {
        quantityLabel.text = menuItem.quantities[Int(sender.value)]
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItem.options?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "optionCell",
            for: indexPath) as? FoodOptionTableViewCell else {
                fatalError("Cannot create FoodOptionTableViewCell")
        }
        let optionName = menuItem.options?[indexPath.row]
        cell.setCellLabel(option: optionName!, isChecked: (options?[optionName!])!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cell = (tableView.cellForRow(at: indexPath) as! FoodOptionTableViewCell)
        cell.check()
        let optionName = cell.optionLabel.text!
        options?[optionName] = !(options?[optionName] ?? false)
    }
}
