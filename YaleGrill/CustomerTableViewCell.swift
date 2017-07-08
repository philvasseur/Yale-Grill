//
//  CustomerTableViewCell.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 5/25/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase


class CustomerTableViewCell: UITableViewCell{
    
    // MARK: - Outlets
    @IBOutlet weak var preparingGIF: UIImageView!
    
    @IBOutlet weak var orderTitle: UILabel!
    @IBOutlet weak var attributeOneLabel: UILabel!
    @IBOutlet weak var attributeTwoLabel: UILabel!
    @IBOutlet weak var attributeThreeLabel: UILabel!
    @IBOutlet weak var attributeFourLabel: UILabel!
    @IBOutlet weak var attributeFiveLabel: UILabel!
    @IBOutlet weak var orderNumLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var orderNumText: UILabel!
    @IBOutlet weak var readyForPickupText: UILabel!
    
    
    // MARK: - Global Variables
    var cOrder : Orders!
    var delegate: CustomerTableViewController?
    var timer = Timer()
    var orderLabels: [UILabel]!
    let status = Constants.Status.self
    
    
    // MARK: - Actions
    
    // MARK: - Functions
    func setByOrder(order : Orders){
        //Loads a random preparing gif
        preparingGIF.loadGif(name: Constants.gifArray[Int(arc4random_uniform(UInt32(Constants.gifArray.count)))])
        preparingGIF.layer.cornerRadius = 10
        self.cOrder = order
        
        //Sets all the info in the cell
        self.orderTitle.text = self.cOrder.foodServing
        self.attributeOneLabel.text = self.cOrder.cheeseSetting
        self.attributeTwoLabel.text = self.cOrder.lettuceSetting
        self.attributeThreeLabel.text = self.cOrder.bunSetting
        self.attributeFourLabel.text = self.cOrder.sauceSetting
        self.attributeFiveLabel.text = self.cOrder.tomatoSetting
        orderNumLabel.isHidden = true //Hides the orderNumLabel until it gets set as non-zero
        for label in self.orderLabels { //unhides once info shows, makes it look snappier
            label.isHidden = false
        }
        
        let orderNumRef = FIRDatabase.database().reference().child(Constants.orders).child(order.orderID)
        
        orderNumRef.observe(FIRDataEventType.value, with: { (snapshot) in //Observes the order for changes
            let orderNum = (snapshot.value as! [String : AnyObject])["orderNum"] as! Int
            if(orderNum != 0) {
                self.orderNumLabel.isHidden = false
                self.cOrder.orderNum = orderNum
                orderNumRef.removeAllObservers()
                if(orderNum < 10){
                    self.orderNumLabel.text = "0\(orderNum)"
                }else {
                    self.orderNumLabel.text = "\(orderNum)"
                }
            }
        })
        
        let orderStatusRef = FIRDatabase.database().reference().child(Constants.grills).child(order.grill).child(Constants.orders).child(order.orderID).child(Constants.orderStatus)
        orderStatusRef.observe(FIRDataEventType.value, with: {(snapshot) in
            let orderStatus = snapshot.value as? Int ?? 3
            
            //If order is before ready status (placed or preparing)
            if (orderStatus < self.status.Ready.rawValue) {
                let notFinishedTexts = ["Order Placed",Constants.preparingTexts[0]]
                self.statusLabel.text=notFinishedTexts[orderStatus] //Sets to either Preparing or Order Placed
                self.statusLabel.isHidden = false //Unhides the "preparing/order placed" label
                self.readyForPickupText.isHidden = true //Hides the "Ready for Pickup" label
                self.preparingGIF.isHidden = false
            } else { //If order is Ready
                self.statusLabel.isHidden=true //Hides 'Preparing...' Label
                self.readyForPickupText.isHidden=false //Unhides the "Ready" Label
            }
        })
        
        
        
        
        
    }
    
    //Called by the timer every second starting from when view first loaded. Only does anything if it isn't hidden and the text is set as the Preparing loop. Gives "Preparing..." animation.
    @objc private func updatePrep(){
            if(statusLabel.text==Constants.preparingTexts[2]){
                statusLabel.text=Constants.preparingTexts[1]
            }else if(statusLabel.text==Constants.preparingTexts[1]){
                statusLabel.text=Constants.preparingTexts[0]
            }else if(statusLabel.text==Constants.preparingTexts[0]){
                statusLabel.text=Constants.preparingTexts[2]
            } else if(statusLabel.text != "Order Placed"){
                timer.invalidate() //Gets rid of timer after preparing status
        }
    }
    
    // MARK: - Overridden Functions
    override func awakeFromNib() {
        super.awakeFromNib()
        orderLabels = [self.attributeOneLabel,self.attributeTwoLabel,self.attributeThreeLabel,self.attributeFourLabel,self.attributeFiveLabel,self.orderTitle]
        for label in orderLabels { //hides labels until they info is loaded
            label.isHidden = true
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updatePrep), userInfo: nil, repeats: true)
        //Creates the timer for animations
        // Initialization code
    }
    
}
