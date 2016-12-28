//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    
    @IBOutlet weak var OrderFoodButton: UIButton!
    @IBOutlet weak var WelcomeMessage: UILabel!
    
    @IBAction func signOutPressed(_ sender: Any) { //Connects to signout button
        signOutAndChange(shouldAnimate: true)
    }
    
    
    private func signOutAndChange(shouldAnimate: Bool){ //Separate method since called from two different places
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        WelcomeMessage.text=""
        OrderFoodButton.isHidden=true
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(signInScreen!, animated:shouldAnimate, completion:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        
    }
   
    override func viewDidLoad() { //Doesn't do much as have to wait till view appears incase non Yale email
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) { //Checks if yale email, if not sends back, if so sets various info
        let cEmail = GIDSignIn.sharedInstance().currentUser.profile.email!
        if(cEmail.lowercased().range(of: "@yale.edu")==nil){
            signOutAndChange(shouldAnimate: false)
        }else{
            let cName = GIDSignIn.sharedInstance().currentUser.profile.name!
            WelcomeMessage.text="Hi, \(cName)"
            OrderFoodButton.isHidden=false
            OrderFoodButton.layer.cornerRadius = 12
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

