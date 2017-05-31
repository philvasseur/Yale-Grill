//
//  MenuViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, GIDSignInUIDelegate{
    
    
    // MARK: - Outlets
    @IBOutlet weak var BurgerStepCount: UIStepper! //StepCount which keeps track of how many burger patties are wanted
    @IBOutlet weak var VeggieStepCount: UIStepper! //StepCount which keeps track of how many veggie patties are wanted
    @IBOutlet weak var ChickenStepCount: UIStepper! //StepCount which keeps track of how many pieces of chicken are wanted
    @IBOutlet weak var ChickenCount: UILabel! //Label which is set to the number of chicken pieces that are currently set by stepCount
    @IBOutlet weak var PlaceButton: UIButton! //PlaceOrder button, just used to make it rounded
    @IBOutlet weak var VeggieCount1: UILabel! //Label for showing how many veggie patties
    @IBOutlet weak var HamburgerCount1: UILabel! //Label for showing how many burger patties
    @IBOutlet var HamburgerSwitches: [UISwitch]! //Switch array which is used to check what burger toppings are wanted when order is placed
    @IBOutlet var VeggieSwitches: [UISwitch]! //Switch array which is used to check what veggie toppings are wanted when order is placed
    
    // MARK: - Global Variables
    var totalOrdersCount: Int = 0 //Used to keep track of how many orders already exist, so user can't accidently order more than 3.
    var ordersPlaced: [Orders] = [] //Returned to OrderScreen class when placeOrder button is pressed.
    
    
    
    // MARK: = Actions
    //Changes the veggieBurger text whenever the VeggieStepCount is changed.
    @IBAction func VeggieStepper(_ sender: UIStepper) {
        if((sender.value)==0){
            for item in VeggieSwitches {
                item.isEnabled=false
            }
            VeggieCount1.text="----"
        }else if((sender.value)==1){
            for item in VeggieSwitches {
                item.isEnabled=true
            }
            VeggieCount1.text="Single"
        }else if((sender.value)==2){
            VeggieCount1.text="Double"
        }
    }
    
    //Updates the ChickenCount label whenever the ChickenStepCount is changed
    @IBAction func StepperCount(_ sender: UIStepper) {
        if((sender.value)==0){
            ChickenCount.text="----"
        }else if((sender.value)==1){
            ChickenCount.text="One Piece"
        }else if((sender.value)==2){
            ChickenCount.text="Two Pieces"
        }else if((sender.value)==3){
            ChickenCount.text="Three Pieces"
        }else if((sender.value)==4){
            ChickenCount.text="Four Pieces"
        }
    }
   
    //Changes the hamburger text whenever the BurgerStepCount is changed.
    @IBAction func HamburgerStepper(_ sender: UIStepper) {
        if((sender.value)==0){
            for item in HamburgerSwitches {
                item.isEnabled=false
            }
            HamburgerCount1.text="----"
        }else if((sender.value)==1){
            for item in HamburgerSwitches {
                item.isEnabled=true
            }
            HamburgerCount1.text="Single"
        }else if((sender.value)==2){
            HamburgerCount1.text="Double"
        }
    }
    
    // MARK: - Functions
    
    //Looping function which goes through all the stepCounts and switches and creates SingleOrder objects. Appends them to the ordersPlaced array
    //This is called indirectly by placeOrder button. PlaceorderButton is set to unwindSegue, but before it segues it checks shouldPerformSegue.
    //If conditions are met, then sets the ordersPlaced array to the array returned here. The unwindSegue method in OrderScreen can then access ordersPlaced
    //to get the orders which were just placed and set the corresponding labels in the active orders screen (OrderScreen.swift)
    func getOrderInfo() -> [Orders]{
        let cName = GIDSignIn.sharedInstance().currentUser.profile.name!
        let cUser = GIDSignIn.sharedInstance().currentUser.userID!
        var orderArray = [Orders]()
        let StepCountArray : [UIStepper] = [BurgerStepCount,VeggieStepCount,ChickenStepCount]
        var toppings = GlobalConstants.toppingsArray
        let switchesArray : [[UISwitch]] = [HamburgerSwitches,VeggieSwitches]
        let foodServingArray : [[String]] = GlobalConstants.foodServingArray
        for index in 0...2{
            var orderInfo : [String] = []
            if(StepCountArray[index].value != 0){
                orderInfo.append(foodServingArray[index][lround(StepCountArray[index].value)-1])
                for cSwitch in 0...4{
                    if(index==2){
                        orderInfo.append("")
                    }else{
                        if(switchesArray[index][cSwitch].isOn){
                            orderInfo.append("\(toppings[cSwitch])")
                        }else{
                            orderInfo.append("No \(toppings[cSwitch])")
                        }
                    }
                }
                let tempOrder = Orders(_userID: cUser, _name: cName, _foodServing: orderInfo[0], _bunSetting: orderInfo[1], _cheeseSetting: orderInfo[2], _sauceSetting: orderInfo[3], _lettuceSetting: orderInfo[4], _tomatoSetting: orderInfo[5], _orderStatus: 0, _orderID : nil, _orderNum: nil)
                orderArray.append(tempOrder)
            }
        }
        
        return orderArray
    }
    
    //CreateAlert method just like in orderScreen class. Used here to stop user from having more than 3 total orders.
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Overridden Functions
    
    //Changes the placeButton corner rounding.
    override func viewDidLoad() {
        super.viewDidLoad()
        PlaceButton.layer.cornerRadius = 12
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    //Calls the alert method above. Stops placeOrder button from seguing if no orders have been placed or if the total would be more than 3.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        ordersPlaced = getOrderInfo()
        if(ordersPlaced.count+totalOrdersCount > 3){
            var plural = ""
            if(totalOrdersCount != 1){
                plural = "s"
            }
            createAlert(title: "Wow, you're hungry!", message: "Sorry, \(ordersPlaced.count) more orders sets you over the limit! You have already placed \(totalOrdersCount) order\(plural) and the limit is 3!")
            return false
        }else if(ordersPlaced.count==0){
            return false
        }else{
            return true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
                // Dispose of any resources that can be recreated.
    }
}
