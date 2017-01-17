//
//  FirebaseConstants.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import CoreLocation

class FirebaseConstants {
    //Grill Constants
    static let GrillIDS = ["Jonathan Edwards" : "105206071860987390121"] //pvass153@gmail.com
    static let CookEmailArray = ["pvass153@gmail.com"]
    static let coordinates  = ["Jonathan Edwards": CLLocation(latitude: 41.308839, longitude: -72.929976),"Branford" : CLLocation(latitude: 41.310051, longitude: -72.930137), "Saybrook":CLLocation(latitude: 41.310170, longitude: -72.929643), "Ezra Stiles":CLLocation(latitude: 41.312518, longitude: -72.930721), "Morse":CLLocation(latitude: 41.312609, longitude: -72.930268),"Trumbull":CLLocation(latitude: 41.310499, longitude: -72.928823), "Silliman":CLLocation(latitude: 41.311213, longitude: -72.924982)]
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
    static let delete = "Mark Picked Up"
    static let markAsReady = "Mark Ready"
    static let prevDining = "PreviousDiningHall"
    
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
    static let PickerData = ["Select Dining Hall","Jonathan Edwards", "Branford", "Ezra Stiles","Trumbull","Davenport","Timothy Dwight","Morse","Calhoun", "Pierson","Saybrook","Berkeley","Silliman"]
    static let UserReadyText = "Ready for Pickup!"
    
}
