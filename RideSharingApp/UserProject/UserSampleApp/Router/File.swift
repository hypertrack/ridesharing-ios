//
//  File.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 20/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import UIKit

class Router {
    
    static func launchHome(forUser user: User) {
        let homeVC = HomeViewController.init(withUser: user)
        self.getWindow()?.rootViewController = homeVC
    }
    
    static func launchLogin() {
        let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        self.getWindow()?.rootViewController = vc
    }

    static private func getWindow() -> UIWindow? {
        var window: UIWindow? = nil
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            window = appDelegate.window
        }
        return window
    }
    
}
