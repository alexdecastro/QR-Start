//
//  AppDelegate.swift
//  QR Start
//
//  Created by Alex DeCastro on 8/29/2019.
//

import UIKit

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("AppDelegate: application: didFinishLaunchingWithOptions:")
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidQRTimeout(notification:)), name: NSNotification.Name(rawValue: TimerUIApplication.QRTimeoutNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidLoginTimeout(notification:)), name: NSNotification.Name(rawValue: TimerUIApplication.LoginTimeoutNotification), object: nil)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("AppDelegate: applicationDidEnterBackground:")
        
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            if let myTVC = navigationController.visibleViewController as? MainTVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
            if let myTVC = navigationController.visibleViewController as? KsadsVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
            if let myTVC = navigationController.visibleViewController as? MillisecondVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
            if let myTVC = navigationController.visibleViewController as? BloodDrawTVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
            if let myTVC = navigationController.visibleViewController as? HairSampleTVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
            if let myTVC = navigationController.visibleViewController as? PHSalivaTVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
            if let myTVC = navigationController.visibleViewController as? GeneticSalivaTVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidEnterBackground()
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    @objc func applicationDidQRTimeout(notification: NSNotification) {
        print("AppDelegate: applicationDidQRTimeout:")
        
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            if let myTVC = navigationController.visibleViewController as? MainTVC {
                // Call a function defined in your view controller.
                myTVC.applicationDidQRTimeout()
            }
        }
    }
    @objc func applicationDidLoginTimeout(notification: NSNotification) {
        print("AppDelegate: applicationDidLoginTimeout:")

        // Go back to the login screen
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: true)
        }
    }
}

