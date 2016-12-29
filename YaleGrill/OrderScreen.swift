//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    var totalOrderArray: [SingleOrder] = []

    @IBOutlet var OrderItemLabels: [UILabel]!
    @IBOutlet var OrderItemLabels2: [UILabel]!
    @IBOutlet var OrderItemLabels3: [UILabel]!
    @IBOutlet weak var noActiveOrdersLabel: UILabel!
    @IBAction func SignOutPressed(_ sender: UIBarButtonItem) {
        signOutAndChange(shouldAnimate: true)
    }
    
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? FoodScreen {
            let tempOrderArray = makeOrderController.ordersPlaced
            for order in tempOrderArray{
                noActiveOrdersLabel.isHidden=true
                setSingleOrder(cOrder: order)
                totalOrderArray.append(order)
            }
            
        }
    }
    
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "ComposeOrder"){
            let destinationVC = (segue.destination as! FoodScreen)
            destinationVC.totalOrdersCount = totalOrderArray.count
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(totalOrderArray.count>=3){
            createAlert(title: "Sorry!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
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
    
    private func setSingleOrder(cOrder: SingleOrder){
        let ItemLabelsArray : [[UILabel]] = [OrderItemLabels,OrderItemLabels2,OrderItemLabels3]
        for orderSpot in ItemLabelsArray{
            if(orderSpot[0].isHidden){
                for itemLabel in orderSpot{
                    itemLabel.isHidden=false
                }
                orderSpot[0].text=cOrder.foodServing
                orderSpot[1].text=cOrder.bunSetting
                orderSpot[2].text=cOrder.cheeseSetting
                orderSpot[3].text=cOrder.sauceSetting
                orderSpot[4].text=cOrder.lettuceSetting
                orderSpot[5].text=cOrder.tomatoSetting
                break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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

