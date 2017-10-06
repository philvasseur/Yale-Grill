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
import FirebaseRemoteConfig
import BTNavigationDropdownMenu

class CustomerTableViewController: UITableViewController, GIDSignInUIDelegate {
    
    var noOrdersLabel = UILabel()
    var grillStatusHandle : UInt!
    var userOrdersRef : DatabaseReference!
    var GID = GIDSignIn.sharedInstance()!
    var grillIsOn : Bool = false
    var menuView: BTNavigationDropdownMenu!
    
    // MARK: - Actions
    
    
    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        print("LOGGING OUT")
        removeActiveObservers()
        GID.signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        Constants.currentOrders = []
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: Constants.ViewControllerID) as? LoginViewController
        self.present(signInScreen!, animated:true, completion:nil)
    }
    
    @IBAction func unwindToOrders(_ sender: UIStoryboardSegue) {
        guard let placedOrderController = sender.source as? MenuItemViewController else { return }
        guard let newOrder = placedOrderController.placedOrder else { return }
        if(!grillIsOn) {
            Constants.createAlert(title: "The Grill Is Off!", message: "Please try again later. If you think this is an error, contact your respective dining hall staff.",
                                  style: .wait)
            return
            
        }
        newOrder.insertIntoDatabase()
        Constants.currentOrders.append(newOrder)
        let indexPath = IndexPath(row: Constants.currentOrders.count - 1, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    
    // MARK: - Functions
    
    //Removes the Firebase observers on each order's status to get rid of errors upon logout when auth is revoked
    func removeActiveObservers(){
        for order in Constants.currentOrders {
            Database.database().reference().child(Constants.grills).child(order.grill).child(Constants.orders).child(order.orderID).child(Constants.orderStatus).removeAllObservers()
        }
    }
    
    func deleteOrder(orderId : String) {
        guard let removedIndex = (Constants.currentOrders.map{$0.orderID}.index(of: orderId)) else { return }
        let newIndexPath = IndexPath(row: removedIndex, section: 0)
        //Removes it from the activeIDs and then removes it from the tableView
        Constants.currentOrders.remove(at: removedIndex)
        self.tableView.deleteRows(at: [newIndexPath], with: .automatic)
    }
    
    
    // MARK: - Overridden Functions
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "customerCell",
            for: indexPath) as? CustomerTableViewCell else {
                fatalError("Cannot create CustomerTableViewCell")
        }
        let index = indexPath.row
        cell.setByOrder(order: Constants.currentOrders[index]) //Sets all the info in the cell
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Constants.currentOrders.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if(Constants.currentOrders.count == 0) { //shows the no active orders label if there are no orders
            menuView.isUserInteractionEnabled = true
            menuView.arrowTintColor = .white
            noOrdersLabel.isHidden = false
        } else {
            menuView.isUserInteractionEnabled = false
            menuView.arrowTintColor = UIColor(hex: "#3C7DEA")
            noOrdersLabel.isHidden = true
        }
        return 1
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(identifier != "menuSegue") {
            return true
        }
        if(Constants.selectedDiningHall == nil ||
            (Constants.PickerData.index(of: Constants.selectedDiningHall) == nil)){
            Constants.createAlert(title: "Select a Dining Hall", message: "Tap the title at the top to select a valid dining hall before placing an order.",
                                  style: .notice)
            return false
        } else  if (!grillIsOn) { //Only goes through orders if the grill is on
            Constants.createAlert(title: "The Grill Is Off!", message: "Please try again later. If you think this is an error, contact your respective dining hall staff.",
                                  style: .wait)
            return false
        } else if(Constants.currentOrders.count >= Constants.orderLimit){
            Constants.createAlert(title: "Order Limit Reached", message: "You can't place more than \(Constants.orderLimit) orders! Please wait for your current orders to be finished!",
                style: .wait)
            return false
        } else {
            return true
        }
    }
    
    private func setDiningHall(dhall : String) {
        UserDefaults.standard.set(dhall, forKey: Constants.prevDining)
        if(Constants.selectedDiningHall != nil) {
            Database.database().reference().child(Constants.grills).child(Constants.selectedDiningHall).child(Constants.grillStatus).removeAllObservers()
        }
        Constants.selectedDiningHall = dhall
        let grillStatusRef = Database.database().reference().child(Constants.grills).child(dhall).child(Constants.grillStatus)
        grillStatusRef.observe(DataEventType.value, with: { (snapshot) in
            self.grillIsOn = snapshot.value as? Bool ?? false
            self.navigationItem.rightBarButtonItem?.tintColor =
                self.grillIsOn == true ? .white : UIColor(hex: "#8DAAEA")
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GID.uiDelegate = self
        
        //Sets up background image and no active orders label for when user has no orders placed
        noOrdersLabel.numberOfLines = 0
        noOrdersLabel.text = "Hi \(GID.currentUser.profile.givenName ?? "Student"),\nYou Have No Active Orders"
        noOrdersLabel.sizeToFit()
        noOrdersLabel.textAlignment = .center
        noOrdersLabel.font = UIFont(name: "Lato-Bold", size: 19)
        self.tableView.backgroundView = UIView()
        self.tableView.backgroundView?.addSubview(noOrdersLabel)
        NSLayoutConstraint.useAndActivate(constraints:
            [noOrdersLabel.centerXAnchor.constraint(equalTo: (tableView.backgroundView?.centerXAnchor)!), noOrdersLabel.centerYAnchor.constraint(equalTo: (tableView.backgroundView?.centerYAnchor)!)])
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
        menuView = BTNavigationDropdownMenu(title: BTTitle.title("Select DHall"), items: Constants.PickerData)
        self.navigationItem.titleView = menuView
        let index = Constants.PickerData.index(of: Constants.selectedDiningHall ?? "Default")
        if(index != nil) {
            menuView.setSelected(index: index!)
            setDiningHall(dhall: Constants.selectedDiningHall)
        }
        menuView.didSelectItemAtIndexHandler = { (indexPath: Int) -> () in
            self.setDiningHall(dhall: Constants.PickerData[indexPath])
        }
        menuView.animationDuration = 0.35
        
        
        tableView.rowHeight = (tableView.frame.height - (self.navigationController?.navigationBar.frame.height)!
            - UIApplication.shared.statusBarFrame.height)/3
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView() //gets rid of dividers below empty cells
    }
}
