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

class OrderScreen: UIViewController, GIDSignInUIDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var LoadingText: UILabel! //LoadingText which shows when first signing in, allows orders queried before user can see active orders screen
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
    private var finishedGif = UIImage.gif(name: "finished")
    var pickerDataSource = ["Jonathan Edwards", "Branford", "Ezra Stiles","Trumbull","Davenport","Timothy Dwight","Morse","Calhoun"]
    var diningHall : String = "Jonathan Edwards"
    @IBOutlet weak var PickerView: UIPickerView!
    @IBOutlet weak var SelectDiningHallLabel: UILabel!
    var grillIsOn = false
    
    // MARK: - Actions
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
            if(grillIsOn){
                for oldOrder in tempOrderArray{
                    allActiveOrders.append(oldOrder.orderID!)
                    oldOrder.insertIntoDatabase(AllActiveIDs: allActiveOrders)
                    FIRDatabase.database().reference().child("Grills").child(FirebaseConstants.GrillIDS[diningHall]!).child("Orders").child(oldOrder.orderID).setValue(oldOrder.orderID)
                }
            }
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
    
    //Sets an order to finished. Called when cook sets the order to complete.
    //Changes the order to the new one (should just have status updated), but also hides the "Status" and "Preparing..." labels, and the PreparingGif. 
    //Unhides the foodIsReady label and the FinishedGif.
    private func updateOrderAsFinished(cOrder: Orders, index: Int){
        let orderLoc = index
        var cOrderLabels = OrderLabelsArray[orderLoc]
        cOrderLabels[7].text="Ready for Pickup!"
        cOrderLabels[7].textColor = UIColor.black
        cOrderLabels[7].font = UIFont(name:"Verdana-Bold", size: 20.0)
        cOrderLabels[7].frame.origin = CGPoint(x: 125, y: cOrderLabels[7].frame.origin.y)
        FinishedGifArray[orderLoc].image = finishedGif
        FinishedGifArray[orderLoc].isHidden=false
        FinishedGifArray[orderLoc].layer.cornerRadius = 9
        GifViews[orderLoc].isHidden=true
        /*cOrderLabels[6].isHidden=true
        cOrderLabels[7].isHidden=true
        FoodIsReadyLabelArray[orderLoc].isHidden=false
        */
        
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
        if(!grillIsOn){
            createAlert(title: "Sorry!", message: "The grill is not currently on! Please try again during Dining Hall hours!")
            return false
        }else if(allActiveOrders.count>=3){
            createAlert(title: "Sorry!", message: "You can't place more than 3 orders! Please wait for your current orders to be finished!")
            //ABILITY TO MAKE ORDERS "FINISHED"
            return false
        }else{
            return true
        }
    }
    
    //Sets the information for an order. Unhides the labels depending on what type of food, and also either sets as preparing or finished depending on orderStatus
    private func setSingleOrder(cOrder: Orders, index: Int){
        //let index : Int = cOrder.orderLocation!
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
            GifViews[index].layer.cornerRadius = 10
            OrderLabelsArray[index][6].isHidden=false
            OrderLabelsArray[index][7].text="Preparing..."
            OrderLabelsArray[index][7].isHidden = false
            OrderLabelsArray[index][7].textColor = UIColor.init(netHex: 0x4C8BF6)
            OrderLabelsArray[index][7].font = UIFont(name:"Verdana-Regular", size: 16.0)
            OrderLabelsArray[index][7].frame.origin = CGPoint(x: 86, y: OrderLabelsArray[index][7].frame.origin.y)
            FinishedGifArray[index].isHidden=true
        }else if(cOrder.orderStatus == 1){
            updateOrderAsFinished(cOrder: cOrder, index: index)
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        diningHall=pickerDataSource[row]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
   
    //Sets the values of the OrderLabelsArray and creates/calls timer.
    //More important calls the async Observe function, this keeps realTime data for the updating of orders.
    //Checks for any value changes in the user's database, if it has activeOrders child that means user is not new. If new then it waits for it to be created from first order creation.
    override func viewDidLoad() {
        super.viewDidLoad()
        PickerView.dataSource = self
        PickerView.delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        OrderLabelsArray=[OrderItemLabels,OrderItemLabels2,OrderItemLabels3]
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(OrderScreen.updatePrep), userInfo: nil, repeats: true)
        self.navigationController?.navigationBar.isHidden=true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
        })
        let grillStatus = FIRDatabase.database().reference().child("Grills").child(FirebaseConstants.GrillIDS[diningHall]!).child("GrillIsOn")
        grillStatus.observe(FIRDataEventType.value, with: { (snapshot) in
            let status = snapshot.value as? Bool
            if(status==nil){
                grillStatus.setValue(false)
                self.grillIsOn=false
            }else{
                self.grillIsOn=status!
            }
        })
        let user = FIRDatabase.database().reference().child("Users").child(GIDSignIn.sharedInstance().currentUser.userID!)
        user.observe(FIRDataEventType.value, with: { (snapshot) in
            if(snapshot.hasChild("ActiveOrders")){
                let userDic = snapshot.value as! NSDictionary
                let orderIDs = userDic["ActiveOrders"] as! String
                let tempOrders = orderIDs.characters.split { $0 == " " }
                self.allActiveOrders = tempOrders.map(String.init)
                for orderID in self.allActiveOrders {
                    let orderRef = FIRDatabase.database().reference().child("Orders").child(orderID)
                    orderRef.removeAllObservers()
                    orderRef.observe(FIRDataEventType.value, with: { (snapshot) in
                        let orderDic = snapshot.value as! NSDictionary
                        let order = Orders.convFromJSON(json: orderDic as! [String : AnyObject])
                        self.changeFromLoading()
                        self.setSingleOrder(cOrder: order, index: self.allActiveOrders.index(of: orderID)!)
                    })
                }
                
                if(self.allActiveOrders.count != 0){
                    self.noActiveOrdersLabel.isHidden=true
                    self.PickerView.isHidden=true
                    self.SelectDiningHallLabel.isHidden=true
                }else{
                    self.changeFromLoading()
                    self.noActiveOrdersLabel.isHidden=false
                    //self.PickerView.isHidden=false
                    //self.SelectDiningHallLabel.isHidden=false
                }
                if(self.allActiveOrders.count < 3){
                    for i in  self.allActiveOrders.count...2{
                        self.wipeLabels(index: i)
                    }
                }
            }else{
                user.child("ActiveOrders").setValue("")
                user.child("Name").setValue(GIDSignIn.sharedInstance().currentUser.profile.name!)
            }
        })
    }
    func changeFromLoading(){
        self.LoadingText.isHidden=true
        self.navigationController?.navigationBar.isHidden=false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

