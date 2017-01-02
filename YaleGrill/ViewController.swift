//
//  ViewController.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    @IBOutlet weak var LoadingLabel: UILabel!
    var timer = Timer()
    @IBOutlet weak var SignInButton: GIDSignInButton!
    @IBOutlet weak var SignInText: UILabel!
    @IBOutlet weak var SignInPicture: UIImageView!
    //Page for logging in. Doesn't do much besides try to auto login. Contains the GIDSignIn button.
    /*
     Method for googleSign in. Is called when you press the button and when the application loads. Checks if there is authentication in keychain cached, if so checks if a yale email. If it has a yale email then moves to OrderScreen page with active orders. If not a yale email then logs out.
     */
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        /* check for user's token */
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            print("\(GIDSignIn.sharedInstance().currentUser.profile.email!) TRYING TO SIGN IN - AUTH")
            let cEmail = GIDSignIn.sharedInstance().currentUser.profile.email!
            if(cEmail.lowercased().range(of: "@yale.edu") != nil){ //Checks if email is a Yale email
                print("Yale Email, SIGNING IN")
                SignInText.isHidden=true
                SignInButton.isHidden=true
                SignInPicture.isHidden=true
                LoadingLabel.isHidden=false
                DynamoCommands.dynamoSearch(email: GIDSignIn.sharedInstance().currentUser.profile.email!)
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.runLoadingAnimation), userInfo: nil, repeats: true)
                //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                    // Put your code which should be executed with a delay here
                while(!DynamoCommands.queryFinished){                    
                }
                   self.performSegue(withIdentifier: "SignInSegue", sender: nil)
               // })
            }else{ //Not a yale email, so signs user out.
                print("Non-Yale Email, LOGGING OUT")
                GIDSignIn.sharedInstance().signOut()
                createAlert(title: "Sorry!", message: "You must use a Yale email address to sign in!")
            }
        }else if(error != nil){
            print("Sign In Error: \(error)")
        }
    }
    func runLoadingAnimation(){
        if(LoadingLabel.text=="Loading..."){
            LoadingLabel.text="Loading."
        }else if(LoadingLabel.text=="Loading."){
            LoadingLabel.text="Loading.."
        }else if(LoadingLabel.text=="Loading.."){
            LoadingLabel.text="Loading..."
        }
    }
    
    func createAlert (title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in alert.dismiss(animated: true, completion: nil)}))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signInSilently()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}

