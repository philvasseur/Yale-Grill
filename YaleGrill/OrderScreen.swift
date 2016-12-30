//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    
    private var gifArray = [UIImage.gif(name: "preparing"), UIImage.gif(name: "preparing2"), UIImage.gif(name:"preparing3")]
    
    @IBOutlet var LinesArray: [UIImageView]!
    var totalOrderArray: [SingleOrder] = []
    var OrderLabelsArray: [[UILabel]]!
    var timer = Timer()
    @IBOutlet var GifViews: [UIImageView]!
    @IBOutlet var OrderItemLabels: [UILabel]!
    @IBOutlet var OrderItemLabels2: [UILabel]!
    @IBOutlet var OrderItemLabels3: [UILabel]!
    @IBOutlet weak var noActiveOrdersLabel: UILabel!
    @IBOutlet var FinishedGifArray: [UIImageView]!
    @IBOutlet var FoodIsReadyLabelArray: [UILabel]!
    private var finishedGif = UIImage.gif(name: "finished")
    
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
    private func updateOrderDisplay(cOrder: SingleOrder){
        let cOrderNum = cOrder.orderNum
        var cOrderLabels = OrderLabelsArray[cOrderNum]
        totalOrderArray[cOrderNum] = cOrder
        if(cOrder.status=="Preparing..."){
            cOrderLabels[6].isHidden=true
            cOrderLabels[7].isHidden=true
            FoodIsReadyLabelArray[cOrderNum].isHidden=false
            FinishedGifArray[cOrderNum].image = finishedGif
            FinishedGifArray[cOrderNum].isHidden=false
            FinishedGifArray[cOrderNum].layer.borderWidth = 3.5
            FinishedGifArray[cOrderNum].layer.borderColor = UIColor.black.cgColor
            GifViews[cOrderNum].isHidden=true
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
            updateOrderDisplay(cOrder: totalOrderArray[0]) //TEMPORARY JUST TO TEST
            //ABILITY TO MAKE ORDERS "FINISHED"
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
        for index in 0...2{
            if(OrderLabelsArray[index][0].isHidden){
                LinesArray[index].isHidden=false
                GifViews[index].isHidden=false
                GifViews[index].image=gifArray[index]
                GifViews[index].layer.borderWidth = 3.5
                GifViews[index].layer.borderColor = UIColor.black.cgColor
                GifViews[index].layer.masksToBounds = true
                for itemLabel in OrderLabelsArray[index]{
                    itemLabel.isHidden=false
                }
                OrderLabelsArray[index][0].text=cOrder.foodServing
                OrderLabelsArray[index][1].text=cOrder.bunSetting
                OrderLabelsArray[index][2].text=cOrder.cheeseSetting
                OrderLabelsArray[index][3].text=cOrder.sauceSetting
                OrderLabelsArray[index][4].text=cOrder.lettuceSetting
                OrderLabelsArray[index][5].text=cOrder.tomatoSetting
                OrderLabelsArray[index][7].text=cOrder.status
                break
            }
        }
    }
    @objc private func updatePrep(){
        for orderLabels in OrderLabelsArray{
            if(orderLabels[7].text=="Preparing."){
                orderLabels[7].text="Preparing.."
            }else if(orderLabels[7].text=="Preparing.."){
                orderLabels[7].text="Preparing..."
            }else if(orderLabels[7].text=="Preparing..."){
                orderLabels[7].text="Preparing."
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        OrderLabelsArray=[OrderItemLabels,OrderItemLabels2,OrderItemLabels3]
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(OrderScreen.updatePrep), userInfo: nil, repeats: true)
       
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

