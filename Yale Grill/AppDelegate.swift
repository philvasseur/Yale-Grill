//
//  AppDelegate.swift
//  YaleGrill
//
//  Created by Phil Vasseur on 12/27/16.
//  Copyright © 2017 Phil Vasseur. All rights reserved.
//

import UIKit
import Firebase
import FirebaseRemoteConfig
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var dBaseRef = Database.database().reference()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        if(configureError != nil){
            print("We have an error!")
        }
        
        // iOS 10 support
        if #available(iOS 10, *) {
            let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_,_ in })
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
            
        } else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        application.registerForRemoteNotifications()
        
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Lato-Regular", size: 17.0)!], for: .normal)
        let attrs = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "Lato-Bold", size: 18)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        UINavigationBar.appearance().tintColor = UIColor.white
        
        loadMenu()
        loadDefaultValues()
        fetchCloudValues()
                
        return true
    }
    
    func loadDefaultValues() {
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
        RemoteConfig.remoteConfig().configSettings = remoteConfigSettings!
        RemoteConfig.remoteConfig().setDefaults([
            "READYTIMER" : 8 as NSObject,
            "strikeBanLimit" : 5 as NSObject,
            "banLength" : 10 as NSObject,
            "orderLimit" : 3 as NSObject])
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
            Constants.orderLimit = Int(RemoteConfig.remoteConfig().configValue(forKey: "orderLimit").numberValue!)
        }
    }
    
    func loadMenu() {
        Constants.menuItems = []
        Database.database().reference().child("Menu").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let json = snapshot.value as? [Any] ?? []
            for menuItemjson in json {
                Constants.menuItems.append(MenuItem(json: menuItemjson as? [String : AnyObject] ?? [:]))
            }
        })
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
}
extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("refresh")
    }

    func application(received remoteMessage: MessagingRemoteMessage) {
        print("%@ Data Message: ", remoteMessage.appData)
    }
}
