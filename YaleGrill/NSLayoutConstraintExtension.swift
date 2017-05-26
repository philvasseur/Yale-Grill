//
//  NSLayoutConstraintExtension.swift
//  Cub Tracker
//
//  Created by Matthew Vasseur on 3/21/17.
//  Copyright © 2017 YaleLeo. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
    
    /**
     Activate a list of constraints and turn off auto resizing for each view
     - parameter constraints: List of constraints to activate
     */
    class func useAndActivate(constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            if let view = constraint.firstItem as? UIView {
                view.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        activate(constraints)
    }
}
