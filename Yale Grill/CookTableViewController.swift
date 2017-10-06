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
import AVFoundation

class CookTableViewController: UITableViewController, GIDSignInUIDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var GrillToggleButton: UIBarButtonItem!
    @IBOutlet weak var NavBar: UINavigationItem!
    
    // MARK: - Global Variables
    var orderNumCount: Int = -1
    var grillName: String!
    var grillSwitch : DatabaseReference!
    var grillIsOn : Bool = false
    var allActiveOrders : [Orders] = []
    
    
    // MARK: - Actions
    @IBAction func GrillButtonPressed(_ sender: UIBarButtonItem) {
        grillIsOn = !grillIsOn
        if(grillIsOn) {
            grillSwitch.setValue(true)
            GrillToggleButton.title = Constants.turnGrillOffText
        }else if(!grillIsOn) {
            grillSwitch.setValue(false)
            GrillToggleButton.title = Constants.turnGrillOnText
        }
    }
    
    
    @IBAction func signOutPressed2(_ sender: UIBarButtonItem) {
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
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
        Database.database().reference().child(Constants.users).child(userID).child("Strikes").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let strikes = snapshot.value as? Int
            if(strikes == nil) {
                Database.database().reference().child(Constants.users).child(userID).child("Strikes").setValue(1)
            }else{
                Database.database().reference().child(Constants.users).child(userID).child("Strikes").setValue(strikes!+1)
                if(((strikes!+1) % Constants.strikeBanLimit) == 0) {
                    var bannedUntil : String?
                    let banEndsDate = NSCalendar.current.date(byAdding: .day, value: Constants.banLength, to: date)
                    bannedUntil = banEndsDate?.description
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = DateFormatter.Style.full
                    print("\(userID) is banned until \(banEndsDate!)")
                    Database.database().reference().child(Constants.users).child(userID).child("BannedUntil").setValue(bannedUntil)
                }
            }
        })
    }
    
    
    // MARK: - Overridden Functions
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "cookCell",
            for: indexPath) as? CookTableViewCell else {
                fatalError("Cannot create CookTableViewCell...")
        }
        let orderIndex = indexPath.row
        cell.setByOrder(order: allActiveOrders[orderIndex], grillName: self.grillName)
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allActiveOrders.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 90
        tableView.allowsSelection = false
        GIDSignIn.sharedInstance().uiDelegate = self
                
        grillName = Constants.ActiveGrills.filter({ (grill: (grillName: String, grillEmail: String)) -> Bool in
            return grill.grillEmail.lowercased()  == GIDSignIn.sharedInstance().currentUser.profile.email.lowercased()
        }).first?.key ?? "Grill Name"
        
        Database.database().reference().child(Constants.grills).child(grillName).child("PushToken").setValue(Messaging.messaging().fcmToken)
        grillSwitch = Database.database().reference().child(Constants.grills).child(grillName).child(Constants.grillStatus)
        grillSwitch.observe(DataEventType.value, with: { (snapshot) in
            let grillStatus = snapshot.value as? Bool ?? false
            if (grillStatus) {
                self.grillIsOn = true
                self.GrillToggleButton.title = Constants.turnGrillOffText
                self.title = "ON - \(self.grillName!)"
            }else {
                self.grillIsOn = false
                self.GrillToggleButton.title = Constants.turnGrillOnText
                self.title = "\(self.grillName!) - GRILL IS OFF"
            }
        })
        let ordersRef = Database.database().reference().child(Constants.grills).child(grillName).child(Constants.orders)
        ordersRef.queryOrderedByKey().observe(DataEventType.childAdded, with: { (snapshot) in
            Database.database().reference().child(Constants.orders).child(snapshot.key).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                let newJson = snapshot.value as! NSDictionary
                let order = Orders(orderID: snapshot.key, json: newJson as! [String : AnyObject])
                self.allActiveOrders.append(order)
                let newIndexPath = IndexPath(row: self.allActiveOrders.count-1, section: 0)
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
            })
        })
        ordersRef.queryOrderedByKey().observe(DataEventType.childRemoved, with: { (snapshot) in
            let orderID = snapshot.key
            //Finds the index of the orderID to be removed
            let removedIndex = self.allActiveOrders.map{$0.orderID}.index(of: orderID)
            let newIndexPath = IndexPath(row: removedIndex!, section: 0)
            //Removes it from the activeIDs and then removes it from the tableView
            self.allActiveOrders.remove(at: removedIndex!)
            self.tableView.deleteRows(at: [newIndexPath], with: .automatic)
        })
    }
}
