//
//  LocationPermissionViewController.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 30/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack
import CoreLocation

enum PermissionKeys: String {
    case coreMotion = "permission.CoreMotion"
}

protocol LocationPermissionProtocol: class {
    func didFinishedAskingPermissions(currentController : UIViewController)
}

class LocationPermissionViewController: UIViewController {

    @IBOutlet weak var descriptionTextLabel: UILabel!
    
    weak var permissionDelegate: LocationPermissionProtocol? = nil
    var pollingTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        descriptionTextLabel.textColor = UIColor(red:0.61, green:0.61, blue:0.61, alpha:1)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationPermissionViewController.onForegroundNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LocationPermissionViewController.onBackgroundNotification(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func permissionPressed(_ sender: UIButton) {
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
        } else if status != .authorizedAlways {
            handleLocationAuthroizeNotAlways()
        } else if status == .authorizedAlways {
            handleLocationAuthorizeAlways()
        }
    }
    
    private func handlLocationNotDetermined() {
        HyperTrack.requestAlwaysLocationAuthorization(completionHandler: { (isAuthorized) in
            if(isAuthorized) {
                self.promptMotionPermission()
            }
        })
    }
    
    private func handleLocationAuthroizeNotAlways() {
        goToSettings()
    }
    
    private func handleLocationAuthorizeAlways() {
        self.promptMotionPermission()
    }
    
    private func goToSettings() {
        guard let urlGeneral = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        UIApplication.shared.open(urlGeneral)
    }
    
    @objc private func onForegroundNotification(_ notification: Notification) {
        if HyperTrack.locationServicesEnabled() == false {
            return
        }
        if (HyperTrack.locationAuthorizationStatus() == .authorizedAlways) {
            promptMotionPermission()
        }
    }
    
    @objc private func onBackgroundNotification(_ notification: Notification) {
        self.pollingTimer?.invalidate()
    }
    
    private func initializeTimer() {
        pollingTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self, selector: #selector(checkForMotionPermission),
                                            userInfo: nil, repeats: true)
    }
    
    // This should be always called once location permission is perfect
    private func promptMotionPermission() {
        if HyperTrack.isActivityAvailable() {
            let prompt = UserDefaults.standard.value(forKey: PermissionKeys.coreMotion.rawValue) as? String
            if prompt == nil {
                // not has been prompted
                UserDefaults.standard.set("Yes", forKey: PermissionKeys.coreMotion.rawValue)
                HyperTrack.requestMotionAuthorization()
                self.initializeTimer()
            } else {
                // already prompted
                checkForMotionPermission()
            }
        } else {
            self.dismissViewController()
        }
    }
    
    @objc private func checkForMotionPermission() {
        HyperTrack.motionAuthorizationStatus(completionHandler: { (authorized) in
            if(authorized){
                self.pollingTimer?.invalidate()
                self.dismissViewController()
            } else {
                self.goToSettings()
            }
        })
    }
    
    private func dismissViewController() {
        self.dismiss(animated: false, completion: {
            self.permissionDelegate?.didFinishedAskingPermissions(currentController: self)
        })
    }
    
    
}
