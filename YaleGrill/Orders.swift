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

class Orders {
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
    }
    
    //Inserts a new order into fireBase database, also sets value of ActiveOrders in firebase database (as empty string if no active orders)
    func insertIntoDatabase(AllActiveIDs : [String]){
        /*let activeOrders = FIRDatabase.database().reference().child("Users").child(userID).child("ActiveOrders")
        let totalIDs = AllActiveIDs.joined(separator: " ")
        activeOrders.setValue(totalIDs)*/
        let currentOrder = FIRDatabase.database().reference().child("Orders").child(orderID)
        currentOrder.setValue(convToJSON())
        
    }
    
    //Changes current Orders object into a json object to be uploaded to firebase
    private func convToJSON() -> [String : AnyObject] {
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
            DatabaseKeys.orderNum: orderNum as AnyObject
        ]
        
        return jsonObject
    }
    
    //Returns an Orders object from a firebase JSON
    class func convFromJSON(json : [String : AnyObject]) -> Orders {
        let order = Orders()
        order.userID = json[DatabaseKeys.userID] as! String
        order.orderID = json[DatabaseKeys.orderID] as! String
        order.name = json[DatabaseKeys.name] as! String
        order.foodServing = json[DatabaseKeys.foodServing] as! String
        order.bunSetting = json[DatabaseKeys.bunSetting] as! String
        order.cheeseSetting = json[DatabaseKeys.cheeseSetting] as! String
        order.sauceSetting = json[DatabaseKeys.sauceSetting] as! String
        order.lettuceSetting = json[DatabaseKeys.lettuceSetting] as! String
        order.tomatoSetting = json[DatabaseKeys.tomatoSetting] as! String
        order.orderStatus = json[DatabaseKeys.orderStatus] as! Int
        order.orderNum = json[DatabaseKeys.orderNum] as! Int
        
        return order
    }
    
    //Creates a new Orders object
    class func createNewObject(_userID: String,_name : String, _foodServing : String, _bunSetting : String, _cheeseSetting : String, _sauceSetting : String, _lettuceSetting : String, _tomatoSetting: String, _orderStatus : Int) -> Orders {
        let order = Orders()
        order.userID = _userID
        let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil))
        order.orderID = uuid as String?
        order.name = _name
        order.foodServing = _foodServing
        order.bunSetting = _bunSetting
        order.cheeseSetting = _cheeseSetting
        order.sauceSetting = _sauceSetting
        order.lettuceSetting = _lettuceSetting
        order.tomatoSetting = _tomatoSetting
        order.orderStatus = _orderStatus
        order.orderNum = 0

        return order
    }
}
