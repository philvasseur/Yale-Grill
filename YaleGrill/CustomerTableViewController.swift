//
//  CustomerTableViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 5/25/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class CustomerTableViewController: UITableViewController, GIDSignInUIDelegate {
    
    var allActiveOrders : [Orders] = []
    var selectedDiningHall : String!
    var grillIsOn = false
    var noOrdersLabel = UILabel()
    var grillStatusHandle : UInt!
    var grillStatusRef : FIRDatabaseReference!
    var userOrdersRef : FIRDatabaseReference!
    
    
    // MARK: - Actions
    
    
    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        print("LOGGING OUT")
        removeActiveObservers()
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: GlobalConstants.ViewControllerID) as? LoginViewController
        self.present(signInScreen!, animated:true, completion:nil)
    }

    //Used to transfer data when user unwinds from the foodScreen. Called when user pressed the "placeOrder" button, loops through the orders placed
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? MenuViewController {
            let tempOrderArray = makeOrderController.ordersPlaced //Gets the placed orders when user Unwinds from FoodScreen
            if(grillIsOn){ //Only goes through orders if the grill is on
                var indexPaths : [IndexPath] = []
                
                //Inserts the orders all at onces, makes it so orderNum lines up better to actual order of the orders
                for placedOrder in tempOrderArray{
                    placedOrder.insertIntoDatabase()
                }
                for placedOrder in tempOrderArray{
                    allActiveOrders.append(placedOrder) //Adds new orders to local orderIDs array
                    indexPaths.append(IndexPath(row: allActiveOrders.count-1, section: 0) ) //Adds orders indexPath in table to array
                }
                self.tableView.insertRows(at: indexPaths, with: .none) //Inserts the index paths of the orders into the table
            }
        }
    }
    
    
    // MARK: - Functions
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //Removes the Firebase observers to get rid of errors upon logout when auth is revoked
    func removeActiveObservers(){
        grillStatusRef.removeAllObservers()
        userOrdersRef.removeAllObservers()
        for order in allActiveOrders {
            FIRDatabase.database().reference().child(GlobalConstants.grills).child(order.grill).child(GlobalConstants.orders).child(order.orderID).child(GlobalConstants.orderStatus).removeAllObservers()
        }
    }
    
    
    // MARK: - Overridden Functions
    
    //When you hit the composeOrder button tells the foodScreen class how many orders have already been placed. Used to stop user from accidently placing more than 3 orders.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == GlobalConstants.ComposeOrderSegueID){
            let destinationVC = (segue.destination as! MenuViewController)
            destinationVC.totalOrdersCount = allActiveOrders.count //sets num of orders variable in FoodScreen
            destinationVC.selectedDiningHall = selectedDiningHall
        }
    }
    
    //Stops segue if 3 orders are already placed or if the grill is off. Creates alert for each
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(!grillIsOn){
            createAlert(title: "Sorry!", message: "The \(selectedDiningHall!) grill is currently off! Please try again later during Dining Hall hours.")
            return false
        }else if(allActiveOrders.count>=3){
            createAlert(title: "Order Limit Reached!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
            return false
        }else{
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "customerCell",
            for: indexPath) as? CustomerTableViewCell else {
                fatalError("BAD ERROR... ORDER CONTROL TABLE CELL")
        }
        let index = indexPath.row
        
        cell.setByOrder(order: allActiveOrders[index]) //Sets all the info in the cell
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allActiveOrders.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if(allActiveOrders.count == 0) { //shows the no active orders label if there are no orders
            noOrdersLabel.isHidden = false
        } else {
            noOrdersLabel.isHidden = true
        }
        return 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        self.title=selectedDiningHall //Sets title as dining hall, which is set in ViewController screen
        tableView.rowHeight = (tableView.frame.height - (self.navigationController?.navigationBar.frame.height)!
            - UIApplication.shared.statusBarFrame.height)/3
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView() //gets rid of dividers below empty cells
        
        //Sets up background image and no active orders label for when user has no orders placed
        let firstName = GIDSignIn.sharedInstance().currentUser.profile.givenName
        noOrdersLabel.numberOfLines = 0
        noOrdersLabel.text = "Hi \(firstName ?? "Student"),\nYou Have No Active Orders"
        noOrdersLabel.sizeToFit()
        noOrdersLabel.textAlignment = .center
        noOrdersLabel.font = UIFont(name: "Verdana-Bold", size: 17)
        let newView = UIImageView(image: UIImage(named: "bg2"))
        self.tableView.backgroundView = newView
        self.tableView.backgroundView?.addSubview(noOrdersLabel)
        NSLayoutConstraint.useAndActivate(constraints:
            [noOrdersLabel.centerXAnchor.constraint(equalTo: (tableView.backgroundView?.centerXAnchor)!), noOrdersLabel.centerYAnchor.constraint(equalTo: (tableView.backgroundView?.centerYAnchor)!)])
        
        //Checks and continues to observe if grill is on or off
        grillStatusRef = FIRDatabase.database().reference().child(GlobalConstants.grills).child(selectedDiningHall!).child(GlobalConstants.grillStat)
        grillStatusRef.observe(FIRDataEventType.value, with: { (snapshot) in
            let status = snapshot.value as? Bool
            if(status==nil){ //No status has been set yet, defaults to off.
                self.grillStatusRef.setValue(false)
                self.grillIsOn=false
            }else{
                self.grillIsOn=status!
            }
        })
        
        //Reference to the user's specific account
        userOrdersRef = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(GlobalConstants.activeOrders)
        
        //Observes for any deletions in the user active order array in order to remove the order in realtime
        userOrdersRef.queryOrderedByKey().observe(FIRDataEventType.childRemoved, with: { (snapshot) in
            let orderID = snapshot.key
            //Finds the index of the orderID to be removed
            let removedIndex = self.allActiveOrders.map{$0.orderID}.index(of: orderID)
            let newIndexPath = IndexPath(row: removedIndex!, section: 0)
            //Removes it from the activeIDs and then removes it from the tableView
            self.allActiveOrders.remove(at: removedIndex!)
            self.tableView.deleteRows(at: [newIndexPath], with: .automatic)
            FIRDatabase.database().reference().child(GlobalConstants.grills).child(self.selectedDiningHall).child(GlobalConstants.orders).child(orderID).child(GlobalConstants.orderStatus).removeAllObservers()
        })
    }
}
