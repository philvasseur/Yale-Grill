//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    var overAllOrderInfo: [String] = []
    var orderInfo : [String]?
    var ordersFull = false

    @IBOutlet var OrderItemLabels: [UILabel]!
    @IBOutlet var OrderItemLabels2: [UILabel]!
    @IBOutlet var OrderItemLabels3: [UILabel]!
    @IBOutlet weak var noActiveOrdersLabel: UILabel!
    @IBAction func SignOutPressed(_ sender: UIBarButtonItem) {
        signOutAndChange(shouldAnimate: true)
    }
    
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? FoodScreen {
            orderInfo = makeOrderController.orderInfo
        }
    }
    
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(ordersFull){
            createAlert(title: "Sorry!", message: "You can't place more than three orders! Please wait for your current orders to be finished!")
            return false
        }else{
            return true
        }
    }
    private func signOutAndChange(shouldAnimate: Bool){ //Separate method since called from two different places
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(signInScreen!, animated:shouldAnimate, completion:nil)
    }
    private func setSingleOrder(aCount : Int) -> Int{
        var tempCount = aCount
        if(OrderItemLabels[0].isHidden){
            for item in OrderItemLabels{
                item.isHidden=false
                overAllOrderInfo.append(orderInfo![tempCount])
                if(tempCount==12){
                    item.text=orderInfo![tempCount]
                    tempCount+=1
                    return tempCount
                }else{
                    item.text = orderInfo![tempCount]
                }
                tempCount+=1
            }
            
        }else if(OrderItemLabels2[0].isHidden){
            for item in OrderItemLabels2{
                item.isHidden=false
                overAllOrderInfo.append(orderInfo![tempCount])
                if(tempCount==12){
                    item.text=orderInfo![tempCount]
                    tempCount+=1
                    return tempCount
                }else{
                    item.text = orderInfo![tempCount]
                }
                tempCount+=1
            }
        }else if(OrderItemLabels3[0].isHidden){
            ordersFull=true
            for item in OrderItemLabels3{
                item.isHidden=false
                overAllOrderInfo.append(orderInfo![tempCount])
                if(tempCount==12){
                    item.text=orderInfo![tempCount]
                    tempCount+=1
                    return tempCount
                }else{
                    item.text = orderInfo![tempCount]
                }
                tempCount+=1
            }
        }else{
            return 13
        }
        return tempCount
    }
    
    private func setOrderLabels(){
        var count = 0
        while(count<13){
            if(orderInfo?[count] == ""){
                count+=6
            }else{
                count = setSingleOrder(aCount: count)
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        if(orderInfo != nil){
            noActiveOrdersLabel.isHidden=true
            setOrderLabels()
            orderInfo = nil
            for item in overAllOrderInfo{
                print(item)
            }
        }
        
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

