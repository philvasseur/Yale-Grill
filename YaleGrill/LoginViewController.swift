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
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadAnimation: NVActivityIndicatorView!
    
    // MARK: - Global Variables
    let pickerView = UIPickerView()
    let locationManager = CLLocationManager()
    let launchView = UIView()
    var currentLocation : CLLocation!
    var allActiveIDs : [String] = []
    var selectedDiningHall : String?
    var cEmail : String!
    
    
    // MARK: - Functions
    
    /*
     Method for googleSign in. Is called when you press the button and when the application loads. Checks if there is authentication in keychain cached, if so gets the dining hall and then checks if the email is a yale/cook email.
     */
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            self.startLoadAnimation()
            cEmail = GIDSignIn.sharedInstance().currentUser.profile.email!
            print("\(cEmail!): Attempting Signing In")
            
            guard let authentication = user.authentication else { return }
            let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            FIRAuth.auth()?.signIn(with: credential) { (_, error) in //Firebase then authenticates user
                if let error = error {
                    print("Firebase Auth Error: \(error)")
                    self.signOutGoogleAndFirebase()
                    return
                }
                
                
                //If checks emails, if a student then gets the dining hall
                if(self.isYaleEmail(user: user)) {
                    self.getDiningHall { success in
                        //Checks to make sure a dining hall is actually chosen
                        if(success) {
                            let dHallRef = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(GlobalConstants.prevDining)
                            dHallRef.setValue(self.selectedDiningHall) //Updates last dining hall logged into
                            self.loadUserAndSegue()
                            
                        } else { //Happens during a bug with pickerView, rare, but taken into account just in case
                            self.signOutGoogleAndFirebase()
                            self.stopLoadAnimation()
                            self.createAlert(title: "Sorry, cannot load the dining hall!", message: "Please select another dining hall. If you think this is an error, contact philip.vasseur@yale.edu.")
                        }
                    }
                }
            }
            
            //If there was an error authenticating google keychain
        }else if(error != nil){
            print("Couldn't sign in, Error: \(error!)")
        }
        
    }
    
    //Gets the last dining hall from firebase server, used for autologin as only autologins in if previous
    //dining hall exists
    func getDiningHall(completion : @escaping (Bool) -> ()) {
        if(GlobalConstants.GrillEmails[diningHallTextField.text!] != nil) {
            selectedDiningHall = diningHallTextField.text
            completion(true)
            return
        }
        let dHallRef = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(GlobalConstants.prevDining)
        
        dHallRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            
            let pastDHall = snapshot.value as? String ?? "Select Dining Hall"
            if (GlobalConstants.GrillEmails[pastDHall] != nil)  {
                self.selectedDiningHall = pastDHall
                completion(true)
            } else {
                completion(false)
            }
            
        })
        
    }
    
    //Checks if the emailed used to login is a valid email
    func isYaleEmail(user: GIDGoogleUser!) -> Bool {
        //Checks if email is a Yale email
        if(cEmail.lowercased().range(of: "@yale.edu") != nil){
            return true
            
            //If not a yale email, checks if the email is contained in the cooks email array (case insensitively)
        }else if (GlobalConstants.GrillEmails.values.contains(where: {$0.caseInsensitiveCompare(cEmail) == .orderedSame})) {
            self.performSegue(withIdentifier: GlobalConstants.ControlScreenSegueID, sender: nil) //Then segues to the ControlScreenView
            return false
            
            //Not a yale email, so signs user out
        }else{
            print("Non-Yale Email, LOGGING OUT")
            signOutGoogleAndFirebase()
            self.stopLoadAnimation()
            createAlert(title: "Invalid Email Address!", message: "You must use a Yale email address to sign in!")
            return false
        }
    }
    
    //Loads the user orders and ban info, for CUSTOMERS only. Cooks don't need this checked.
    func loadUserAndSegue() {
        let user = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!)
        user.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in //Gets initial info for user
            if(snapshot.hasChild("Name")) {
                let userDic = snapshot.value as! NSDictionary
                //If the user has an active ban, returns and does not login
                if(self.isBanned(bannedUntilString: userDic["BannedUntil"] as? String, user: user)) {
                    return
                }
                let ordersValue = userDic[GlobalConstants.activeOrders] as? [String: String] ?? [:]
                for (key, _) in ordersValue {
                    self.allActiveIDs.append(key)
                }
                
            }else{
                //Sets name if user doesn't exist yet.
                user.child(GlobalConstants.name).setValue(GIDSignIn.sharedInstance().currentUser.profile.name!)
            }
            self.performSegue(withIdentifier: GlobalConstants.SignInSegueID, sender: nil) //Segues to OrderScreen
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
        self.createAlert(title: "You've Been Banned!", message: "Due to not picking up 5 orders, you have been temporarily banned from using YaleGrill. This ban will expire on \n\n\(banEndString).\n\n This is an automated ban. If you think this is a mistake, please contact philip.vasseur@yale.edu.")
        self.stopLoadAnimation()
        self.signOutGoogleAndFirebase()
        return true
    }
    
    func startLoadAnimation(){
        self.loadingIndicator.startAnimating()
        self.loadingIndicator.isHidden = false
        self.loadingView.isHidden = false
        pickerView.isHidden = true
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func stopLoadAnimation(){
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.isHidden = true
        self.loadingView.isHidden = true
        pickerView.isHidden = false
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func signOutGoogleAndFirebase() {
        UIView.animate(withDuration: 0.25, delay: 0,
                       options: UIViewAnimationOptions.curveEaseOut, animations: {
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
    
    
    //Alert Function to create an alert
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //PickerView function which sets the number of components (to 1), is used for dining hall selection
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //PickerView function which returns the college based on what row is selected, is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return GlobalConstants.PickerData[row]
    }
    //PickerView function which returns the number of rows (number of colleges), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return GlobalConstants.PickerData.count
    }
    //PickerView function, which checks if the college has a grillID (which means it is activated), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.diningHallTextField.text=GlobalConstants.PickerData[row]
        if(GlobalConstants.PickerData[row] == "Select Dining Hall"){ //Checks GrillIDs dictionary for the college
            GSignInButton.isEnabled = false
        }else{
            GSignInButton.isEnabled = true //If not the default, enables the dining hall
        }
    }
    
    //To get the location and compare it to the closet dining hall, to auto fill for new dining hall.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last!
        var closestDiningHall = ["DiningHall": "None","Distance" : CLLocationDistanceMax] as [String : Any]
        for college in GlobalConstants.coordinates{ //Loops through the colleges and checks which dining hall is closest
            let dis = college.value.distance(from: currentLocation)
            if(dis < closestDiningHall["Distance"] as! CLLocationDistance && dis<=100){
                closestDiningHall["DiningHall"] = college.key
                closestDiningHall["Distance"] = dis
            }
        }
        if(closestDiningHall["DiningHall"] as! String != "None"){ //If there is a closest dining hall, updates the DiningHall string
            let row = GlobalConstants.PickerData.index(of :closestDiningHall["DiningHall"] as! String)!
            pickerView.selectRow(row, inComponent: 0, animated: false)
            pickerView(pickerView, didSelectRow: row, inComponent: 1)
        }
        self.locationManager.stopUpdatingLocation()
        
    }
    //Location function to check for failing.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed with error: \(error)")
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
        loadingIndicator.activityIndicatorViewStyle = .whiteLarge
        loadingView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        loadingView.layer.cornerRadius = 10.0
        loadingIndicator.hidesWhenStopped = true
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        //only want to load dining halls when app is opened, not on logout
        if(GlobalConstants.appJustOpened) {
            GlobalConstants.appJustOpened = false
            loadDiningHalls()
        }
        
        if(GIDSignIn.sharedInstance().hasAuthInKeychain()) {
            GIDSignIn.sharedInstance().signInSilently()
        } else {
            self.launchView.isHidden=true
        }
        
    }
    
    func loadDiningHalls() {
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
        launchView.addSubview(loadAnimation)
        loadAnimation.startAnimating()
        
        //Loads the cook grillIDs and corresponding emails from database
        let grillRef = FIRDatabase.database().reference().child(GlobalConstants.grills).child("GrillEmails")
        grillRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            GlobalConstants.GrillEmails = snapshot.value as! [String : String]
            for(key,_) in GlobalConstants.GrillEmails {
                GlobalConstants.PickerData.append(key)
            }
            
        })
    }
    
    //Sets the customers order information before segueing
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        stopLoadAnimation()
        if(segue.identifier==GlobalConstants.SignInSegueID){
            let destinationNav = segue.destination as! UINavigationController
            let destinationVC = destinationNav.viewControllers.first as! CustomerTableViewController
            destinationVC.selectedDiningHall = self.selectedDiningHall
            destinationVC.allActiveIDs = self.allActiveIDs
            destinationVC.tableView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
}

