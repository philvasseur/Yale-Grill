//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

/*
 OrderScreen page. This class is for the page which contains all active orders, sign out button, and compose button. Has all the order information and keeps track of the all of the current orders. GIfs and such on this page as well.
*/

import UIKit

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    
    private var needsToUpdateOrders = true
    private var gifArray = [UIImage.gif(name: "preparing"), UIImage.gif(name: "preparing2"), UIImage.gif(name:"preparing3")] //Image Array of the three preparing gifs
    @IBOutlet var LinesArray: [UIImageView]! //Array of the two white lines which separate the orders
    var totalOrderArray: [Orders] = [] //Where all the current orders are appended to and kept track of
    var OrderLabelsArray: [[UILabel]]! //Holds the three OrderItemLabels outlet collections which are defined below. Allows for easy looping through the three sections and their labels
    var timer = Timer() //Used to update the "Preparing..." text to make it animate
    @IBOutlet var GifViews: [UIImageView]! //Array of the UIImageView which hold the preparing gifs.
    @IBOutlet var OrderItemLabels: [UILabel]! //This and the next two lines are outlet collections of labels for the three order sections.
    @IBOutlet var OrderItemLabels2: [UILabel]!
    @IBOutlet var OrderItemLabels3: [UILabel]!
    @IBOutlet weak var noActiveOrdersLabel: UILabel! //Hidden when an order is created.
    @IBOutlet var FinishedGifArray: [UIImageView]! //Array of UIImageViews which are unhidden when an order is marked finished. Contains the finishedGif
    @IBOutlet var FoodIsReadyLabelArray: [UILabel]! //Array of "FOOD IS READY" text Overlayed over the FinishedGifArrays. Unhidden when order is marked finished.
    private var finishedGif = UIImage.gif(name: "finished")
    
    //When the signout button is pressed, calls the signOut method and changes back to login viewController screen.
    @IBAction func SignOutPressed(_ sender: UIBarButtonItem) {
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(signInScreen!, animated:true, completion:nil)

    }
    
   
    
    //Used to transfer data when user unwinds from the foodScreen. Called when user pressed the "placeOrder" button, loops through the orders that were just placed and sets each one. 
    //Also sets the noActiveOrdersLabel as hidden. Adds the ordersPlaced to the totalOrderArray.
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? FoodScreen {
            let tempOrderArray = makeOrderController.ordersPlaced
            for oldOrder in tempOrderArray{
                DynamoCommands.dynamoInsertRow(oldOrder)
            }
            setOrders(ordersArray: tempOrderArray)
        
            
        }
    }
    private func setOrders(ordersArray: [Orders]){
        for newOrder in ordersArray{
            noActiveOrdersLabel.isHidden=true
            setSingleOrder(cOrder: newOrder)
            totalOrderArray.append(newOrder)
        }
    }
    
    //Sets an order to finished. Called when cook sets the order to complete and then will have to somehow pull that it's now set as finished in the database.
    //Changes the order to the new one (should just have status updated), but also hides the "Status" and "Preparing..." labels, and the PreparingGif. 
    //Unhides the foodIsReady label and the FinishedGif.
    private func updateOrderAsFinished(cOrder: Orders){
        let cOrderNum = cOrder.orderNumber! as Int
        var cOrderLabels = OrderLabelsArray[cOrderNum]
        totalOrderArray[cOrderNum] = cOrder
        if(cOrder.isFinished==1){
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
    
    //Simple created alert method, just used for warning when user trys to place another order after already having three.
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //When you hit the composeOrder button tells the foodScreen class how many orders have already been placed. Used to stop user from accidently placing more than 3 orders. 
    //For example, stopping user who already has two orders to place another two, as that would be > 3.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "ComposeOrder"){
            let destinationVC = (segue.destination as! FoodScreen)
            destinationVC.totalOrdersCount = totalOrderArray.count
        }
    }
    
    //Used to stop user from placing more than three orders. Only performs segue when the composeOrder button is pressed if there are less than three orders. If >=3, creates an alert.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(totalOrderArray.count>=3){
            createAlert(title: "Sorry!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
            //ABILITY TO MAKE ORDERS "FINISHED"
            return false
        }else{
            return true
        }
    }
    
    //This is the method which sets the labels to the order. Called with a singleOrder object and loops through the three orderItemLabels groups checking if any are still hidden.
    //If they're hidden it means they haven't been used yet. When it finds unused orderItemLabels, sets all the corresponding labels to the correct info, unhides the seperating line,
    //unhides the preparing gif, and the status/preparing labels.
    public func setSingleOrder(cOrder: Orders){
        for index in 0...2{
            if(OrderLabelsArray[index][0].isHidden){
                LinesArray[index].isHidden=false
                GifViews[index].isHidden=false
                GifViews[index].image=gifArray[index]
                GifViews[index].layer.borderWidth = 3.5
                GifViews[index].layer.borderColor = UIColor.black.cgColor
                GifViews[index].layer.masksToBounds = true
                
                OrderLabelsArray[index][0].text=cOrder.foodServing
                OrderLabelsArray[index][0].isHidden = false
                OrderLabelsArray[index][6].isHidden=false
                if(cOrder.isFinished==0){
                    OrderLabelsArray[index][7].text="Preparing..."
                }
                OrderLabelsArray[index][7].isHidden = false
                if(cOrder.bunSetting != "EMPTY_STRING"){
                    for itemLabel in OrderLabelsArray[index]{
                        itemLabel.isHidden=false
                    }
                    OrderLabelsArray[index][1].text=cOrder.bunSetting
                    OrderLabelsArray[index][2].text=cOrder.cheeseSetting
                    OrderLabelsArray[index][3].text=cOrder.sauceSetting
                    OrderLabelsArray[index][4].text=cOrder.lettuceSetting
                    OrderLabelsArray[index][5].text=cOrder.tomatoSetting
                }
                break
            }
        }
    }
    
    //Called by the timer every second starting from when view first loaded. Only does anything if it isn't hidden and the text is set as the Preparing loop. Gives "Preparing..." animatino.
    @objc private func updatePrep(){
        if(needsToUpdateOrders && DynamoCommands.prevOrders.count>0){
            setOrders(ordersArray: DynamoCommands.prevOrders)
            needsToUpdateOrders=false
        }
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
   
    //Sets the values of the OrderLabelsArray and creates/calls timer.
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        OrderLabelsArray=[OrderItemLabels,OrderItemLabels2,OrderItemLabels3]
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(OrderScreen.updatePrep), userInfo: nil, repeats: true)
        if(needsToUpdateOrders && DynamoCommands.prevOrders.count>0){
            setOrders(ordersArray: DynamoCommands.prevOrders)
            needsToUpdateOrders=false
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

