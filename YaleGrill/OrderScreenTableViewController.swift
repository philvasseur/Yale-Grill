//
//  ControlScreenView.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/2/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class OrderScreenTableViewController: UITableViewController, GIDSignInUIDelegate {
    
    var allActiveIDs : [String] = []
    var selectedDiningHall : String!
    var grillIsOn = false
    
    // MARK: - Actions
    
    
    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: FirebaseConstants.ViewControllerID) as? ViewController
        self.present(signInScreen!, animated:true, completion:nil)
    }

    
    
    //Used to transfer data when user unwinds from the foodScreen. Called when user pressed the "placeOrder" button, loops through the orders placed
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? FoodScreen {
            let tempOrderArray = makeOrderController.ordersPlaced //Gets the placed orders when user Unwinds from FoodScreen
            if(grillIsOn){ //Only goes through orders if the grill is on
                var indexPaths : [IndexPath] = []
                for placedOrder in tempOrderArray{
                    allActiveIDs.append(placedOrder.orderID!) //Adds new orders to local orderIDs array
                    placedOrder.insertIntoDatabase(AllActiveIDs: self.allActiveIDs) //Inserts order into Database   
                    FIRDatabase.database().reference().child(FirebaseConstants.grills).child(FirebaseConstants.GrillIDS[self.selectedDiningHall]!).child(FirebaseConstants.orders).child(placedOrder.orderID).setValue(placedOrder.orderID)
                    
                    FIRDatabase.database().reference().child(FirebaseConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(FirebaseConstants.activeOrders).child(placedOrder.orderID).setValue(placedOrder.orderID)
                    indexPaths.append(IndexPath(row: allActiveIDs.count-1, section: 0))
                    
                    //Above: Inserts orderID into grill's active orders
                }
                self.tableView.insertRows(at: indexPaths, with: .fade)
            }
        }
    }

    
    
    // MARK: - Functions
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Overridden Functions
    
    //When you hit the composeOrder button tells the foodScreen class how many orders have already been placed. Used to stop user from accidently placing more than 3 orders.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == FirebaseConstants.ComposeOrderSegueID){
            let destinationVC = (segue.destination as! FoodScreen)
            destinationVC.totalOrdersCount = allActiveIDs.count //sets num of orders variable in FoodScreen
        }
    }
    
    //Stops segue if 3 orders are already placed, if the grill is off, or if the user has been banned. Creates alert for each one.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(!grillIsOn){
            createAlert(title: "Sorry!", message: "The \(selectedDiningHall!) grill is currently off! Please try again later during Dining Hall hours.")
            return false
            
        }else if(allActiveIDs.count>=3){
            createAlert(title: "Order Limit Reached!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
            return false
            
        }else{
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "customerCell",
            for: indexPath) as? OrderScreenTableViewCell else {
                fatalError("BAD ERROR... ORDER CONTROL TABLE CELL")
        }
        let index = indexPath.row
        
        cell.setByOrderID(orderID: allActiveIDs[index])
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allActiveIDs.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = self.tableView.frame.height/3.3
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.backgroundView = UIImageView(image: UIImage(named: "subtleWaves.png"))
        GIDSignIn.sharedInstance().uiDelegate = self
        self.title=selectedDiningHall //Sets title as dining hall, which is set in ViewController screen
        
        let grillStatus = FIRDatabase.database().reference().child(FirebaseConstants.grills).child(FirebaseConstants.GrillIDS[selectedDiningHall]!).child(FirebaseConstants.grillStat)
        grillStatus.observe(FIRDataEventType.value, with: { (snapshot) in //Used to check if grill is on or off.
            let status = snapshot.value as? Bool
            if(status==nil){
                grillStatus.setValue(false)
                self.grillIsOn=false
            }else{
                self.grillIsOn=status!
            }
        })
        
        //Reference to the user's specific account
        let user = FIRDatabase.database().reference().child(FirebaseConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!)
        
        //Observes for any deletions in the user active order array
        user.child(FirebaseConstants.activeOrders).queryOrderedByKey().observe(FIRDataEventType.childRemoved, with: { (snapshot) in
            let orderID = snapshot.value as! String
            let removedIndex = self.allActiveIDs.index(of: orderID)
            let newIndexPath = IndexPath(row: removedIndex!, section: 0)
            self.allActiveIDs.remove(at: removedIndex!)
            self.tableView.deleteRows(at: [newIndexPath], with: .automatic)
        })
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
