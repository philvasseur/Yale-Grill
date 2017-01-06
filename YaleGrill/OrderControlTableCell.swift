//
//  OrderControlTableCell.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase

class OrderControlTableCell: UITableViewCell {

    @IBOutlet weak var OrderName: UILabel!
    @IBOutlet weak var FoodServingLabel: UILabel!
    @IBOutlet weak var BunLabel: UILabel!
    @IBOutlet weak var CheeseLabel: UILabel!
    @IBOutlet weak var SauceLabel: UILabel!
    @IBOutlet weak var TomatoLabel: UILabel!
    @IBOutlet weak var LettuceLabel: UILabel!
    @IBOutlet weak var OrderStatusLabel: UILabel!
    @IBOutlet weak var OrderStatusButton: UIButton!
    private var grillUserID : String!
    private var cOrder : Orders!
    private var orderRef : FIRDatabaseReference?
    
    @IBAction func ChangeStatusPressed(_ sender: UIButton) {
        if(cOrder?.orderStatus==0){
            cOrder?.orderStatus = 1
            orderRef?.child("orderStatus").setValue(cOrder?.orderStatus)
            OrderStatusLabel.text = "Ready"
            OrderStatusButton.setTitle("Delete", for: .normal)
        }else if(cOrder?.orderStatus==1){
            cOrder.orderStatus=2
            removeOrder()
            orderRef?.child("orderStatus").setValue(cOrder?.orderStatus)
        }
    }
    
    private func removeOrder(){
        let cOrderID = self.cOrder.orderID!
        let userRef = FIRDatabase.database().reference().child("Users").child(cOrder.userID!).child("ActiveOrders")
        userRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let allIDsString = snapshot.value as! String
            let tempArray = allIDsString.characters.split { $0 == " " }
            var allIDsArray = tempArray.map(String.init)
            let idIndex = allIDsArray.index(of: cOrderID)
            allIDsArray[idIndex!]=""
            let newIDsString = allIDsArray.joined(separator: " ")
            userRef.setValue(newIDsString)
            
        })
        FIRDatabase.database().reference().child("Grills").child(grillUserID).child("Orders").child(cOrderID).setValue(nil)
    }
    func setByOrder(cOrder : Orders, grillUserID : String){
        self.cOrder = cOrder
        orderRef = FIRDatabase.database().reference().child("Orders").child(cOrder.orderID)
        FoodServingLabel.text = cOrder.foodServing
        BunLabel.text = cOrder.bunSetting
        CheeseLabel.text = cOrder.cheeseSetting
        SauceLabel.text = cOrder.sauceSetting
        TomatoLabel.text = cOrder.tomatoSetting
        LettuceLabel.text = cOrder.lettuceSetting
        OrderName.text = cOrder.name
        if(cOrder.orderStatus==0){
            OrderStatusLabel.text = "Preparing"
            OrderStatusButton.setTitle("Mark as Ready", for: .normal)
        }else if(cOrder.orderStatus==1){
            OrderStatusLabel.text = "Ready"
            OrderStatusButton.setTitle("Delete", for: .normal)
        }
        self.grillUserID = grillUserID
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        OrderStatusButton.layer.cornerRadius = 9
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
