//
//  SingleOrder.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/29/16.
//  Copyright © 2016 Phil Vasseur. All rights reserved.
//

import UIKit

class SingleOrder {
    var name, foodServing, bunSetting, cheeseSetting, sauceSetting, lettuceSetting,tomatoSetting: String
    var orderNum: Int
    var status: String = "Pending"
    
    init(orderNum: Int, name: String, foodServing: String, bunSetting: String, cheeseSetting: String, sauceSetting: String, lettuceSetting: String, tomatoSetting: String) {
        self.name = name
        self.foodServing = foodServing
        self.bunSetting = bunSetting
        self.cheeseSetting = cheeseSetting
        self.sauceSetting = sauceSetting
        self.lettuceSetting = lettuceSetting
        self.tomatoSetting = tomatoSetting
        self.orderNum = orderNum
    }
    func changeStatusToPreparing(){
        self.status = "Preparing"
    }
    func changeStatusToFinished(){
        self.status = "Finished"
    }
    
}
