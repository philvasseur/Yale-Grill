//
//  DynamoCommands.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/30/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import Foundation
import AWSDynamoDB

class DynamoCommands{
    public static var prevOrders : [Orders] = []
    
    public static func dynamoInsertRow(_ row: Orders) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        // Try to insert the row in the DynamoDB table.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        objectMapper.save(row).continue(with: AWSExecutor.mainThread(), with: { (task: AWSTask<AnyObject>!) -> AnyObject! in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let error = task.error {
                // Failed to insert row into Dynamo table. Display error.
                print("ERROR INSERTING: \(error)")
            } else {
                // Successfully inserted row into Dynamo table.
                print("Order inserted into DB!")
            }
            return nil
        })
    }
    
    public static func dynamoDeleteRow(_ row: Orders) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        
        // Try to delete the row from the DynamoDB table.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        objectMapper.remove(row).continue(with: AWSExecutor.mainThread(), with: { (task: AWSTask<AnyObject>!) -> AnyObject! in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let error = task.error {
                // Failed to removed row. Display an alert to notify.
                print("Unable to delete the order: \(error)")
            } else {
                // Successfully removed row. Display an alert to notify.
                print("Order has been deleted!")
                
            }
            return nil
        })
    }
    
    // MARK: Dynamo - Search for orders with this email
    public static func dynamoSearch(email: String) {
       let objectMapper = AWSDynamoDBObjectMapper.default()
        // Set up the query for all rides with the current user's netID.
        let queryForOrders = AWSDynamoDBQueryExpression()
        queryForOrders.scanIndexForward = true
        queryForOrders.keyConditionExpression = "email = :currentUserEmail"
        queryForOrders.expressionAttributeValues = [":currentUserEmail" : email]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        objectMapper.query(Orders.self, expression: queryForOrders).continue(
            { (task: AWSTask<AWSDynamoDBPaginatedOutput>!) -> AnyObject! in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let error = task.error {
                print("Cannot query server: \(error)")
            } else {
                let result = task.result
                prevOrders =  result!.items as! [Orders]
                
            }
            // We don't use the return value from this task.
            return nil
        })
    }
}
