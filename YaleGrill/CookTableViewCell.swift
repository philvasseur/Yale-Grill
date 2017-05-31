//
//  CookTableViewCell.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase



class CookTableViewCell: UITableViewCell{

    // MARK: - Outlets
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
    
    // MARK: - Global Variables
    var grillUserID : String!
    var cOrder : Orders!
    var orderRef : FIRDatabaseReference?
    var delegate: CookTableViewController?
    var task : DispatchWorkItem?
    var playerID : String!
    let status = GlobalConstants.Status.self
    
    // MARK: - Actions
    @IBAction func ChangeStatusPressed(_ sender: UIButton) {
        if(cOrder?.orderStatus == status.Placed.rawValue){
            cOrder?.orderStatus = status.Preparing.rawValue
            OrderStatusLabel.text = GlobalConstants.preparingTexts[3]
            OrderStatusButton.setTitle("Mark Ready", for: .normal)
            OrderStatusButton.backgroundColor = UIColor(hex: "#009900") //dark green
            
        }else if(cOrder?.orderStatus == status.Preparing.rawValue){
            cOrder.orderStatus = status.Ready.rawValue
            OrderStatusLabel.text = "Ready"
            OrderStatusButton.setTitle("Mark Picked Up", for: .normal)
            OrderStatusButton.backgroundColor = UIColor.red
            task = DispatchWorkItem {
                print("Running Task")
                self.delegate?.giveStrike(userID : self.cOrder.userID!,name : self.cOrder.name)
                self.NameLabel.text = "Anyone (was \(self.cOrder.name!))"
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + GlobalConstants.READYTIMER*60, execute: task!)
            
        }else if(cOrder?.orderStatus == status.Ready.rawValue){
            cOrder.orderStatus = status.PickedUp.rawValue
            removeOrder()
        }
        orderRef?.child(GlobalConstants.orderStatus).setValue(cOrder?.orderStatus)
        
        if(cOrder.orderStatus != status.PickedUp.rawValue) {
            //Updates the order status in the grill's active orders array
            FIRDatabase.database().reference().child(GlobalConstants.grills).child(self.grillUserID).child(GlobalConstants.orders).child(cOrder.orderID).child(GlobalConstants.orderStatus).setValue(cOrder.orderStatus)
        }
        
    }
    
    // MARK: - Functions
    func setByOrder(cOrder : Orders, grillUserID : String){
        self.cOrder = cOrder
        orderRef = FIRDatabase.database().reference().child(GlobalConstants.orders).child(cOrder.orderID)
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
        if(cOrder.orderStatus == status.Placed.rawValue){
            OrderStatusLabel.text = "Order Placed"
            OrderStatusButton.setTitle("Mark Preparing", for: .normal)
            OrderStatusButton.backgroundColor = UIColor(hex: "#4C8BF6") //blue
        }else if(cOrder.orderStatus == status.Preparing.rawValue){
            OrderStatusButton.backgroundColor = UIColor(hex: "#009900") //dark green
            OrderStatusLabel.text = GlobalConstants.preparingTexts[3]
            OrderStatusButton.setTitle("Mark as Ready", for: .normal)
        }else if(cOrder.orderStatus == status.Ready.rawValue){
            OrderStatusButton.backgroundColor = UIColor.red
            OrderStatusLabel.text = "Ready"
            OrderStatusButton.setTitle("Mark Picked Up", for: .normal)
        }
        self.grillUserID = grillUserID
        
    }
    
    private func removeOrder(){
        //Cancels the task which after a set amount of time of being ready gives customer a strike
        task?.cancel()
        let cOrderID = self.cOrder.orderID!
        
        //Removes the order from the users's active orders
        FIRDatabase.database().reference().child(GlobalConstants.users).child(cOrder.userID!).child(GlobalConstants.activeOrders).child(cOrderID).setValue(nil)
        //Removes the order from the grill's active orders
        FIRDatabase.database().reference().child(GlobalConstants.grills).child(self.grillUserID).child(GlobalConstants.orders).child(cOrderID).setValue(nil)
        
    }
    
    // MARK: - Overridden Functions
    override func awakeFromNib() {
        super.awakeFromNib()
        OrderStatusButton.layer.cornerRadius = 9
        // Initialization code
    }

}
