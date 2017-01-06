//
//  FirebaseConstants.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation

class FirebaseConstants {
    //Grill Constants
    static let GrillIDS = ["Jonathan Edwards" : "105206071860987390121"] //pvass153@gmail.com
    static let CookEmailArray = ["pvass153@gmail.com"]
    static let orders = "Orders"
    static let grills = "Grills"
    static let grillStat = "GrillIsOn"
    static let users = "Users"
    static let activeOrders = "ActiveOrders"
    static let name = "Name"
    static let turnGrillOnText = "Turn Grill On"
    static let turnGrillOffText = "Turn Grill Off"
    static let orderStatus = "orderStatus"
    static let ready = "Ready"
    static let delete = "Delete"
    static let markAsReady = "Mark as Ready"
    
    //FOOD CONSTANTS
    static let foodServingArray = [["Single Burger","Double Burger"],["Single Veggie Burger","Double Veggie Burger"],["One Piece of Chicken","Two Pieces of Chicken","Three Pieces of Chicken","Four Pieces of Chicken"]]
    static let toppingsArray = ["Bun","Cheese","Sauce","Lettuce","Tomatoes"]
    static let preparingTexts = ["Preparing...","Preparing..","Preparing.","Preparing"]
    
    //ID Constants
    static let SignInSegueID = "SignInSegue"
    static let ControlScreenSegueID = "ControlScreenSegue"
    static let ComposeOrderSegueID = "ComposeOrder"
    static let ViewControllerID = "ViewController"
    static let prepGifIDs = ["preparing","preparing2","preparing3"]
    static let cellIdentifier = "cell"
    
    //Other
    static let PickerData = ["Jonathan Edwards", "Branford", "Ezra Stiles","Trumbull","Davenport","Timothy Dwight","Morse","Calhoun"]
    static let UserReadyText = "Ready for Pickup!"
    
}
