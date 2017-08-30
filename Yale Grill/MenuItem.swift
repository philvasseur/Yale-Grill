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
    var options: [String]!
    
    //Creates a new Orders object
    init(_title : String, _info: String, _image : UIImage, _quantities: [String]!, _options: [String]! = []) {
        title = _title
        info = _info
        image = _image
        quantities = _quantities
        options = _options
    }
    
    //Returns an Orders object from a firebase JSON
    convenience init(json : [String : AnyObject]){
        let title = json["Title"] as! String
        let info = json["Info"] as! String
        let options = json["Options"] as? [String] ?? []
        let quantities = json["Quantities"] as? [String] ?? []
        let imageName = json["ImageName"] as! String
        self.init(_title: title,_info: info,_image: UIImage(), _quantities: quantities,_options: options)
        Storage.storage().reference(withPath: "menu/\(imageName).jpg").getData(maxSize: 2097152) { data, error in
            if let error = error {
                print("Unable to download file for menu item: \(title). ERROR: \(error)")
                print("Will be set to default image")
            } else {
                // Data for user image is returned
                self.image = UIImage(data: data!)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "menuImageLoaded"), object: nil, userInfo: ["item": self])
            }
        }
    }
    
}

