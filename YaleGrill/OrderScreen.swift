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
import Firebase

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var LoadingText: UILabel! //LoadingText which shows when first signing in, allows orders queried before user can see active orders screen
    var dBaseRef = FIRDatabase.database().reference().child(GIDSignIn.sharedInstance().currentUser.userID!) //the FIRDatabase Ref for the current user
    private var gifArray = [UIImage.gif(name: "preparing"), UIImage.gif(name: "preparing2"), UIImage.gif(name:"preparing3")] //Image Array of the three preparing gifs
    @IBOutlet var LinesArray: [UIImageView]! //Array of the two white lines which separate the orders
    var allActiveOrders: [String] = [] //Array of the activeOrderIds
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
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(signInScreen!, animated:true, completion:nil)

    }
    
    //Used to transfer data when user unwinds from the foodScreen. Called when user pressed the "placeOrder" button, loops through the orders placed, adds their orderID to the array and inserts them into the fireBase database
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? FoodScreen {
            let tempOrderArray = makeOrderController.ordersPlaced
            for oldOrder in tempOrderArray{
                allActiveOrders.append(oldOrder.orderID!)
                oldOrder.insertIntoDatabase(AllActiveIDs: allActiveOrders)
            }
        }
    }
    
    //Method to update the orderLocation of orders. If a lower index order is removed it makes it so any remaining orders stay at the lowest possible index, keeps relative order of any orders in mind as to not switch them around
    private func updateLocations(totalOrderArray : [Orders]) -> [Orders]{
        if(totalOrderArray.count == 1){
            if(totalOrderArray[0].orderLocation != 0){
                wipeLabels(index: totalOrderArray[0].orderLocation)
                totalOrderArray[0].orderLocation = 0
                let Order = totalOrderArray[0]
                dBaseRef.child(Order.orderID).child("orderLocation").setValue(Order.orderLocation)
            }
        }else if(totalOrderArray.count == 2){
            if(totalOrderArray[0].orderLocation! > totalOrderArray[1].orderLocation!){
                if(totalOrderArray[0].orderLocation != 1){
                    wipeLabels(index: totalOrderArray[0].orderLocation)
                    totalOrderArray[0].orderLocation = 1
                    let Order = totalOrderArray[0]
                    dBaseRef.child(Order.orderID).child("orderLocation").setValue(Order.orderLocation)
                }
                if(totalOrderArray[1].orderLocation != 0){
                    wipeLabels(index: totalOrderArray[0].orderLocation)
                    totalOrderArray[1].orderLocation = 0
                    let Order = totalOrderArray[1]
                    dBaseRef.child(Order.orderID).child("orderLocation").setValue(Order.orderLocation)
                }
            }else{
                if(totalOrderArray[0].orderLocation != 0){
                    wipeLabels(index: totalOrderArray[0].orderLocation)
                    totalOrderArray[0].orderLocation = 0
                    let Order = totalOrderArray[0]
                    dBaseRef.child(Order.orderID).child("orderLocation").setValue(Order.orderLocation)
                }
                if(totalOrderArray[1].orderLocation != 1){
                    wipeLabels(index: totalOrderArray[0].orderLocation)
                    totalOrderArray[1].orderLocation = 1
                    let Order = totalOrderArray[1]
                    dBaseRef.child(Order.orderID).child("orderLocation").setValue(Order.orderLocation)
                }
            }
            
        }
        return totalOrderArray
    }
    
    //Function called whenever values are updated in the Firebase database. Only called by that async method. Makes it so no active orders is hidden, updates the locations of the orders.
    //Incase an order has been deleted. What is passed into setOrders are all the currently active orders in the database for the user. Sets each one and then will wipe any unused labels to make sure
    //that there isn't any leftover text from deleted/moved orders. If no orders, wipes all labels and unhides noActiveOrders label
    private func setOrders(ordersArray: [Orders]){
        noActiveOrdersLabel.isHidden=true
        let newPosOrders = updateLocations(totalOrderArray: ordersArray)
        for cOrder in newPosOrders{
            setSingleOrder(cOrder: cOrder)
        }
        if(newPosOrders.count==2){
            wipeLabels(index: 2)
        }else if(newPosOrders.count==1){
            wipeLabels(index: 2)
            wipeLabels(index: 1)
        }else if(newPosOrders.count==0){
            wipeLabels(index: 2)
            wipeLabels(index: 1)
            wipeLabels(index: 0)
            noActiveOrdersLabel.isHidden=false
        }
    }
    
    //Hides all labels, meant to get rid of the remains of any deleted/moved order
    private func wipeLabels(index: Int){
        for eachLabel in OrderLabelsArray[index]{
            eachLabel.isHidden=true
        }
        GifViews[index].isHidden=true
        FinishedGifArray[index].isHidden=true
        FoodIsReadyLabelArray[index].isHidden=true
        LinesArray[index].isHidden=true
        
    }
    
    //Sets an order to finished. Called when cook sets the order to complete.
    //Changes the order to the new one (should just have status updated), but also hides the "Status" and "Preparing..." labels, and the PreparingGif. 
    //Unhides the foodIsReady label and the FinishedGif.
    private func updateOrderAsFinished(cOrder: Orders){
        let orderLoc = cOrder.orderLocation!
        var cOrderLabels = OrderLabelsArray[orderLoc]
        cOrderLabels[6].isHidden=true
        cOrderLabels[7].isHidden=true
        FoodIsReadyLabelArray[orderLoc].isHidden=false
        FinishedGifArray[orderLoc].image = finishedGif
        FinishedGifArray[orderLoc].isHidden=false
        FinishedGifArray[orderLoc].layer.borderWidth = 3.5
        FinishedGifArray[orderLoc].layer.borderColor = UIColor.black.cgColor
        GifViews[orderLoc].isHidden=true
        
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
            destinationVC.totalOrdersCount = allActiveOrders.count
        }
    }
    
    //Used to stop user from placing more than three orders. Only performs segue when the composeOrder button is pressed if there are less than three orders. If >=3, creates an alert.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(allActiveOrders.count>=3){
            createAlert(title: "Sorry!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
            //ABILITY TO MAKE ORDERS "FINISHED"
            return false
        }else{
            return true
        }
    }
    
    //Sets the information for an order. Unhides the labels depending on what type of food, and also either sets as preparing or finished depending on orderStatus
    private func setSingleOrder(cOrder: Orders){
        let index : Int = cOrder.orderLocation!
        LinesArray[index].isHidden=false
        OrderLabelsArray[index][0].text=cOrder.foodServing
        OrderLabelsArray[index][0].isHidden = false
        if(cOrder.bunSetting != "EMPTY_STRING"){
            for itemLabel in OrderLabelsArray[index]{
                itemLabel.isHidden=false
            }
            OrderLabelsArray[index][1].text=cOrder.bunSetting
            OrderLabelsArray[index][2].text=cOrder.cheeseSetting
            OrderLabelsArray[index][3].text=cOrder.sauceSetting
            OrderLabelsArray[index][4].text=cOrder.lettuceSetting
            OrderLabelsArray[index][5].text=cOrder.tomatoSetting
        }else{
            OrderLabelsArray[index][1].isHidden=true
            OrderLabelsArray[index][2].isHidden=true
            OrderLabelsArray[index][3].isHidden=true
            OrderLabelsArray[index][4].isHidden=true
            OrderLabelsArray[index][5].isHidden=true
        }
        
        if(cOrder.orderStatus == 0){
            GifViews[index].isHidden=false
            GifViews[index].image=gifArray[index]
            GifViews[index].layer.borderWidth = 3.5
            GifViews[index].layer.borderColor = UIColor.black.cgColor
            GifViews[index].layer.masksToBounds = true
            OrderLabelsArray[index][6].isHidden=false
            OrderLabelsArray[index][7].text="Preparing..."
            OrderLabelsArray[index][7].isHidden = false
            FoodIsReadyLabelArray[index].isHidden=true
            FinishedGifArray[index].isHidden=true
        }else if(cOrder.orderStatus == 1){
            updateOrderAsFinished(cOrder: cOrder)
        }
    }
    
    //Called by the timer every second starting from when view first loaded. Only does anything if it isn't hidden and the text is set as the Preparing loop. Gives "Preparing..." animatino.
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
   
    //Sets the values of the OrderLabelsArray and creates/calls timer.
    //More important calls the async Observe function, this keeps realTime data for the updating of orders.
    //Checks for any value changes in the user's database, if it has activeOrders child that means user is not new. If new then it waits for it to be created from first order creation.
    override func viewDidLoad() {
        super.viewDidLoad()
        var firstTime = true
        GIDSignIn.sharedInstance().uiDelegate = self
        OrderLabelsArray=[OrderItemLabels,OrderItemLabels2,OrderItemLabels3]
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(OrderScreen.updatePrep), userInfo: nil, repeats: true)
        navigationController?.navigationBar.isHidden=true
        noActiveOrdersLabel.isHidden=true
        
        let user = self.dBaseRef
        user.observe(FIRDataEventType.value, with: { (snapshot) in
            // Get user value
            if(snapshot.hasChild("ActiveOrders")){
                let value = snapshot.value as! NSDictionary
                let orderIDs = value["ActiveOrders"] as! String
                let spaceArray = orderIDs.characters.split { $0 == " " }
                self.allActiveOrders = spaceArray.map(String.init) //sets allActiveOrders from activeOrders value of database, changing it from a string to an array
                var loadedOrders : [Orders] = []
                for id in self.allActiveOrders{ //Loops through the ids in active orders and adds the converted json objects to an array of current order objects
                    let jsonOrder = value[id]
                    let foundOrder = Orders.convFromJSON(json: jsonOrder as! [String : AnyObject])
                    loadedOrders.append(foundOrder)
                }
                var sec: Int
                if(firstTime){
                    sec=1
                    firstTime=false
                }else{
                    sec=0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(sec), execute: { //If first time loading, waits a second to allow database to connect, if not instantly sets orders.
                    self.LoadingText.isHidden=true
                    self.navigationController?.navigationBar.isHidden=false
                    self.setOrders(ordersArray: loadedOrders)
                })
            }else{
                print("new User")
                firstTime=false
                self.LoadingText.isHidden=true
                self.noActiveOrdersLabel.isHidden=false
                self.navigationController?.navigationBar.isHidden=false
            }
            // ...
        })
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

