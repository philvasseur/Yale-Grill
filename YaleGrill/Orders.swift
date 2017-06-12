//
//  Orders.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 1/5/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//


import Foundation
import UIKit
import Firebase

class Orders : NSObject {
    var userID: String!
    var orderID: String!
    var name: String!
    var foodServing: String!
    var bunSetting: String!
    var cheeseSetting: String!
    var sauceSetting: String!
    var lettuceSetting: String!
    var tomatoSetting: String!
    var orderStatus: Int!
    var orderNum: Int!
    
    private struct DatabaseKeys {
        static let name = "name"
        static let foodServing = "foodServing"
        static let bunSetting = "bunSetting"
        static let cheeseSetting = "cheeseSetting"
        static let sauceSetting = "sauceSetting"
        static let lettuceSetting = "lettuceSetting"
        static let tomatoSetting = "tomatoSetting"
        static let orderStatus = "orderStatus"
        static let orderID = "orderID"
        static let userID = "userID"
        static let orderNum = "orderNum"
        static let grill = "grill"
    }
    
    //Creates a new Orders object
    init(_userID: String,_name : String, _foodServing : String, _bunSetting : String, _cheeseSetting : String, _sauceSetting : String, _lettuceSetting : String, _tomatoSetting: String, _orderStatus : Int,
          _orderID : String?, _orderNum : Int?) {
        self.userID = _userID
        let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil)) as String?
        self.orderID = _orderID ?? uuid
        self.name = _name
        self.foodServing = _foodServing
        self.bunSetting = _bunSetting
        self.cheeseSetting = _cheeseSetting
        self.sauceSetting = _sauceSetting
        self.lettuceSetting = _lettuceSetting
        self.tomatoSetting = _tomatoSetting
        self.orderStatus = _orderStatus
        self.orderNum = _orderNum ?? 0
    }
    
    //Returns an Orders object from a firebase JSON
    convenience init(json : [String : AnyObject]){
        let userID = json[DatabaseKeys.userID] as! String
        let orderID = json[DatabaseKeys.orderID] as! String
        let name = json[DatabaseKeys.name] as! String
        let foodServing = json[DatabaseKeys.foodServing] as! String
        let bunSetting = json[DatabaseKeys.bunSetting] as! String
        let cheeseSetting = json[DatabaseKeys.cheeseSetting] as! String
        let sauceSetting = json[DatabaseKeys.sauceSetting] as! String
        let lettuceSetting = json[DatabaseKeys.lettuceSetting] as! String
        let tomatoSetting = json[DatabaseKeys.tomatoSetting] as! String
        let orderStatus = json[DatabaseKeys.orderStatus] as! Int
        let orderNum = json[DatabaseKeys.orderNum] as! Int
        self.init(_userID: userID, _name: name, _foodServing: foodServing, _bunSetting: bunSetting, _cheeseSetting: cheeseSetting, _sauceSetting: sauceSetting, _lettuceSetting: lettuceSetting, _tomatoSetting: tomatoSetting, _orderStatus: orderStatus, _orderID : orderID, _orderNum: orderNum)
        
    }
    
    //Inserts a new order into fireBase database
    func insertIntoDatabase(selectedDiningHall : String){
        let currentOrder = FIRDatabase.database().reference().child("Orders").child(orderID)
        currentOrder.setValue(convToJSON(selectedDiningHall: selectedDiningHall))
        
        //Inserts orderID/OrderStatus/OrderPushToken into Grills active orders
        let grillOrderInfo: [String: AnyObject] = [
            GlobalConstants.orderStatus : self.orderStatus as AnyObject,
            "pushToken": FIRInstanceID.instanceID().token() as AnyObject,
            ]
        FIRDatabase.database().reference().child(GlobalConstants.grills).child(selectedDiningHall).child(GlobalConstants.orders).child(self.orderID).setValue(grillOrderInfo)
        
        
        //Inserts OrderID into Users active orders
        FIRDatabase.database().reference().child(GlobalConstants.users).child(GIDSignIn.sharedInstance().currentUser.userID!).child(GlobalConstants.activeOrders).child(self.orderID).setValue(selectedDiningHall)
        
    }
    
    //Changes current Orders object into a json object to be uploaded to firebase
    private func convToJSON(selectedDiningHall : String) -> [String : AnyObject] {
        let jsonObject: [String: AnyObject] = [
            DatabaseKeys.name : name as AnyObject,
            DatabaseKeys.foodServing: foodServing as AnyObject,
            DatabaseKeys.bunSetting: bunSetting as AnyObject,
            DatabaseKeys.cheeseSetting: cheeseSetting as AnyObject,
            DatabaseKeys.sauceSetting: sauceSetting as AnyObject,
            DatabaseKeys.lettuceSetting: lettuceSetting as AnyObject,
            DatabaseKeys.tomatoSetting: tomatoSetting as AnyObject,
            DatabaseKeys.orderStatus: orderStatus as AnyObject,
            DatabaseKeys.orderID: orderID as AnyObject,
            DatabaseKeys.userID: userID as AnyObject,
            DatabaseKeys.orderNum: orderNum as AnyObject,
            DatabaseKeys.grill : selectedDiningHall as AnyObject
        ]
        
        return jsonObject
    }
    
}
