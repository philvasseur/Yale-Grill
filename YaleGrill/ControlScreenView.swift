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

class ControlScreenView: UITableViewController, GIDSignInUIDelegate, UITextViewDelegate {
   
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FirebaseConstants.cellIdentifier,
            for: indexPath) as? OrderControlTableCell else {
                fatalError("BAD ERROR... ORDER CONTROL TABLE CELL")
        }
        let orderIndex = indexPath.row
        let newCell = setOrderInfo(cell: cell, index: orderIndex)
        newCell.delegate = self
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
    
    
    func showAlert(title:String, message:String, userID :String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: { (action) in self.saveBan(userID: userID, alert: alert)}))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.font = UIFont(name: "System", size: 18)
            textField.placeholder = "Number of Days"
            textField.textAlignment = .center
            textField.keyboardType = .numberPad
        }
        let attributedString = NSAttributedString(string: title, attributes: [
            NSFontAttributeName : UIFont.systemFont(ofSize: 20), //your font here
            NSForegroundColorAttributeName : UIColor.black
            ])
        alert.setValue(attributedString, forKey: "attributedTitle")
        self.present(alert, animated: true, completion: nil)
        
    }
    
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
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveBan(userID : String, alert: UIAlertController){
        var bannedUntil : String?
        let banText = alert.textFields![0].text!
        let invalidCharacters = CharacterSet(charactersIn: "0123456789").inverted
        if((banText.rangeOfCharacter(from: invalidCharacters, options: [], range: banText.startIndex ..< banText.endIndex) == nil) || (banText.isEmpty)){
            print("Does not have bad chars")
            alert.dismiss(animated: true, completion: nil)
            if(!(banText.isEmpty) && alert.textFields![0].text! != "0"){
                let banLength = Int(alert.textFields![0].text!)
                let date = Date()
                let banEndsDate = NSCalendar.current.date(byAdding: .day, value: banLength!, to: date)
                bannedUntil = banEndsDate?.description
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = DateFormatter.Style.full
                print("\(userID) is banned until \(banEndsDate!)")
                createAlert(title: "User Banned", message: "The ban will expire on \(dateFormatter.string(from: banEndsDate!)).")
            }else{
                createAlert(title: "Ban Cleared", message: "Any existing ban on the user has been removed.")
            }
            FIRDatabase.database().reference().child(FirebaseConstants.users).child(userID).child("BannedUntil").setValue(bannedUntil)
        }else{
            self.present(alert, animated: true, completion: nil)
        }
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
