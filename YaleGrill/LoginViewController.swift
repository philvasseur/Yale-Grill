//
//  LoginViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import NVActivityIndicatorView

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, UIPickerViewDelegate, UIPickerViewDataSource, CLLocationManagerDelegate{
    
    //LOCATION SERVICES NOT TURNED ON ATM
    
    // MARK: - Outlets
    @IBOutlet weak var diningHallTextField: UITextField!
    @IBOutlet weak var DisabledSignInColor: UIImageView!
    @IBOutlet weak var GSignInButton: GIDSignInButton!
    @IBOutlet weak var loggingInIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loggingInView: UIView!
    @IBOutlet weak var launchAnimation: NVActivityIndicatorView!
    
    // MARK: - Global Variables
    let pickerView = UIPickerView()
    let locationManager = CLLocationManager()
    let launchView = UIView()
    var currentLocation : CLLocation!
    var allActiveOrders : [Orders] = []
    var selectedDiningHall : String?
    
    
    // MARK: - Functions
    
    
    //Method for googleSign in. Is called when you press GIDSignInButton and on openif user is already logged in (silentSignIn)
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if(error != nil){ //If there was an error authenticating google keychain
            print("Couldn't sign in, Error: \(error.localizedDescription)")
            return;
        }

        print("Attempting Signing In")
        
        //Checks emails, if a student then gets the dining hall, if cook then segues, if neither logs out
        let emailType = self.checkEmail(email: user.profile.email)
        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        if(emailType == .Yale){
            self.startLoginAnimation()
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in //Firebase then authenticates user
                if let error = error {
                    print("Firebase Auth Error: \(error)")
                    self.signOutGoogleAndFirebase()
                    return
                }
                //If it's a yale email, gets the currently selected dining hall
                self.getDiningHall { success in //Completion handler used to make sure a dining hall is actually set
                    if(success) {
                        self.loadOrdersAndSegue()
                    } else { //Happens during a bug with pickerView or if user's prevDiningHall is no longer available
                        self.signOutGoogleAndFirebase()
                        self.stopLoginAnimation()
                        Constants.createAlert(title: "Cannot Load Dining Hall", message: "Please select another dining hall. If you think this is an error, contact philip.vasseur@yale.edu.", style: .error)
                    }
                }
            }
        } else if (emailType == .Cook) {
            self.startLoginAnimation()
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in //Firebase then authenticates user
                if let error = error {
                    print("Firebase Auth Error: \(error)")
                    self.signOutGoogleAndFirebase()
                    return
                }
                //If it is a cooks email then segues right away
                self.performSegue(withIdentifier: Constants.ControlScreenSegueID, sender: nil)
            }
        } else if (emailType == .Other) {
            //Not a yale email, so signs user out
            print("Non-Yale Email, LOGGING OUT")
            self.signOutGoogleAndFirebase()
            self.stopLoginAnimation()
            Constants.createAlert(title: "Invalid Email Address", message: "This app is for Yale students only. Use a valid Yale email address to login.",style: .error)
        }
        
    }
    
    //Checks if a dining hall is selected, if not grabs previously logged in dining hall from database
    func getDiningHall(completion : @escaping (Bool) -> ()) {
        let dHallRef = FIRDatabase.database().reference().child(Constants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(Constants.prevDining)
        if(Constants.ActiveGrills[diningHallTextField.text!] != nil) {
            selectedDiningHall = diningHallTextField.text
            dHallRef.setValue(self.selectedDiningHall) //Updates last dining hall logged into for user
            completion(true)
            return
        }
        
        dHallRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let pastDHall = snapshot.value as? String ?? "Select Dining Hall"
            if (Constants.ActiveGrills[pastDHall] != nil)  {
                self.selectedDiningHall = pastDHall
                completion(true)
            } else {
                dHallRef.removeValue()
                //There is no active dining hall selected, cannot login
                completion(false)
            }
        })
    }
    
    //Checks if the emailed used to login is a valid Yale/Cook email
    func checkEmail(email: String) -> Constants.EmailType {
        //Checks if email is a Yale email
        if(email.lowercased().range(of: "@yale.edu") != nil){
            return .Yale
            //If not a yale email, checks if the email is contained in the cooks email array (case insensitively)
        }else if (Constants.ActiveGrills.values.contains(where: {$0.caseInsensitiveCompare(email) == .orderedSame})) {
            return .Cook
        }else{
            return .Other
        }
    }
    
    //Loads the user orders and ban info, for CUSTOMERS only. Cooks don't need this checked.
    func loadOrdersAndSegue() {
        let user = FIRDatabase.database().reference().child(Constants.users).child(GIDSignIn.sharedInstance().currentUser.userID!)
        user.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in //Gets initial info for user
            var orderIDs : [String] = []
            if(snapshot.hasChild("Name")) {
                let userDic = snapshot.value as! NSDictionary
                //If the user has an active ban, returns and does not login
                if(self.isBanned(bannedUntilString: userDic["BannedUntil"] as? String, user: user)) {
                    return
                }
                //Keys are timeStamp based, so we can sort to make sure orders are shown in same order they're placed
                for (orderID, grillName) in userDic[Constants.activeOrders] as? [String: String] ?? [:] {
                    if(grillName == self.selectedDiningHall) {
                        orderIDs.append(orderID)
                    }
                }
            }else{
                //Sets name if user doesn't exist yet.
                user.child(Constants.name).setValue(GIDSignIn.sharedInstance().currentUser.profile.name!)
            }
            
            if(orderIDs.count == 0) {
                self.performSegue(withIdentifier: Constants.SignInSegueID, sender: nil)
            }
            
            for key in orderIDs.sorted() {
                FIRDatabase.database().reference().child(Constants.orders).child(key).observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                    self.allActiveOrders.append(Orders.init(orderID: snapshot.key, json: snapshot.value as! Dictionary))
                    if(self.allActiveOrders.count == orderIDs.count) { //Onces all the orders have been loaded
                        self.performSegue(withIdentifier: Constants.SignInSegueID, sender: nil) //Segues to OrderScreen
                    }
                })
            }
        })
        
    }
    
    //Takes the bannedUntil format in the database and checks if it has passed already or not
    func isBanned(bannedUntilString : String?, user: FIRDatabaseReference) -> Bool {
        var bannedUntil : Date?
        //Checks if user has bannedUntil property in their account, if so checks if still banned
        if(bannedUntilString == nil){
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        bannedUntil = dateFormatter.date(from: bannedUntilString!)
        let timeUntil = bannedUntil?.timeIntervalSinceNow
        if(timeUntil?.isLessThanOrEqualTo(0))!{ //Checks if users banUntil date has passed, if so removes ban
            user.child("BannedUntil").setValue(nil)
            return false
        }
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateStyle = DateFormatter.Style.full
        let banEndString = dateFormatter2.string(from: bannedUntil!)
        Constants.createAlert(title: "You've Been Banned!", message: "Due to not picking up 5 orders, you have been temporarily banned from using YaleGrill. This ban will expire on \n\n\(banEndString).\n\n This is an automated ban. If you think this is a mistake, please contact philip.vasseur@yale.edu.",
            style: .error)
        self.stopLoginAnimation()
        self.signOutGoogleAndFirebase()
        return true
    }
    
    //Loads the Dining Hall grill names and emails for the pickerView from firebase
    func loadDiningHalls(completion: @escaping () -> ()) {
        //Loads the cook grillIDs and corresponding emails from database
        let grillRef = FIRDatabase.database().reference().child(Constants.grills).child("ActiveGrills")
        grillRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            Constants.ActiveGrills = snapshot.value as! [String : String]
            for(grillName,_) in Constants.ActiveGrills {
                Constants.PickerData.append(grillName)
            }
            completion();
            
        })
    }
    
    //Starts the animation for NORMAL signin
    func startLoginAnimation(){
        self.loggingInIndicator.startAnimating()
        self.loggingInIndicator.isHidden = false
        self.loggingInView.isHidden = false
        pickerView.isHidden = true
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    //Stops the animation for NORMAL signin
    func stopLoginAnimation(){
        self.loggingInIndicator.stopAnimating()
        self.loggingInIndicator.isHidden = true
        self.loggingInView.isHidden = true
        pickerView.isHidden = false
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    //Signs out of both google and firebase authentication, also hides potential launchView
    func signOutGoogleAndFirebase() {
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.launchView.alpha = 0.0
        })
        GIDSignIn.sharedInstance().signOut()
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
    
    
    // MARK: - PickerView and LocationManager delegates
    
    //PickerView function which sets the number of components (to 1), is used for dining hall selection
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //PickerView function which returns the college based on what row is selected, is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Constants.PickerData[row]
    }
    //PickerView function which returns the number of rows (number of colleges), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Constants.PickerData.count
    }
    //PickerView function, which checks if the college has a grillID (which means it is activated), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.diningHallTextField.text=Constants.PickerData[row]
        if(Constants.PickerData[row] == "Select Dining Hall"){ //Checks GrillIDs dictionary for the college
            GSignInButton.isEnabled = false
        }else{
            GSignInButton.isEnabled = true //If not the default, enables the dining hall
        }
    }
    
    //To get the location and compare it to the closet dining hall, to auto fill for new dining hall.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last!
        var closestDiningHall = ["DiningHall": "None","Distance" : CLLocationDistanceMax] as [String : Any]
        for college in Constants.coordinates{ //Loops through the colleges and checks which dining hall is closest
            let dis = college.value.distance(from: currentLocation)
            if(dis < closestDiningHall["Distance"] as! CLLocationDistance && dis<=100){
                closestDiningHall["DiningHall"] = college.key
                closestDiningHall["Distance"] = dis
            }
        }
        if(closestDiningHall["DiningHall"] as! String != "None"){ //If there is a closest dining hall, updates the DiningHall string
            let row = Constants.PickerData.index(of :closestDiningHall["DiningHall"] as! String)!
            pickerView.selectRow(row, inComponent: 0, animated: false)
            pickerView(pickerView, didSelectRow: row, inComponent: 1)
        }
        self.locationManager.stopUpdatingLocation()
        
    }
    //Location function to check for failing.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed with error: \(error)")
    }
    
    func createLaunchView() {
        //Keeps the launchScreen while loading the dining hall names
        self.view.addSubview(launchView)
        NSLayoutConstraint.useAndActivate(constraints:
            [launchView.centerXAnchor.constraint(equalTo: (self.view.centerXAnchor)),
             launchView.centerYAnchor.constraint(equalTo: (self.view.centerYAnchor)),
             launchView.heightAnchor.constraint(equalTo: (self.view.heightAnchor)),
             launchView.widthAnchor.constraint(equalTo: (self.view.widthAnchor))
            ])
        launchView.backgroundColor = UIColor.white
        let launchImage = UIImageView()
        launchImage.image = UIImage(named: "finalIconFull")
        launchView.addSubview(launchImage)
        
        NSLayoutConstraint.useAndActivate(constraints:
            [launchImage.centerXAnchor.constraint(equalTo: (launchView.centerXAnchor)),
             NSLayoutConstraint(item: launchImage, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: launchView, attribute: NSLayoutAttribute.centerY, multiplier: 0.8, constant: 0),
             launchImage.widthAnchor.constraint(equalTo: (launchView.widthAnchor)),
             launchImage.heightAnchor.constraint(equalTo: (launchImage.widthAnchor))
            ])
        launchView.addSubview(launchAnimation)
        launchAnimation.startAnimating()
    }
    
    
    // MARK: - Overridden Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.showsSelectionIndicator = true
        pickerView.dataSource = self
        pickerView.delegate = self
        diningHallTextField.inputView = pickerView
        GSignInButton.isEnabled=false
        DisabledSignInColor.layer.cornerRadius = 2 //Used to set the color for when login button when disabled
        self.diningHallTextField.text = "Select Dining Hall"
        
        //Style for the loading indicator when someone logs in
        loggingInIndicator.activityIndicatorViewStyle = .whiteLarge
        loggingInView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        loggingInView.layer.cornerRadius = 10.0
        loggingInIndicator.hidesWhenStopped = true
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        //only want to load dining halls when app is opened, not on logout
        if(Constants.appJustOpened) {
            Constants.appJustOpened = false
            createLaunchView()
            loadDiningHalls {_ in //On success of loading dining halls, either hides launch view or signsInSilently for autologin
                if(GIDSignIn.sharedInstance().hasAuthInKeychain()) {
                    GIDSignIn.sharedInstance().signInSilently()
                } else { //If user has no authentication on app open, hides the loading screen
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.launchView.alpha = 0.0
                    })
                }
            }
        }
    }
    
    
    //Sets the customers order information before segueing
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        stopLoginAnimation()
        if(segue.identifier==Constants.SignInSegueID){
            let destinationNav = segue.destination as! UINavigationController
            let destinationVC = destinationNav.viewControllers.first as! CustomerTableViewController
            destinationVC.selectedDiningHall = self.selectedDiningHall
            destinationVC.allActiveOrders = self.allActiveOrders
            destinationVC.tableView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

