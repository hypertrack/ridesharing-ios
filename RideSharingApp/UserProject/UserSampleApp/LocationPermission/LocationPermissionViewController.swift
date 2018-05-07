//
//  LocationPermissionViewController.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 07/05/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack
import CoreLocation

protocol LocationPermissionProtocol: class {
    func didFinishedAskingPermissions(currentController : UIViewController)
}

class LocationPermissionViewController: UIViewController {
   
    @IBOutlet weak var descriptionTextLabel: UILabel!
    
    weak var permissionDelegate: LocationPermissionProtocol? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        descriptionTextLabel.textColor = UIColor(red:0.61, green:0.61, blue:0.61, alpha:1)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationPermissionViewController.onForegroundNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func locationPermissionPressed(_ sender: UIButton) {
        if (!HyperTrack.locationServicesEnabled()) {
            HyperTrack.requestLocationServices()
            return
        }
        let status = HyperTrack.locationAuthorizationStatus()
        handleLocationStatus(status: status)
    }
    
    private func handleLocationStatus(status: CLAuthorizationStatus) {
        if status == .notDetermined {
            // first time
            handlLocationNotDetermined()
        } else if status == .authorizedAlways {
            self.dismissViewController()
        } else if status == .authorizedWhenInUse {
            self.dismissViewController()
        } else {
            // Permission Not Given
            self.goToSettings()
        }
    }
    
    private func handlLocationNotDetermined() {
        HyperTrack.requestAlwaysLocationAuthorization(completionHandler: { (isAuthorized) in
            if self.isLocationPermissionGiven() == true {
                self.dismissViewController()
            }
        })
    }
    
    private func goToSettings() {
        guard let urlGeneral = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        UIApplication.shared.open(urlGeneral)
    }
    
    
    @objc private func onForegroundNotification(_ notification: Notification) {
        if self.isLocationPermissionGiven() == true {
            self.dismissViewController()
        }
    }
    
    private func isLocationPermissionGiven() -> (Bool) {
        if HyperTrack.locationServicesEnabled() == false {
            return false
        }
        if HyperTrack.locationAuthorizationStatus() == .authorizedAlways ||
            HyperTrack.locationAuthorizationStatus() == .authorizedWhenInUse {
            return true
        } else {
            return false
        }
    }
    
    private func dismissViewController() {
        self.dismiss(animated: false, completion: {
            self.permissionDelegate?.didFinishedAskingPermissions(currentController: self)
        })
    }
    
}
