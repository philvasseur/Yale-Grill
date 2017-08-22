//
//  RCValues.swift
//  Yale Grill
//
//  Created by Phil Vasseur on 8/22/17.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import Foundation
import Firebase
import FirebaseRemoteConfig

class RCValues {
    
    static let sharedInstance = RCValues()
    
    var loadingDoneCallback: (() -> ())?
    var fetchComplete: Bool = false
    
    private init() {
        loadDefaultValues()
        fetchCloudValues()
    }
    
    func loadDefaultValues() {
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
        RemoteConfig.remoteConfig().configSettings = remoteConfigSettings!
        RemoteConfig.remoteConfig().setDefaults([
                                  "READYTIMER" : 8 as NSObject,
                                  "strikeBanLimit" : 5 as NSObject,
                                  "banLength" : 10 as NSObject])
    }
    
    func fetchCloudValues() {
        var expirationDuration = 3600
        if RemoteConfig.remoteConfig().configSettings.isDeveloperModeEnabled {
            expirationDuration = 0
        }
        
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                RemoteConfig.remoteConfig().activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
            Constants.READYTIMER = Double(RemoteConfig.remoteConfig().configValue(forKey: "READYTIMER").numberValue!)
            Constants.strikeBanLimit = Int(RemoteConfig.remoteConfig().configValue(forKey: "strikeBanLimit").numberValue!)
            Constants.banLength = Int(RemoteConfig.remoteConfig().configValue(forKey: "banLength").numberValue!)
            
            self.fetchComplete = true
            self.loadingDoneCallback?()
        }
    }
}
