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

class ControlScreenView: UITableViewController, GIDSignInUIDelegate {
   
    var grillRef = FIRDatabase.database().reference().child("Grills").child(GIDSignIn.sharedInstance().currentUser.userID).child("GrillIsOn")
    private var grillIsOn : Bool = false
    private var allActiveOrders : [Orders] = []
    private var allActiveIDs : [String] = []
    @IBOutlet weak var GrillToggleButton: UIBarButtonItem!
    @IBOutlet weak var NavBar: UINavigationItem!
    
    @IBAction func GrillButtonPressed(_ sender: UIBarButtonItem) {
        if(!grillIsOn){
            grillRef.setValue(true)            
        }else if(grillIsOn){
            grillRef.setValue(false)
        }
    }
    
    @IBAction func signOutPressed2(_ sender: UIBarButtonItem) {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: FirebaseConstants.cellIdentifier,
            for: indexPath) as! OrderControlTableCell
        let orderIndex = indexPath.row
        let newCell = setOrderInfo(cell: cell, index: orderIndex)
        return newCell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allActiveOrders.count
    }
    
    private func setOrderInfo(cell : OrderControlTableCell, index : Int) -> OrderControlTableCell{
        cell.setByOrder(cOrder: allActiveOrders[index], grillUserID : GIDSignIn.sharedInstance().currentUser.userID!)
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 90
        tableView.allowsSelection = false
        GIDSignIn.sharedInstance().uiDelegate = self
        grillRef.observe(FIRDataEventType.value, with: { (snapshot) in
            let grillStatus = snapshot.value as? Bool
            if(grillStatus==nil){
                self.grillRef.setValue(false)
                self.grillIsOn = false
                self.GrillToggleButton.title = FirebaseConstants.turnGrillOnText
            }else if(grillStatus==true){
                self.grillIsOn = true
                self.GrillToggleButton.title = FirebaseConstants.turnGrillOffText
            }else if(grillStatus==false){
                self.grillIsOn = false
                self.GrillToggleButton.title = FirebaseConstants.turnGrillOnText
            }
        })
        let ordersRef = FIRDatabase.database().reference().child(FirebaseConstants.grills).child(GIDSignIn.sharedInstance().currentUser.userID).child(FirebaseConstants.orders)
        ordersRef.queryOrderedByKey().observe(FIRDataEventType.childAdded, with: { (snapshot) in
            let newOrderID = snapshot.value as! String
            self.allActiveIDs.append(newOrderID)
            let singleOrderRef = FIRDatabase.database().reference().child(FirebaseConstants.orders).child(newOrderID as String)
            singleOrderRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                let newJson = snapshot.value as! NSDictionary
                let newOrder = Orders.convFromJSON(json: newJson as! [String : AnyObject])
                let newIndexPath = IndexPath(row: self.allActiveOrders.count, section: 0)
                self.allActiveOrders.append(newOrder)
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
            })
        })
        ordersRef.queryOrderedByKey().observe(FIRDataEventType.childRemoved, with: { (snapshot) in
            let orderID = snapshot.value as! String
            let removedIndex = self.allActiveIDs.index(of: orderID)
            let newIndexPath = IndexPath(row: removedIndex!, section: 0)
            self.allActiveIDs.remove(at: removedIndex!)
            self.allActiveOrders.remove(at: removedIndex!)
            self.tableView.deleteRows(at: [newIndexPath], with: .automatic)
        })

        //Grills > JE(or other grills) > array of all the IDs
        //Call Observe for childAdded on activeOrders if it exists, if not create it then call it
        //when a child is added, use the ID to add it to allActiveOrders array using singleEventObserve
        //This should create a new tableviewcell which should then get set to allactiveorders.
        //Use indexPath to get what order it is in allActiveOrders

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
