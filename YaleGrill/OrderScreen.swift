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

    @IBAction func SignOutPressed(_ sender: UIBarButtonItem) {
        signOutAndChange(shouldAnimate: true)
    }
    
    
    private func signOutAndChange(shouldAnimate: Bool){ //Separate method since called from two different places
        print("LOGGING OUT")
        GIDSignIn.sharedInstance().signOut()
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let signInScreen = sb.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        self.present(signInScreen!, animated:shouldAnimate, completion:nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if(orderInfo != nil){
            for item in orderInfo!{
                if(!item.isEmpty){
                    print(item)
                }
            }
            orderInfo = nil
        }
        
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

