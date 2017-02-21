//
//  OrderControlTableCell.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase



class OrderControlTableCell: UITableViewCell{

    @IBOutlet weak var OrderNumLabel: UILabel!
    @IBOutlet weak var FoodServingLabel: UILabel!
    @IBOutlet weak var BunLabel: UILabel!
    @IBOutlet weak var CheeseLabel: UILabel!
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var SauceLabel: UILabel!
    @IBOutlet weak var TomatoLabel: UILabel!
    @IBOutlet weak var LettuceLabel: UILabel!
    @IBOutlet weak var OrderStatusLabel: UILabel!
    @IBOutlet weak var OrderStatusButton: UIButton!
    final var READYTIMER : Double = 8
    private var grillUserID : String!
    private var cOrder : Orders!
    private var orderRef : FIRDatabaseReference?
    var delegate:ControlScreenView?
    var task : DispatchWorkItem?
    
    
    @IBAction func ChangeStatusPressed(_ sender: UIButton) {
        if(cOrder?.orderStatus==0){
            cOrder?.orderStatus = 1
            OrderStatusLabel.text = FirebaseConstants.preparingTexts[3]
            OrderStatusButton.setTitle("Mark Ready", for: .normal)
        }else if(cOrder?.orderStatus==1){
            cOrder.orderStatus=2
            OrderStatusLabel.text = FirebaseConstants.ready
            OrderStatusButton.setTitle(FirebaseConstants.delete, for: .normal)
            task = DispatchWorkItem {
                print("Running Task")
                self.delegate?.giveStrike(userID : self.cOrder.userID!,name : self.cOrder.name)
                self.NameLabel.text = "Anyone (was \(self.cOrder.name!))"
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + READYTIMER*60, execute: task!)
        }else if(cOrder?.orderStatus==2){
            cOrder.orderStatus=3
            removeOrder()
        }
        orderRef?.child(FirebaseConstants.orderStatus).setValue(cOrder?.orderStatus)
    }
    
    private func removeOrder(){
        task?.cancel()
        let cOrderID = self.cOrder.orderID!
        let userRef = FIRDatabase.database().reference().child(FirebaseConstants.users).child(cOrder.userID!).child(FirebaseConstants.activeOrders)
        userRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let allIDsString = snapshot.value as! String
            let tempArray = allIDsString.characters.split { $0 == " " }
            var allIDsArray = tempArray.map(String.init)
            let idIndex = allIDsArray.index(of: cOrderID)
            allIDsArray[idIndex!]=""
            let newIDsString = allIDsArray.joined(separator: " ")
            userRef.setValue(newIDsString)
            FIRDatabase.database().reference().child(FirebaseConstants.grills).child(self.grillUserID).child(FirebaseConstants.orders).child(cOrderID).setValue(nil)
            
        })
        
    }
    
    func setByOrder(cOrder : Orders, grillUserID : String){
        self.cOrder = cOrder
        orderRef = FIRDatabase.database().reference().child(FirebaseConstants.orders).child(cOrder.orderID)
        FoodServingLabel.text = cOrder.foodServing
        BunLabel.text = cOrder.bunSetting
        CheeseLabel.text = cOrder.cheeseSetting
        SauceLabel.text = cOrder.sauceSetting
        TomatoLabel.text = cOrder.tomatoSetting
        LettuceLabel.text = cOrder.lettuceSetting
        NameLabel.text = cOrder.name
        if(cOrder.orderNum > 9) {
            OrderNumLabel.text = "- #\(cOrder.orderNum!)"
        }else{
             OrderNumLabel.text = "- #0\(cOrder.orderNum!)"
        }
        if(cOrder.orderStatus==0){
            OrderStatusLabel.text = "Order Placed"
            OrderStatusButton.setTitle("Mark Preparing", for: .normal)
        }else if(cOrder.orderStatus==1){
            OrderStatusLabel.text = FirebaseConstants.preparingTexts[3]
            OrderStatusButton.setTitle(FirebaseConstants.markAsReady, for: .normal)
        }else if(cOrder.orderStatus==2){
            OrderStatusLabel.text = FirebaseConstants.ready
            OrderStatusButton.setTitle(FirebaseConstants.delete, for: .normal)
        }
        self.grillUserID = grillUserID
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        OrderStatusButton.layer.cornerRadius = 9
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)

        // Configure the view for the selected state
    }

}
