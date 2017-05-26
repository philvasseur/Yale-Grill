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

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate{
    
    /*
     Method for googleSign in. Is called when you press the button and when the application loads. Checks if there is authentication in keychain cached, if so checks if a yale email. If it has a yale email then moves to OrderScreen page with active orders. If not a yale email then logs out.
     */
    
    // MARK: - Outlets
    @IBOutlet weak var diningHallTextField: UITextField!
    @IBOutlet weak var DisabledSignInColor: UIImageView!
    @IBOutlet weak var GSignInButton: GIDSignInButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingView: UIView!
    
    // MARK: - Global Variables
    let pickerView = UIPickerView()
    let locationManager = CLLocationManager()
    var currentLocation : CLLocation!
    var pickerDataSource = GlobalConstants.PickerData
    var allActiveIDs : [String] = []
    
    
    // MARK: - Functions
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        /* check for user's token */
        
        let selectedDiningHall = diningHallTextField.text //When sign in pressed, gets what the current Dining hall is set to
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            self.startLoadAnimation()
            print("\(GIDSignIn.sharedInstance().currentUser.profile.email!) TRYING TO SIGN IN - AUTH")
            let cEmail = GIDSignIn.sharedInstance().currentUser.profile.email!
            if(cEmail.lowercased().range(of: "@yale.edu") != nil){ //Checks if email is a Yale email
                guard let authentication = user.authentication else { return }
                let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in //Firebase then authenticates user
                    if let error = error {
                        print("Firebase Auth Error: \(error)")
                        return
                    }
                    
                    if(selectedDiningHall=="Select Dining Hall"){ //Should Only happen if autologin, thus it pulls the last dHall logged into from the database
                        self.pullDiningHall()
                    }else{ //If Dining Hall selected is actual dining hall
                        if(GlobalConstants.GrillIDS[selectedDiningHall!] != nil){ //Checks that dining hall is activated
                            let dHallRef = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(GlobalConstants.prevDining)
                            dHallRef.setValue(selectedDiningHall) //Updates last dining hall logged into
                            self.loadUserAndSegue()
                            
                        }else{ //Happens during a bug with pickerView, rare, but took into account just in case
                            GIDSignIn.sharedInstance().signOut()
                            self.stopLoadAnimation()
                            self.createAlert(title: "\(selectedDiningHall!) Dining Hall isn't activated!", message: "Please select another dining hall. If you think this is an error, contact philip.vasseur@yale.edu.")
                        }
                    }
                }

                
            }else if(GlobalConstants.CookEmailArray.contains(cEmail.lowercased())){ //If not a yale email, checks if the account is a cook's account
                guard let authentication = user.authentication else { return }
                let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in //If so authenticates the cooks account
                    if let error = error {
                        print("Firebase Auth Error: \(error)")
                        return
                    }
                    self.performSegue(withIdentifier: GlobalConstants.ControlScreenSegueID, sender: nil) //Then segues to the ControlScreenView
                }
            }else{ //Not a yale email, so signs user out
                print("Non-Yale Email, LOGGING OUT")
                stopLoadAnimation()
                GIDSignIn.sharedInstance().signOut()
                createAlert(title: "Invalid Email Address!", message: "You must use a Yale email address to sign in!")
            }
        }else if(error != nil){
            print("Sign In Error: \(error)")
            stopLoadAnimation()
            self.locationManager.delegate = self //still need to fully implement location services
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        }
    }
    
    
    func loadUserAndSegue() { //Loads the user orders and ban info, for CUSTOMERS only. Cooks don't need this checked.
        let user = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!)
        user.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in //Gets initial info for user
            var bannedUntil : Date? = nil
            if(snapshot.hasChild(GlobalConstants.activeOrders)){
                let userDic = snapshot.value as! NSDictionary
                let bannedUntilString = userDic["BannedUntil"] as? String
                
                //Checks if user has bannedUntil property in their account, if so checks if still banned
                if(bannedUntilString != nil){
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
                    bannedUntil = dateFormatter.date(from: bannedUntilString!)
                    let timeUntil = bannedUntil?.timeIntervalSinceNow
                    if(timeUntil?.isLessThanOrEqualTo(0))!{ //Checks if users banUntil date has passed, if so removes ban
                        bannedUntil = nil
                        user.child("BannedUntil").setValue(nil)
                    }
                    print("Banned for: \(timeUntil!)") //debugging
                }
                
                let ordersValue = userDic[GlobalConstants.activeOrders] as? [String: String]
                for (key, _) in ordersValue! {
                    self.allActiveIDs.append(key)
                }
                
            }else{
                user.child(GlobalConstants.name).setValue(GIDSignIn.sharedInstance().currentUser.profile.name!) //same for name
            }
            if(bannedUntil != nil){
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = DateFormatter.Style.full
                let bannedUntilString = dateFormatter.string(from: bannedUntil!)
                self.createAlert(title: "You've Been Banned!", message: "Due to not picking up 5 orders, you have been temporarily banned from using YaleGrill. This ban will expire on \n\n\(bannedUntilString).\n\n This is an automated ban. If you think this is a mistake, please contact philip.vasseur@yale.edu.")
                
                print("LOGGING OUT")
                GIDSignIn.sharedInstance().signOut()
                let firebaseAuth = FIRAuth.auth()
                do {
                    try firebaseAuth?.signOut()
                } catch let signOutError as NSError {
                    print ("Error signing out: %@", signOutError)
                }
                self.stopLoadAnimation()
            }else {
                self.performSegue(withIdentifier: GlobalConstants.SignInSegueID, sender: nil) //Segues to OrderScreen
            }
        })
    }
    
    //Gets the last dining hall from firebase server, used for autologin
    func pullDiningHall() {
        let dHallRef = FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(GlobalConstants.prevDining)
        dHallRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let pastDHall = snapshot.value as? String
            if((pastDHall != nil) && (GlobalConstants.GrillIDS[pastDHall!] != nil)){
                self.diningHallTextField.text = pastDHall
                self.loadUserAndSegue()
            }else { //Should never happen unless someone messes with database
                GIDSignIn.sharedInstance().signOut()
                self.stopLoadAnimation()
                self.createAlert(title: "Sorry about that!", message: "We can't find a previously selected dining hall or the dining hall we found is not activated. If you think this is an error, contact philip.vasseur@yale.edu.")
                print("No Accessible Dining Hall")
            }
        })
    }
    
    func startLoadAnimation(){
        self.loadingIndicator.startAnimating()
        self.loadingIndicator.isHidden = false
        self.loadingView.isHidden = false
        pickerView.isHidden = true
    }
    
    func stopLoadAnimation(){
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.isHidden = true
        self.loadingView.isHidden = true
        pickerView.isHidden = false
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
        return pickerDataSource[row]
    }
    //PickerView function which returns the number of rows (number of colleges), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    //PickerView function, which checks if the college has a grillID (which means it is activated), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.diningHallTextField.text=pickerDataSource[row]
        if(GlobalConstants.GrillIDS[pickerDataSource[row]] != nil){ //Checks GrillIDs dictionary for the college
            GSignInButton.isEnabled=true
        }else{
            GSignInButton.isEnabled=false //If not, deactivates signIn button
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
        DisabledSignInColor.layer.cornerRadius = 2
        self.diningHallTextField.text = "Select Dining Hall"
        
        
        loadingIndicator.activityIndicatorViewStyle = .whiteLarge
        
        loadingView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        loadingView.layer.cornerRadius = 10.0
        loadingIndicator.hidesWhenStopped = true
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
     
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier==GlobalConstants.SignInSegueID){
            let destinationNav = segue.destination as! UINavigationController
            let destinationVC = destinationNav.viewControllers.first as! CustomerTableViewController
            destinationVC.selectedDiningHall = self.diningHallTextField.text
            destinationVC.allActiveIDs = self.allActiveIDs
            destinationVC.tableView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

