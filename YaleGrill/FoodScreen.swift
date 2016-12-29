//
//  FoodScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class FoodScreen: UIViewController, GIDSignInUIDelegate{
    var totalOrdersCount: Int = 0
    var ordersPlaced: [SingleOrder] = []
    @IBOutlet weak var BurgerStepCount: UIStepper!
    @IBOutlet weak var VeggieStepCount: UIStepper!
    @IBOutlet weak var ChickenStepCount: UIStepper!
    @IBOutlet weak var ChickenCount: UILabel!
    @IBOutlet weak var PlaceButton: UIButton!
    @IBOutlet weak var VeggieCount1: UILabel!
    @IBOutlet weak var VeggieCount2: UILabel!
    @IBOutlet weak var HamburgerCount1: UILabel!
    @IBOutlet weak var HamburgerCount2: UILabel!
    @IBOutlet var HamburgerSwitches: [UISwitch]!
    @IBOutlet var VeggieSwitches: [UISwitch]!
    
    @IBAction func StepperCount(_ sender: UIStepper) {
        if((sender.value)==0){
            ChickenCount.text="Zero Pieces"
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
    
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        ordersPlaced = getOrderInfo()
        if(ordersPlaced.count+totalOrdersCount > 3){
            var plural = ""
            if(totalOrdersCount != 1){
                plural = "s"
            }
            let ordersLeft = 3-totalOrdersCount
            createAlert(title: "Wow, you're hungry!", message: "You already have \(totalOrdersCount) order\(plural) and just tried to add \(ordersPlaced.count) more, but the max number of orders is 3! Please order only \(ordersLeft) more!")
            return false
        }else{
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    }
    
    func getOrderInfo() -> [SingleOrder]{
        let cName = GIDSignIn.sharedInstance().currentUser.profile.name!
        let orderNum = 111
        var orderArray = [SingleOrder]()
        let StepCountArray : [UIStepper] = [BurgerStepCount,VeggieStepCount,ChickenStepCount]
        var toppings = ["Bun","Cheese","Sauce","Lettuce","Tomatoes"]
        let switchesArray : [[UISwitch]] = [HamburgerSwitches,VeggieSwitches]
        let foodServingArray : [[String]] = [["Single Burger","Double Burger"],["Single Veggie Burger","Double Veggie Burger"],["One Piece of Chicken","Two Pieces of Chicken","Three Pieces of Chicken","Four Pieces of Chicken"]]
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
                let tempOrder = SingleOrder(orderNum: orderNum, name: cName, foodServing: orderInfo[0], bunSetting: orderInfo[1], cheeseSetting: orderInfo[2], sauceSetting: orderInfo[3], lettuceSetting: orderInfo[4], tomatoSetting: orderInfo[5])
                orderArray.append(tempOrder)
            }
        }
        
        return orderArray
    }
    
    @IBAction func VeggieStepper(_ sender: UIStepper) {
        if((sender.value)==0){
            for item in VeggieSwitches{
                item.isEnabled=false
            }
            VeggieCount1.text="Zero"
            VeggieCount2.text="Patties"
        }else if((sender.value)==1){
            for item in VeggieSwitches{
                item.isEnabled=true
            }
            VeggieCount1.text="One"
            VeggieCount2.text="Patty"
        }else if((sender.value)==2){
            VeggieCount1.text="Two"
            VeggieCount2.text="Patties"
        }
    }
   
    @IBAction func HamburgerStepper(_ sender: UIStepper) {
        if((sender.value)==0){
            for item in HamburgerSwitches {
                item.isEnabled=false
            }
            HamburgerCount1.text="Zero"
            HamburgerCount2.text="Patties"
        }else if((sender.value)==1){
            for item in HamburgerSwitches {
                item.isEnabled=true
            }
            HamburgerCount1.text="One"
            HamburgerCount2.text="Patty"
        }else if((sender.value)==2){
            HamburgerCount1.text="Two"
            HamburgerCount2.text="Patties"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PlaceButton.layer.cornerRadius = 12
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
                // Dispose of any resources that can be recreated.
    }
}
