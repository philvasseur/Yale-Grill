//
//  MenuTableViewController.swift
//
//
//  Created by Phil Vasseur on 8/17/17.
//
//

import UIKit
import Firebase

class MenuTableViewController: UITableViewController {
    
    
    // MARK: - Global Variables
    var totalOrdersCount: Int = 0 //Used to keep track of how many orders already exist, so user can't accidently order more than 3.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor(hex: "#fafafa")
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "cellSelection", sender: indexPath)
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "menuItemCell",
            for: indexPath) as? MenuTableViewCell else {
                fatalError("Cannot create MenuTableViewCell")
        }
        cell.setItemInfo(item: Constants.menuItems[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cellSelection" {
            let destination = (segue.destination as! UINavigationController).topViewController as! MenuItemViewController
            let row = (sender as! IndexPath).row
            destination.menuItem = Constants.menuItems[row]
        }
    }
    
    @IBAction func unwindToMenu(_ sender: UIStoryboardSegue) {
    }
}

