//
//  MenuItem.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 8/18/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class MenuItem : NSObject {
    var title: String!
    var info: String!
    var image: UIImage!
    var quantities: [String]!
    var options: [String]?
    
    //Creates a new Orders object
    init(_title : String, _info: String, _image : UIImage, _quantities: [String]!, _options: [String]? = nil) {
        title = _title
        info = _info
        image = _image
        quantities = _quantities
        options = _options
    }
    
}

