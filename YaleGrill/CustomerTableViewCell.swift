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
    @IBOutlet weak var readyGIF: UIImageView!
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
    var orderRef : FIRDatabaseReference!
    var delegate: CustomerTableViewController?
    var timer = Timer()
    var orderLabels: [UILabel]!
    
    
    // MARK: - Actions
    
    // MARK: - Functions
    func setByOrderID(orderID : String){
        let notFinishedTexts = ["Order Placed",GlobalConstants.preparingTexts[0]]
        
        //Loads a random preparing gif
        preparingGIF.loadGif(name: GlobalConstants.gifArray[Int(arc4random_uniform(UInt32(GlobalConstants.gifArray.count)))])
        preparingGIF.layer.cornerRadius = 10
        
        orderRef = FIRDatabase.database().reference().child(GlobalConstants.orders).child(orderID)
        
        orderRef.observe(FIRDataEventType.value, with: { (snapshot) in //Observes the order for changes
            let orderDic = snapshot.value as! NSDictionary
            //
            let order = Orders(json: orderDic as! [String : AnyObject]) //Converts from JSON to order object
            self.cOrder = order
            
            //Sets all the info in the cell
            self.orderTitle.text = self.cOrder.foodServing
            self.attributeOneLabel.text = self.cOrder.cheeseSetting
            self.attributeTwoLabel.text = self.cOrder.lettuceSetting
            self.attributeThreeLabel.text = self.cOrder.bunSetting
            self.attributeFourLabel.text = self.cOrder.sauceSetting
            self.attributeFiveLabel.text = self.cOrder.tomatoSetting
            
            for label in self.orderLabels { //unhides once info shows, makes it look snappier
                label.isHidden = false
            }
            
            //Order Status 0 means placed, 1 means preparing, and 2 means Ready
            if(self.cOrder.orderStatus == 0 || self.cOrder.orderStatus == 1){
                self.statusLabel.text=notFinishedTexts[self.cOrder.orderStatus] //Sets to either Preparing or Order Placed
                self.statusLabel.isHidden = false //Unhides the "preparing/order placed" label
                self.readyForPickupText.isHidden = true //Hides the "Ready for Pickup" label
                self.preparingGIF.isHidden = false
                self.readyGIF.isHidden = true
            }else if(self.cOrder.orderStatus == 2 || self.cOrder.orderStatus == 3){
                self.statusLabel.isHidden=true //Hides 'Preparing...' Label
                self.readyGIF.image = UIImage.gif(name: "finished") //Done here to make place order snappier
                self.readyGIF.layer.cornerRadius = 9
                self.readyForPickupText.isHidden=false //Unhides the "Ready For Pickup" Label
                self.preparingGIF.isHidden = true
                self.readyGIF.isHidden = false
            }
            
            if(self.cOrder.orderNum > 0 && self.cOrder.orderNum < 10){
                self.orderNumLabel.text = "0\(self.cOrder.orderNum!)"
                self.orderNumLabel.isHidden = false //The actual order Number label
            }else if(self.cOrder.orderNum != 0) {
                self.orderNumLabel.text = "\(self.cOrder.orderNum!)"
                self.orderNumLabel.isHidden = false //The actual order Number label
            } else {
                self.orderNumLabel.isHidden = true
            }
        })
        
        
    }
    
    //Called by the timer every second starting from when view first loaded. Only does anything if it isn't hidden and the text is set as the Preparing loop. Gives "Preparing..." animation.
    @objc private func updatePrep(){
            if(statusLabel.text==GlobalConstants.preparingTexts[2]){
                statusLabel.text=GlobalConstants.preparingTexts[1]
            }else if(statusLabel.text==GlobalConstants.preparingTexts[1]){
                statusLabel.text=GlobalConstants.preparingTexts[0]
            }else if(statusLabel.text==GlobalConstants.preparingTexts[0]){
                statusLabel.text=GlobalConstants.preparingTexts[2]
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
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        
        // Configure the view for the selected state
    }
    
}
