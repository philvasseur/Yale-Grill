//
//  CookTableViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/2/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class CookTableViewController: UITableViewController, GIDSignInUIDelegate {
   
    // MARK: - Outlets
    @IBOutlet weak var GrillToggleButton: UIBarButtonItem!
    @IBOutlet weak var NavBar: UINavigationItem!
    
    // MARK: - Global Variables
    final var strikeBanLimit = 5
    final var banLength = 10
    var orderNumCount: Int = -1
    var grillRef = FIRDatabase.database().reference().child("Grills").child(GIDSignIn.sharedInstance().currentUser.userID).child("GrillIsOn")
    var grillIsOn : Bool = false
    var allActiveOrders : [Orders] = []
    var allActiveIDs : [String] = []
    
    
    // MARK: - Actions
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
        let signInScreen = sb.instantiateViewController(withIdentifier: GlobalConstants.ViewControllerID) as? LoginViewController
        self.present(signInScreen!, animated:true, completion:nil)
    }
    
    
    // MARK: - Functions
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        let attributedString = NSAttributedString(string: title, attributes: [
            NSFontAttributeName : UIFont.systemFont(ofSize: 19), //your font here
            NSForegroundColorAttributeName : UIColor.black
            ])
        let attributedString2 = NSAttributedString(string: message, attributes: [
            NSFontAttributeName : UIFont.systemFont(ofSize: 16), //your font here
            NSForegroundColorAttributeName : UIColor.black
            ])
        alert.setValue(attributedString, forKey: "attributedTitle")
        alert.setValue(attributedString2, forKey: "attributedMessage")
        if(self.presentedViewController == nil) {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func giveStrike(userID : String, name: String){
        let date = Date()
        self.createAlert(title: "Strike Given", message: "Due to not picking up their food, \(name) has been given a strike.")
        FIRDatabase.database().reference().child(GlobalConstants.users).child(userID).child("Strikes").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let strikes = snapshot.value as? Int
            if(strikes == nil) {
                FIRDatabase.database().reference().child(GlobalConstants.users).child(userID).child("Strikes").setValue(1)
            }else{
                FIRDatabase.database().reference().child(GlobalConstants.users).child(userID).child("Strikes").setValue(strikes!+1)
                if(((strikes!+1) % self.strikeBanLimit) == 0) {
                    var bannedUntil : String?
                    let banEndsDate = NSCalendar.current.date(byAdding: .day, value: self.banLength, to: date)
                    bannedUntil = banEndsDate?.description
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = DateFormatter.Style.full
                    print("\(userID) is banned until \(banEndsDate!)")
                    FIRDatabase.database().reference().child(GlobalConstants.users).child(userID).child("BannedUntil").setValue(bannedUntil)
                }
            }
        })
    }
    
    
    // MARK: - Overridden Functions
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "cookCell",
            for: indexPath) as? CookTableViewCell else {
                fatalError("BAD ERROR... ORDER CONTROL TABLE CELL")
        }
        let orderIndex = indexPath.row
        cell.setByOrder(cOrder: allActiveOrders[orderIndex], grillUserID : GIDSignIn.sharedInstance().currentUser.userID!)

        //let newCell = setOrderInfo(cell: cell, index: orderIndex)
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allActiveOrders.count
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
                self.GrillToggleButton.title = GlobalConstants.turnGrillOnText
            }else if(grillStatus==true){
                self.grillIsOn = true
                self.GrillToggleButton.title = GlobalConstants.turnGrillOffText
            }else if(grillStatus==false){
                self.grillIsOn = false
                self.GrillToggleButton.title = GlobalConstants.turnGrillOnText
            }
        })
        
        let ordersRef = FIRDatabase.database().reference().child(GlobalConstants.grills).child(GIDSignIn.sharedInstance().currentUser.userID).child(GlobalConstants.orders)
        let orderNumRef = FIRDatabase.database().reference().child(GlobalConstants.grills).child(GIDSignIn.sharedInstance().currentUser.userID).child("OrderNumCount")
        orderNumRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let orderNum = snapshot.value as? Int
            if(orderNum == nil) {
                orderNumRef.setValue(1);
                self.orderNumCount = 1
            }else{
                self.orderNumCount = orderNum!
            }
        
            ordersRef.queryOrderedByKey().observe(FIRDataEventType.childAdded, with: { (snapshot) in
                let newOrderID = snapshot.value as! String
                self.allActiveIDs.append(newOrderID)
                let singleOrderRef = FIRDatabase.database().reference().child(GlobalConstants.orders).child(newOrderID as String)
                singleOrderRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                    let newJson = snapshot.value as! NSDictionary
                    let newOrder = Orders.convFromJSON(json: newJson as! [String : AnyObject])
                    if(newOrder.orderNum == 0){
                        newOrder.orderNum = self.orderNumCount
                        self.orderNumCount += 1
                        orderNumRef.setValue(self.orderNumCount)
                        singleOrderRef.child("orderNum").setValue(newOrder.orderNum)
                    }
                    if(self.orderNumCount >= 100){
                        orderNumRef.setValue(1);
                        self.orderNumCount = 1
                    }
                    let newIndexPath = IndexPath(row: self.allActiveOrders.count, section: 0)
                    self.allActiveOrders.append(newOrder)
                    self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                })
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
