//
//  LocationPermissionViewController.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 30/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        guard let urlGeneral = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        UIApplication.shared.open(urlGeneral)
    }
    
    func changeToEnablePermissions(){
        
//        self.requestLocationDescriptionLabel.text = "We need your permissions to capture your activity through the day, and to let you share your live location with your friends when you are on your way."
//
//        self.enableLocationCTAButton.setTitle("Enable Permissions", for: UIControlState.normal)
//        self.enableLocationCTAButton.removeTarget(self, action: #selector(didTapGoToSettings(_:)), for: UIControlEvents.touchUpInside)
//        self.enableLocationCTAButton.addTarget(self, action: #selector(didTapEnableLocationButton(_:)), for: UIControlEvents.touchUpInside)
        
    }
    
    
    @objc private func onForegroundNotification(_ notification: Notification) {
        if (HyperTrack.locationAuthorizationStatus() == .authorizedAlways) {
            changeToEnablePermissions()
            if(HyperTrack.isActivityAvailable()){
                // TODO: How to know if it is not authorized
                HyperTrack.requestMotionAuthorization()
                self.initializeTimer()
            }else{
                self.dismissViewController()
            }
        }
    }
    
    private func initializeTimer() {
        pollingTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self, selector: #selector(checkForMotionPermission),
                                            userInfo: nil, repeats: true)
    }
    
    @objc private func checkForMotionPermission() {
        HyperTrack.motionAuthorizationStatus(completionHandler: { (authorized) in
            if(authorized){
                self.pollingTimer?.invalidate()
                self.dismissViewController()
            }
        })
    }
    
    private func dismissViewController() {
        self.dismiss(animated: false, completion: {
            self.permissionDelegate?.didFinishedAskingPermissions(currentController: self)
        })
    }
    
    
}
