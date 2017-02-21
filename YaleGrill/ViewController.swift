//
//  ViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

class ViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, CLLocationManagerDelegate{
    
    /*
     Method for googleSign in. Is called when you press the button and when the application loads. Checks if there is authentication in keychain cached, if so checks if a yale email. If it has a yale email then moves to OrderScreen page with active orders. If not a yale email then logs out.
     */
    
    // MARK: - Outlets
    @IBOutlet weak var diningHallTextField: UITextField!
    @IBOutlet weak var DisabledSignInColor: UIImageView!
    @IBOutlet weak var LoadingImage: UIImageView!
    @IBOutlet weak var LoadingBack: UIImageView!
    @IBOutlet weak var GSignInButton: GIDSignInButton!
    
    
    // MARK: - Global Variables
    let pickerView = UIPickerView()
    let locationManager = CLLocationManager()
    var currentLocation : CLLocation!
    var pickerDataSource = FirebaseConstants.PickerData
    
    
    // MARK: - Functions
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        /* check for user's token */
        let selectedDiningHall = diningHallTextField.text //When sign in pressed, gets what the current Dining hall is set to
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
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
                        let dHallRef = FIRDatabase.database().reference().child(FirebaseConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(FirebaseConstants.prevDining)
                        dHallRef.observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                            let pastDHall = snapshot.value as? String
                            if((pastDHall != nil) && (FirebaseConstants.GrillIDS[pastDHall!] != nil)){
                                self.diningHallTextField.text = pastDHall
                                self.performSegue(withIdentifier: FirebaseConstants.SignInSegueID, sender: nil) //Segues to OrderScreen
                            }else { //Should never happen unless someone messes with database
                                GIDSignIn.sharedInstance().signOut()
                                self.createAlert(title: "Sorry about that!", message: "We can't find a previously selected dining hall or the dining hall we found is not activated. If you think this is an error, contact philip.vasseur@yale.edu.")
                                print("No Accessible Dining Hall")
                                self.LoadingBack.isHidden=true
                                self.LoadingImage.isHidden=true
                            }
                        })
                    }else{ //If Dining Hall selected is actual dining hall
                        if(FirebaseConstants.GrillIDS[selectedDiningHall!] != nil){ //Checks that dining hall is activated
                            let dHallRef = FIRDatabase.database().reference().child(FirebaseConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(FirebaseConstants.prevDining)
                            dHallRef.setValue(selectedDiningHall) //Updates last dining hall logged into
                            self.performSegue(withIdentifier: FirebaseConstants.SignInSegueID, sender: nil) //Segues to OrderScreen
                        }else{
                            GIDSignIn.sharedInstance().signOut()
                            self.createAlert(title: "\(selectedDiningHall!) Dining Hall isn't activated!", message: "Please select another dining hall. If you think this is an error, contact philip.vasseur@yale.edu.")
                        }
                    }
                }
            }else if(FirebaseConstants.CookEmailArray.contains(cEmail.lowercased())){ //If not a yale email, checks if the account is a cook's account
                guard let authentication = user.authentication else { return }
                let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in //If so authenticates the cooks account
                    if let error = error {
                        print("Firebase Auth Error: \(error)")
                        return
                    }
                    self.performSegue(withIdentifier: FirebaseConstants.ControlScreenSegueID, sender: nil) //Then segues to the ControlScreenView
            }
            }else{ //Not a yale email, so signs user out
                print("Non-Yale Email, LOGGING OUT")
                GIDSignIn.sharedInstance().signOut()
                createAlert(title: "Invalid Email Address!", message: "You must use a Yale email address to sign in!")
            }
        }else if(error != nil){
            print("Sign In Error: \(error)")
            LoadingBack.isHidden=true
            LoadingImage.isHidden=true
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
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
        return pickerDataSource[row]
    }
    //PickerView function which returns the number of rows (number of colleges), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    //PickerView function, which checks if the college has a grillID (which means it is activated), is used for dining hall selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.diningHallTextField.text=pickerDataSource[row]
        if(FirebaseConstants.GrillIDS[pickerDataSource[row]] != nil){ //Checks GrillIDs dictionary for the college
            GSignInButton.isEnabled=true
        }else{
            GSignInButton.isEnabled=false //If not, deactivates signIn button
        }
    }
    
    //To get the location and compare it to the closet dining hall, to auto fill for new dining hall.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last!
        var closestDiningHall = ["DiningHall": "None","Distance" : CLLocationDistanceMax] as [String : Any]
        for college in FirebaseConstants.coordinates{ //Loops through the colleges and checks which dining hall is closest
            let dis = college.value.distance(from: currentLocation)
            if(dis < closestDiningHall["Distance"] as! CLLocationDistance && dis<=100){
                closestDiningHall["DiningHall"] = college.key
                closestDiningHall["Distance"] = dis
            }
        }
        if(closestDiningHall["DiningHall"] as! String != "None"){ //If there is a closest dining hall, updates the DiningHall string
            let row = FirebaseConstants.PickerData.index(of :closestDiningHall["DiningHall"] as! String)!
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
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
     
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier==FirebaseConstants.SignInSegueID){
            let destinationNav = segue.destination as! UINavigationController
            let destinationVC = destinationNav.viewControllers.first as! OrderScreen
            destinationVC.selectedDiningHall = self.diningHallTextField.text
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

