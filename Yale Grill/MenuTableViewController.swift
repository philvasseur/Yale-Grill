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
    var grillIsOn: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor(hex: "#fafafa")
        
        //Checks and continues to observe if grill is on or off
        let grillStatusRef = FIRDatabase.database().reference().child(Constants.grills).child(Constants.selectedDiningHall).child(Constants.grillStat)
        grillStatusRef.observe(FIRDataEventType.value, with: { (snapshot) in
            let status = snapshot.value as? Bool
            if(status==nil){ //No status has been set yet, defaults to off.
                self.grillIsOn=false
            }else{
                self.grillIsOn=status!
            }
        })

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
                fatalError("BAD ERROR... ORDER CONTROL TABLE CELL")
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
        if let placedOrderController = sender.source as? MenuItemViewController {
            guard let newOrder = placedOrderController.placedOrder else {return} //Gets the placed orders when user Unwinds from FoodScreen
            if (!grillIsOn) { //Only goes through orders if the grill is on
                Constants.createAlert(title: "The Grill Is Off!", message: "Please try again later during Dining Hall hours. If you think this is an error, contact your respective dining hall staff.",
                                      style: .wait)
            } else if(Constants.currentOrders.count > 2){
                Constants.createAlert(title: "Order Limit Reached", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!",
                                      style: .wait)
            } else {
                newOrder.insertIntoDatabase()
                Constants.currentOrders.append(newOrder)
            }
        }
    }
}

