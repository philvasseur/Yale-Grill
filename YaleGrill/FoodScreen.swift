//
//  FoodScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class FoodScreen: UIViewController, GIDSignInUIDelegate{
    
    var orderInfo: [String] = []
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        orderInfo = getOrderInfo()
    }
    
    func getOrderInfo() -> [String]{
        orderInfo = ["","","","","","","","","","","","",""]
        var toppings = ["Bun","Cheese","Sauce","Lettuce","Tomatoes"]
        if(BurgerStepCount.value != 0){
            if(BurgerStepCount.value==1){
                orderInfo[0]="Single Burger"
            }else{
                orderInfo[0]="Double Burger"
            }
            var count = 1
            for hamSwitch in HamburgerSwitches{
                if(hamSwitch.isOn){
                    orderInfo[count]="\(toppings[count-1])"
                }else{
                    orderInfo[count]="No \(toppings[count-1])"
                }
                count += 1
            }
            
        }
        if(VeggieStepCount.value != 0){
            if(VeggieStepCount.value==1){
                orderInfo[6]="Single Veggie Burger"
            }else{
                orderInfo[6]="Double Veggie Burger"
            }
            var count = 7
            for vegSwitch in VeggieSwitches{
                if(vegSwitch.isOn){
                    orderInfo[count]="\(toppings[count-7])"
                }else{
                    orderInfo[count]="No \(toppings[count-7])"
                }
                count += 1
            }
        }
        switch (ChickenStepCount.value){
        case 1: orderInfo[12]="One Piece of Chicken"
        case 2: orderInfo[12]="Two Pieces of Chicken"
        case 3: orderInfo[12]="Three Pieces of Chicken"
        case 4: orderInfo[12]="Four Pieces of Chicken"
        default: orderInfo[12]=""
        }
        
        return orderInfo
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
