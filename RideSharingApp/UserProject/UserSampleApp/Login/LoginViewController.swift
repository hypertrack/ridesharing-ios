//
//  LoginViewController.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 20/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import MBProgressHUD
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
            let userDetailVC = self.storyboard?.instantiateViewController(withIdentifier: "UserDetailsViewController") as! UserDetailsViewController
            userDetailVC.phoneNumber = phone
            userDetailVC.uid = user.uid
            self.present(userDetailVC, animated: true, completion: nil)
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

}
