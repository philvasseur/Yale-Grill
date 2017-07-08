//
//  UIColorExtensions.swift
//  Bookster
//
//  Created by Matthew Vasseur on 12/29/16.
//  Copyright © 2016 Matthew Vasseur. All rights reserved.
//

import UIKit

extension UIColor {
    
    /**
     Extend UIColor initializer to take RGB integers and alpha
     - parameters:
     - red: Red Value
     - green: Blue Value
     - blue: Blue Value
     - withAlpha: Alpha value
     */
    convenience init(red: Int, green: Int, blue: Int, withAlpha alpha: CGFloat) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
    }
    
    /**
     Extend UIColor initializer to take RGB integers (or hex)
     - parameters:
     - red: Red Value
     - green: Blue Value
     - blue: Blue Value
     */
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: red, green: green, blue: blue, withAlpha: 1.0)
    }
    
    /**
     Extend UIColor initializer to hexadecimal strings and alpha
     - parameters:
     - hex: Hexadecimal string beginning with #
     - withAlpha: Alpha value
     */
    convenience init(hex: String, withAlpha alpha: CGFloat){
        // Trim and format hex string (e.g. remove whitespace and '#' prefix)
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        // Initialize RBG Color to 0 and create a scanner for the hex string
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        // Read the colors
        let newRed = CGFloat((rgbValue & 0xFF0000) >> 16) / 255
        let newGreen = CGFloat((rgbValue & 0x00FF00) >> 8) / 255
        let newBlue = CGFloat(rgbValue & 0x0000FF) / 255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
    }
    
    /**
     Extend UIColor initializer to hexadecimal strings
     - parameters:
     - hex: Hexadecimal string beginning with #
     */
    convenience init(hex: String){
        self.init(hex: hex, withAlpha: 1.0)
    }
}
