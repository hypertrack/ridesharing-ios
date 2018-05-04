//
//  LoginViewController.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 11/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebasePhoneAuthUI

class LoginViewController: UIViewController, FUIAuthDelegate, AlertHandler {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        FUIAuth.defaultAuthUI()?.delegate = self
        let phoneProvider = FUIPhoneAuth.init(authUI: FUIAuth.defaultAuthUI()!)
        FUIAuth.defaultAuthUI()?.providers = [phoneProvider]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func loginPressed(_ sender: UIButton) {
        let phoneProvider = FUIAuth.defaultAuthUI()?.providers.first as! FUIPhoneAuth
        phoneProvider.signIn(withPresenting: self, phoneNumber: nil)
    }
    
    // MARK: FIUIAuthDelegate Method

    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if error == nil, let user = authDataResult?.user, let phone = user.phoneNumber {
            //TODO: Router class
            let driverDetailsVC = self.storyboard?.instantiateViewController(withIdentifier: "DriverDetailsViewController") as! DriverDetailsViewController
            driverDetailsVC.phoneNumber = phone
            driverDetailsVC.uid = user.uid
            self.present(driverDetailsVC, animated: true, completion: nil)
            //TODO: Show UI blocker
        } else {
            if let error = error {
                let code = (error as NSError).code
                switch code {
                case Int(FUIAuthErrorCode.userCancelledSignIn.rawValue):
                    print("User cancelled sign-in");
                    break
                default:
                    showError()
                }
            } else {
                showError()
            }
        }
    }
    
    private func showError() {
        // show error
        showAlert()
    }
    
    private func startActivityIndicator() {
        activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
    }
    
    private func stopActivityIndicator() {
        activityIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
    }
    
}
