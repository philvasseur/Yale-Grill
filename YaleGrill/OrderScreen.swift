//
//  OrderScreen.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class OrderScreen: UIViewController, GIDSignInUIDelegate {
    
    var orderInfo : [String]?
    @IBOutlet weak var OrderFoodButton: UIButton!
    @IBOutlet weak var WelcomeMessage: UILabel!
    @IBOutlet weak var ActiveOrdersLabel: UILabel!
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
    
    override func viewWillDisappear(_ animated: Bool){
        super.viewWillDisappear(animated)
        ActiveOrdersLabel.isHidden=true
        self.navigationController?.isNavigationBarHidden = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ActiveOrdersLabel.isHidden=false
        self.navigationController?.isNavigationBarHidden = true
        if(orderInfo != nil){
            for item in orderInfo!{
                if(!item.isEmpty){
                    print(item)
                }
            }
            orderInfo = nil
        }
        
    }
   
    override func viewDidLoad() { //Doesn't do much as have to wait till view appears incase non Yale email
        super.viewDidLoad()
        let cName = GIDSignIn.sharedInstance().currentUser.profile.name!
        WelcomeMessage.text="Hi, \(cName)"
        OrderFoodButton.isHidden=false
        OrderFoodButton.layer.cornerRadius = 12
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

