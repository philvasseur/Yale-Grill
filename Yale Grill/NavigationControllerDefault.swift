//
//  NavigationControllerDefault.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 9/19/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit

class NavigationControllerDefault: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        var size : CGFloat = 18
        if(UIScreen.main.nativeBounds.height < 1334) {
            size = 17
        }
        let attrs = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "Lato-Bold", size: size)!
        ]
        
        UINavigationBar.appearance().titleTextAttributes = attrs
        UINavigationBar.appearance().tintColor = UIColor.white
        // Do any additional setup after loading the view.
    }
}
