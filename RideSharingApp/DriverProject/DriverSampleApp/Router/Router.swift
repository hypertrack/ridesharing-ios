//
//  Router.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 11/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import UIKit


class Router {
    
    static func launchHome(forDriver driver: Driver) {
        let homeVC = HomeViewController.init(withDriver: driver)
        self.getWindow()?.rootViewController = homeVC
    }
    
    static func launchLogin() {
        let storyboard = UIStoryboard.init(name: "Login", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        self.getWindow()?.rootViewController = vc
    }
    
    static func launchAcceptRide(forTrip trip: Trip, presentOverViewController parentVC: UIViewController) -> AcceptRideViewController {
        let vc = AcceptRideViewController.init(withTrip: trip)
        parentVC.present(vc, animated: true, completion: nil)
        return vc
    }
    
    static func launchLocationPermission(inParent parentVC: UIViewController) -> LocationPermissionViewController {
        let vc = LocationPermissionViewController.init(nibName: "LocationPermissionViewController", bundle: nil)
        parentVC.present(vc, animated: true, completion: nil)
        return vc
    }
    
    static private func getWindow() -> UIWindow? {
        var window: UIWindow? = nil
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            window = appDelegate.window
        }
        return window
    }
    
}
