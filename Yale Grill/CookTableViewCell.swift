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
    @IBOutlet weak var foodServingLabel: UILabel!
    @IBOutlet weak var OrderNumLabel: UILabel!
    @IBOutlet var attributeLabels: [UILabel]!
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var OrderStatusLabel: UILabel!
    @IBOutlet weak var OrderStatusButton: UIButton!
    
    // MARK: - Global Variables
    var grillName : String!
    var cOrder : Orders!
    var orderStatus : Constants.Status!
    var orderRef : DatabaseReference?
    var delegate: CookTableViewController?
    var task : DispatchWorkItem?
    var playerID : String!
    let status = Constants.Status.self
    
    // MARK: - Actions
    @IBAction func ChangeStatusPressed(_ sender: UIButton) {
        if(orderStatus == status.Placed){
            orderStatus = status.Preparing
            OrderStatusLabel.text = Constants.preparingTexts[3]
            OrderStatusButton.setTitle("Mark Ready", for: .normal)
            OrderStatusButton.backgroundColor = UIColor(hex: "#009900") //dark green
            self.contentView.backgroundColor = UIColor.white
            
        }else if(orderStatus == status.Preparing){
            orderStatus = status.Ready
            OrderStatusLabel.text = "Ready"
            OrderStatusButton.setTitle("Mark Picked Up", for: .normal)
            OrderStatusButton.backgroundColor = UIColor.red
            task = DispatchWorkItem {
                self.delegate?.giveStrike(userID : self.cOrder.userID!,name : self.cOrder.name)
                self.NameLabel.text = "Anyone (was \(self.cOrder.name!))"
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constants.READYTIMER*60, execute: task!)
            
        }else if(orderStatus == status.Ready){
            orderStatus = status.PickedUp
            removeOrder()
        }
        
        if(orderStatus != status.PickedUp) {
            //Updates the order status in the grill's active orders array
            Database.database().reference().child(Constants.grills).child(self.grillName).child(Constants.orders).child(cOrder.orderID).child(Constants.orderStatus).setValue(orderStatus.rawValue)
        }
        
    }
    
    // MARK: - Functions
    func setByOrder(order : Orders, grillName : String){
        for label in attributeLabels { //hides labels until they info is loaded
            label.isHidden = true
        }
        self.OrderNumLabel.isHidden = true //Hides the orderNumber while waiting for it to be set
        self.cOrder = order
        self.grillName = grillName
        
        let orderStatusRef = Database.database().reference().child(Constants.grills).child(grillName).child(Constants.orders).child(self.cOrder.orderID).child(Constants.orderStatus)
        orderStatusRef.observeSingleEvent(of: DataEventType.value, with: {(snapshot) in
            self.orderStatus = Constants.Status(rawValue: snapshot.value as? Int ?? 0)
            
            if(self.orderStatus == self.status.Placed){
                self.OrderStatusLabel.text = "Order Placed"
                self.OrderStatusButton.setTitle("Mark Preparing", for: .normal)
                self.OrderStatusButton.backgroundColor = UIColor(hex: "#4C8BF6") //blue
                self.contentView.backgroundColor = UIColor(hex: "#FFB19C")
            }else if(self.orderStatus == self.status.Preparing){
                self.OrderStatusButton.backgroundColor = UIColor(hex: "#009900") //dark green
                self.OrderStatusLabel.text = Constants.preparingTexts[3]
                self.OrderStatusButton.setTitle("Mark as Ready", for: .normal)
            }else if(self.orderStatus == self.status.Ready){
                self.OrderStatusButton.backgroundColor = UIColor.red
                self.OrderStatusLabel.text = "Ready"
                self.OrderStatusButton.setTitle("Mark Picked Up", for: .normal)
            }
        })
        
        self.foodServingLabel.text = self.cOrder.foodServing
        self.NameLabel.text = self.cOrder.name
        var count = 0
        for option in self.cOrder.options ?? [:] {
            if(option.value) {
                self.attributeLabels[count].text = option.key
            } else {
                self.attributeLabels[count].text = "No \(option.key)"
            }
            self.attributeLabels[count].isHidden = false
            count += 1
        }
        
        if(self.cOrder.orderNum != nil) {
            self.OrderNumLabel.isHidden = false
            if(self.cOrder.orderNum! < 10){
                self.OrderNumLabel.text = "- #0\(self.cOrder.orderNum!)"
            }else {
                self.OrderNumLabel.text = "- #\(self.cOrder.orderNum!)"
            }
        } else {
            let orderNumRef = Database.database().reference().child(Constants.orders).child(order.orderID).child("orderNum")
            orderNumRef.observe(DataEventType.value, with: { (snapshot) in //Observes the order for changes
                if (!snapshot.exists()) {
                    return
                }
                orderNumRef.removeAllObservers()
                let orderNum = snapshot.value  as! Int
                self.OrderNumLabel.isHidden = false
                self.cOrder.orderNum = orderNum
                orderNumRef.removeAllObservers()
                if(orderNum < 10){
                    self.OrderNumLabel.text = " - #0\(orderNum)"
                }else {
                    self.OrderNumLabel.text = " - #\(orderNum)"
                }
            })
        }
    }
    
    private func removeOrder(){
        //Cancels the task which after a set amount of time of being ready gives customer a strike
        task?.cancel()
        let cOrderID = self.cOrder.orderID!
        
        //Removes the order from the users's active orders
        Database.database().reference().child(Constants.users).child(cOrder.userID!).child(Constants.activeOrders).child(cOrderID).removeValue() {(error, reference) in
                //Removes the order from the grill's active orders once it is removed from the user's
                if(error == nil) {
                    Database.database().reference().child(Constants.grills).child(self.grillName).child(Constants.orders).child(cOrderID).removeValue()
                }
            }
        
    }
    
    // MARK: - Overridden Functions
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
