//
//  AppDelegate.swift
//  Habits
//
//  Created by Tiago Fernandes on 08/02/2026.
//

import ObjectiveC
import UIKit
import OSLog

internal class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Logger.location.debug("App was launched")

        return true
    }
}
