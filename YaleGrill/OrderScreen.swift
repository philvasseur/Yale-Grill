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
    @IBAction func signOutPressed(_ sender: Any) {
        signOutAndChange(shouldAnimate: true)
    }
    
    private func signOutAndChange(shouldAnimate: Bool){
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        WelcomeMessage.text=""
        OrderFoodButton.isHidden=true
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(signInScreen!, animated:shouldAnimate, completion:nil)
    }
    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let cEmail = GIDSignIn.sharedInstance().currentUser.profile.email!
        if(cEmail.lowercased().range(of: "@yale.edu")==nil){
            signOutAndChange(shouldAnimate: false)
        }else{
            let cName = GIDSignIn.sharedInstance().currentUser.profile.name!
            WelcomeMessage.text="Hi, \(cName)"
            OrderFoodButton.isHidden=false
            OrderFoodButton.layer.cornerRadius = 10
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

