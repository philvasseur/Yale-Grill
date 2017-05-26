//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

/*
 *
 *
 THIS ORDER SCREEN IS NO LONGER USED. IT HAS BEEN REPLACED WITH THE CUSTOMER TABLE VIEW CONTROLLER. IGNORE THIS CODE.
 IT IS OLD LEGACY CODE.
 *
 *
 */


/*
 OrderScreen page. This class is for the page which contains all active orders, sign out button, and compose button. Has all the order information and keeps track of the all of the current orders. GIfs and such on this page as well.
*/

import UIKit
import Firebase

class OrderScreen: UIViewController, GIDSignInUIDelegate{
    
    // MARK: - Outlets
    @IBOutlet weak var LoadingText: UILabel! //LoadingText which shows when first signing in
    @IBOutlet weak var LoadingScreen: UIImageView! //Loading screen which is up until orders are set.
    @IBOutlet var LinesArray: [UIImageView]! //Array of the two white lines which separate the orders
    @IBOutlet var GifViews: [UIImageView]! //Array of the UIImageView which hold the preparing gifs.
    @IBOutlet var OrderItemLabels: [UILabel]! //This and the next two outlets are outlet collections of labels for orders
    @IBOutlet var OrderItemLabels2: [UILabel]!
    @IBOutlet var OrderItemLabels3: [UILabel]!
    @IBOutlet weak var noActiveOrdersLabel: UILabel! //Hidden when an order is created.
    @IBOutlet var FinishedGifArray: [UIImageView]! //Array of UIImageViews which are unhidden when an order is marked finished.
    
    // MARK: - Global Variables
    var allActiveOrders: [String] = [] //Array of the activeOrderIds
    var OrderLabelsArray: [[UILabel]]! //Holds the three OrderItemLabels outlet collections which are defined below. Allows for easy looping through the three sections and their labels
    var timer = Timer() //Used to update the "Preparing..." text to make it animate
    var finishedGif = UIImage.gif(name: "finished")
    var gifArray = [UIImage.gif(name: GlobalConstants.prepGifIDs[0]), UIImage.gif(name: GlobalConstants.prepGifIDs[1]), UIImage.gif(name:GlobalConstants.prepGifIDs[2])] //Image Array of the three preparing gifs
    var selectedDiningHall : String!
    var grillIsOn = false
    var bannedUntil : Date?
    
    
    // MARK: - Actions
    //When the signout button is pressed, calls the signOut method and changes back to login viewController screen.
    @IBAction func SignOutPressed(_ sender: UIBarButtonItem) {
        print("LOGGING OUT") //for debugging
        GIDSignIn.sharedInstance().signOut() //Signs out of the gmail account
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut() //Signs out of the firebase auth
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: GlobalConstants.ViewControllerID) as? LoginViewController
        self.present(signInScreen!, animated:true, completion:nil) //Changes back to the original ViewController

    }
    
    //Used to transfer data when user unwinds from the foodScreen. Called when user pressed the "placeOrder" button, loops through the orders placed
    @IBAction func unwindToOrderScreen(_ sender: UIStoryboardSegue) {
        if let makeOrderController = sender.source as? MenuViewController {
            let tempOrderArray = makeOrderController.ordersPlaced //Gets the placed orders when user Unwinds from FoodScreen
            if(grillIsOn){ //Only goes through orders if the grill is on
                for placedOrder in tempOrderArray{
                    allActiveOrders.append(placedOrder.orderID!) //Adds new orders to local orderIDs array
                    placedOrder.insertIntoDatabase(AllActiveIDs: self.allActiveOrders) //Inserts order into Database
                    FIRDatabase.database().reference().child(GlobalConstants.grills).child(GlobalConstants.GrillIDS[self.selectedDiningHall]!).child(GlobalConstants.orders).child(placedOrder.orderID).setValue(placedOrder.orderID)
                    //Above: Inserts orderID into grill's active orders
                }
            }
        }
    }
    
    
    // MARK: - Functions
    
    //Sets the information for an order. Unhides the labels for all of the order information depending on the index,
    //and sets various GIFs/Status texts depending on the order status.
    private func setSingleOrder(cOrder: Orders, index: Int){
        LinesArray[index].isHidden=false
        OrderLabelsArray[index][0].text=cOrder.foodServing
        OrderLabelsArray[index][1].text=cOrder.bunSetting
        OrderLabelsArray[index][2].text=cOrder.cheeseSetting
        OrderLabelsArray[index][3].text=cOrder.sauceSetting
        OrderLabelsArray[index][4].text=cOrder.lettuceSetting
        OrderLabelsArray[index][5].text=cOrder.tomatoSetting
        let notFinishedTexts = ["Order Placed",GlobalConstants.preparingTexts[0]]
        
        if(cOrder.orderNum > 0 && cOrder.orderNum < 10){
            OrderLabelsArray[index][10].text = "0\(cOrder.orderNum!)"
            OrderLabelsArray[index][10].isHidden = false //The actual order Number label
        }else if(cOrder.orderNum != 0) {
            OrderLabelsArray[index][10].text = "\(cOrder.orderNum!)"
            OrderLabelsArray[index][10].isHidden = false //The actual order Number label
        }
        for i in 0...6{
            OrderLabelsArray[index][i].isHidden=false
        }
        OrderLabelsArray[index][9].isHidden = false //'Order#' Label
        
        
        //Order Status 0 means placed, 1 means preparing, and 2 means Ready
        if(cOrder.orderStatus == 0 || cOrder.orderStatus == 1){
            GifViews[index].isHidden=false
            GifViews[index].image=gifArray[index]
            GifViews[index].layer.cornerRadius = 10
            OrderLabelsArray[index][7].text=notFinishedTexts[cOrder.orderStatus] //Sets to either Preparing or Order Placed
            OrderLabelsArray[index][7].isHidden = false //Unhides the "preparing/order placed" label
            OrderLabelsArray[index][8].isHidden = true //Hides the "Ready for Pickup" label
            FinishedGifArray[index].isHidden=true //Hides the finishedGif Array
        }else if(cOrder.orderStatus == 2){
            OrderLabelsArray[index][7].isHidden=true //Hides 'Preparing...' Label
            OrderLabelsArray[index][8].isHidden=false //Unhides the "Ready For Pickup" Label
            FinishedGifArray[index].image = finishedGif
            FinishedGifArray[index].isHidden=false
            FinishedGifArray[index].layer.cornerRadius = 9 //Unhides and sets properties of Finished Gif
            GifViews[index].isHidden=true //Hides the preparing gif
        }
    }
    
    //Hides all labels, meant to get rid of the remains of any deleted/moved order
    private func wipeLabels(index: Int){
        for eachLabel in OrderLabelsArray[index]{
            eachLabel.isHidden=true
        }
        GifViews[index].isHidden=true
        FinishedGifArray[index].isHidden=true
        LinesArray[index].isHidden=true
        
    }
    
    //Once all previous orders hav ebeen set the Loading text/Screen is hidden and nav bar is unhidden
    func changeFromLoading(){
        //DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
        self.LoadingText.isHidden=true
        self.LoadingScreen.isHidden=true
        self.navigationController?.navigationBar.isHidden=false
        //}
    }
    
    //Called by the timer every second starting from when view first loaded. Only does anything if it isn't hidden and the text is set as the Preparing loop. Gives "Preparing..." animation.
    @objc private func updatePrep(){
        for orderLabels in OrderLabelsArray{
            if(orderLabels[7].text==GlobalConstants.preparingTexts[2]){
                orderLabels[7].text=GlobalConstants.preparingTexts[1]
            }else if(orderLabels[7].text==GlobalConstants.preparingTexts[1]){
                orderLabels[7].text=GlobalConstants.preparingTexts[0]
            }else if(orderLabels[7].text==GlobalConstants.preparingTexts[0]){
                orderLabels[7].text=GlobalConstants.preparingTexts[2]
            }
        }
    }

    
    //Alert method, just used for warning when user trys to place another order after already having three.
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Overridden Functions
    
    //When you hit the composeOrder button tells the foodScreen class how many orders have already been placed. Used to stop user from accidently placing more than 3 orders.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == GlobalConstants.ComposeOrderSegueID){
            let destinationVC = (segue.destination as! MenuViewController)
            destinationVC.totalOrdersCount = allActiveOrders.count //sets num of orders variable in FoodScreen
        }
    }
    
    //Stops segue if 3 orders are already placed, if the grill is off, or if the user has been banned. Creates alert for each one.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if(!grillIsOn){
            createAlert(title: "Sorry!", message: "The \(selectedDiningHall!) grill is currently off! Please try again later during Dining Hall hours.")
            return false
            
        }else if(allActiveOrders.count>=3){
            createAlert(title: "Order Limit Reached!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
            return false
            
        }else if(bannedUntil != nil){
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.full
            let bannedUntilString = dateFormatter.string(from: bannedUntil!)
            createAlert(title: "You've Been Banned!", message: "Due to not picking up 5 orders, you have been temporarily banned from using YaleGrill. This ban will expire on \n\n\(bannedUntilString).\n\n This is an automated ban. If you think this is a mistake, please contact philip.vasseur@yale.edu.")
            return false
            
        }else{
            return true
        }
    }
    
   
    //Sets up a lot of initial functions and observes, read through documentation for more details.
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        OrderLabelsArray=[OrderItemLabels,OrderItemLabels2,OrderItemLabels3] //Sets the OrderLabelsArray
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(OrderScreen.updatePrep), userInfo: nil, repeats: true) //Creates the timer for animations
        self.navigationController?.navigationBar.isHidden=true //Hides the navigation bar for loading screen
        self.title=selectedDiningHall //Sets title as dining hall, which is set in ViewController screen
        
        let grillStatus = FIRDatabase.database().reference().child(GlobalConstants.grills).child(GlobalConstants.GrillIDS[selectedDiningHall]!).child(GlobalConstants.grillStat)
        grillStatus.observe(FIRDataEventType.value, with: { (snapshot) in //Used to check if grill is on or off.
            let status = snapshot.value as? Bool
            if(status==nil){
                grillStatus.setValue(false)
                self.grillIsOn=false
            }else{
                self.grillIsOn=status!
            }
        })
        
        //Reference to the user's specific account
        let user = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!)
        user.observe(FIRDataEventType.value, with: { (snapshot) in //Observes for any changes in the user
            if(snapshot.hasChild(GlobalConstants.activeOrders)){
                let userDic = snapshot.value as! NSDictionary
                let bannedUntilString = userDic["BannedUntil"] as? String
                //Checks if user has bannedUntil property in their account, if so checks if still banned
                if(bannedUntilString != nil){
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
                    self.bannedUntil = dateFormatter.date(from: bannedUntilString!)
                    let timeUntil = self.bannedUntil?.timeIntervalSinceNow
                    if(timeUntil?.isLessThanOrEqualTo(0))!{ //Checks if users banUntil date has passed, if so removes ban
                         self.bannedUntil = nil
                        user.child("BannedUntil").setValue(nil)
                    }
                    print("Banned for: \(timeUntil!)") //debugging
                }else{
                    self.bannedUntil = nil //If no bannedUntil property, then they aren't banned.
                }
                
                
                let orderIDs = userDic[GlobalConstants.activeOrders] as! String //Gets string of all active Orders
                let tempOrders = orderIDs.characters.split { $0 == " " }
                self.allActiveOrders = tempOrders.map(String.init) //These lines just change the string to an array of IDs
                if(self.allActiveOrders.count < 3){
                    for i in  self.allActiveOrders.count...2{ //Loop to clear the sections which have no orders
                        self.wipeLabels(index: i)
                    }
                }
                for orderID in self.allActiveOrders {
                    let orderRef = FIRDatabase.database().reference().child(GlobalConstants.orders).child(orderID)
                    orderRef.removeAllObservers()
                    orderRef.observe(FIRDataEventType.value, with: { (snapshot) in //Observes the specific order
                        let orderDic = snapshot.value as! NSDictionary
                        let order = Orders.convFromJSON(json: orderDic as! [String : AnyObject]) //Converts the JSON from database
                        self.setSingleOrder(cOrder: order, index: self.allActiveOrders.index(of: orderID)!)
                        if(self.allActiveOrders.last==orderID){ //If the active order is the last one, hides loading stuff
                            self.changeFromLoading()
                        }
                    })
                }
                if(self.allActiveOrders.count != 0){ //If there are >0 orders, hides label
                    self.noActiveOrdersLabel.isHidden=true
                }else{
                    self.changeFromLoading() //If there are no orders, hides loading stuff
                    self.noActiveOrdersLabel.isHidden=false
                }
            }else{
                user.child(GlobalConstants.activeOrders).setValue("") //If user has no active orders, creates empty one
                user.child(GlobalConstants.name).setValue(GIDSignIn.sharedInstance().currentUser.profile.name!) //same for name
            }
        })
    }
    //Tries to make sure that Nav bar isn't hidden if the loading screen is hidden.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if(LoadingScreen.isHidden == true) {
            changeFromLoading()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
