//
//  FirebaseConstants.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import CoreLocation

class Constants {
    //Grill Constants
    //add to this array to activate new cook accounts, make sure to add the emailID to the grillIDs array too
    static var ActiveGrills : [String : String] = [:]
    static var selectedDiningHall : String!
    static var currentOrders : [Orders] = []
    static var appJustOpened = true;
    static var PickerData = ["Select Dining Hall"]
    static let coordinates  = [
        "Jonathan Edwards": CLLocation(latitude: 41.308839, longitude: -72.929976),
        "Branford" : CLLocation(latitude: 41.310051, longitude: -72.930137),
        "Saybrook":CLLocation(latitude: 41.310170, longitude: -72.929643),
        "Ezra Stiles":CLLocation(latitude: 41.312518, longitude: -72.930721),
        "Morse":CLLocation(latitude: 41.312609, longitude: -72.930268),
        "Trumbull":CLLocation(latitude: 41.310499, longitude: -72.928823),
        "Silliman":CLLocation(latitude: 41.311213, longitude: -72.924982)
    ]
    
    enum Status: Int {
        case Placed, Preparing, Ready, PickedUp
    }
    
    enum EmailType: Int {
        case Yale, Cook, Other
    }
    
    
    //Remote Config Defaults
    static var READYTIMER : Double = 8 //minutes left ready till user is given a strike
    static var strikeBanLimit = 5 //strikes until user gets a ban
    static var banLength = 10 //day long ban length
    static var orderLimit = 3 //day long ban length
    //defaults end
    
    static let orders = "Orders"
    static let grills = "Grills"
    static let grillStatus = "GrillIsOn"
    static let users = "Users"
    static let activeOrders = "ActiveOrders"
    static let name = "Name"
    static let turnGrillOnText = "Turn Grill On"
    static let turnGrillOffText = "Turn Grill Off"
    static let orderStatus = "orderStatus"
    static let prevDining = "PreviousDiningHall"
    
    //FOOD CONSTANTS
    static let foodServingArray = [
        ["Single Burger","Double Burger"],
        ["Single Veggie Burger","Double Veggie Burger"],
        ["One Piece of Chicken","Two Pieces of Chicken","Three Pieces of Chicken","Four Pieces of Chicken"]
    ]
    static let toppingsArray = ["Bun","Cheese","Sauce","Lettuce","Tomatoes"]
    static let preparingTexts = ["Preparing...","Preparing..","Preparing.","Preparing"]
    static let gifArray = ["preparing1","preparing2","preparing3","preparing4","preparing5"]
    
    static var menuItems: [MenuItem] = []
    
    //ID Constants
    static let SignInSegueID = "SignInSegue"
    static let ControlScreenSegueID = "ControlScreenSegue"
    static let ComposeOrderSegueID = "ComposeOrder"
    static let ViewControllerID = "ViewController"
    
    //Other
    static let UserReadyText = "Ready for Pickup!"
    
    static func createAlert (title : String, message : String, style: SCLAlertViewStyle){
        let alertAppearance = SCLAlertView.SCLAppearance(kWindowWidth: 300, kWindowHeight: 200, contentViewCornerRadius: 10, buttonCornerRadius: 8)
        let alert = SCLAlertView(appearance: alertAppearance)
        switch style {
        case .error:
            alert.showError(title, subTitle: message, closeButtonTitle: "Okay")
        case .warning:
            alert.showWarning(title, subTitle: message, closeButtonTitle: "Okay")
        case .notice:
            alert.showNotice(title, subTitle: message, closeButtonTitle: "Okay")
        case .success:
            alert.showSuccess(title, subTitle: message, closeButtonTitle: "Okay")
        case .info:
            alert.showInfo(title, subTitle: message, closeButtonTitle: "Okay")
        case .edit:
            alert.showEdit(title, subTitle: message, closeButtonTitle: "Okay")
        case .wait:
            alert.showWait(title, subTitle: message, closeButtonTitle: "Okay",colorStyle: 0x3C7DEA)
        }
    }
    
}
