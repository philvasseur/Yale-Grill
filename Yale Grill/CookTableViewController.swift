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
    var orderNumCount: Int = -1
    var grillName: String!
    var grillSwitch : FIRDatabaseReference!
    var grillIsOn : Bool = false
    var allActiveIDs : [String] = []
    
    
    // MARK: - Actions
    @IBAction func GrillButtonPressed(_ sender: UIBarButtonItem) {
        if(!grillIsOn){
            grillSwitch.setValue(true)
        }else if(grillIsOn){
            grillSwitch.setValue(false)
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
        let signInScreen = sb.instantiateViewController(withIdentifier: Constants.ViewControllerID) as? LoginViewController
        self.present(signInScreen!, animated:true, completion:nil)
    }
    
    
    // MARK: - Functions
    
    func giveStrike(userID : String, name: String){
        let date = Date()
        Constants.createAlert(title: "Strike Given", message: "Due to not picking up their food, \(name) has been given a strike.",style: .notice)
        FIRDatabase.database().reference().child(Constants.users).child(userID).child("Strikes").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let strikes = snapshot.value as? Int
            if(strikes == nil) {
                FIRDatabase.database().reference().child(Constants.users).child(userID).child("Strikes").setValue(1)
            }else{
                FIRDatabase.database().reference().child(Constants.users).child(userID).child("Strikes").setValue(strikes!+1)
                if(((strikes!+1) % Constants.strikeBanLimit) == 0) {
                    var bannedUntil : String?
                    let banEndsDate = NSCalendar.current.date(byAdding: .day, value: Constants.banLength, to: date)
                    bannedUntil = banEndsDate?.description
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = DateFormatter.Style.full
                    print("\(userID) is banned until \(banEndsDate!)")
                    FIRDatabase.database().reference().child(Constants.users).child(userID).child("BannedUntil").setValue(bannedUntil)
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
        cell.setByOrder(orderID: allActiveIDs[orderIndex], grillName: grillName)
        
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
        tableView.rowHeight = 90
        tableView.allowsSelection = false
        GIDSignIn.sharedInstance().uiDelegate = self
        
        for (grill, grillEmail) in Constants.ActiveGrills {
            if(grillEmail.lowercased()  == GIDSignIn.sharedInstance().currentUser.profile.email.lowercased()) {
                grillName = grill
                self.title = "Orders - \(grillName!)"
                break
            }
        }
        
        grillSwitch = FIRDatabase.database().reference().child("Grills").child(grillName).child("GrillIsOn")
        
        grillSwitch.observe(FIRDataEventType.value, with: { (snapshot) in
            let grillStatus = snapshot.value as? Bool
            if(grillStatus==nil){
                self.grillSwitch.setValue(false)
                self.grillIsOn = false
                self.GrillToggleButton.title = Constants.turnGrillOnText
            }else if(grillStatus==true){
                self.grillIsOn = true
                self.GrillToggleButton.title = Constants.turnGrillOffText
            }else if(grillStatus==false){
                self.grillIsOn = false
                self.GrillToggleButton.title = Constants.turnGrillOnText
            }
        })
        
        let ordersRef = FIRDatabase.database().reference().child(Constants.grills).child(grillName).child(Constants.orders)
        
        ordersRef.queryOrderedByKey().observe(FIRDataEventType.childAdded, with: { (snapshot) in
            self.allActiveIDs.append(snapshot.key)
            let newIndexPath = IndexPath(row: self.allActiveIDs.count-1, section: 0)
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)
        })
        
        ordersRef.queryOrderedByKey().observe(FIRDataEventType.childRemoved, with: { (snapshot) in
            let orderID = snapshot.key
            let removedIndex = self.allActiveIDs.index(of: orderID)
            let newIndexPath = IndexPath(row: removedIndex!, section: 0)
            self.allActiveIDs.remove(at: removedIndex!)
            self.tableView.deleteRows(at: [newIndexPath], with: .automatic)
        })
    }
}
