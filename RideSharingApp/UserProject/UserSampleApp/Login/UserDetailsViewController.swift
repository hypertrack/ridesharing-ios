//
//  UserDetailsViewController.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 30/04/18.
//  Copyright © 2018 Ashish Asawa. All right s reserved.
//

import UIKit
import MBProgressHUD

class UserDetailsViewController: UIViewController, AlertHandler {

    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    var phoneNumber: String!
    var uid: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        phoneTextField.text = phoneNumber
        phoneTextField.isUserInteractionEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitPressed(_ sender: UIButton) {
        if let name = nameTextField.text, name.count > 0 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            DataService.instance.createUser(uid: uid, name: name, phone: phoneNumber, completionHandler: {[weak self] (isUserCreated, error) in
                self?.view.endEditing(true)
                if let view = self?.view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
                if isUserCreated == true {
                    UserDefaults.standard.set(name, forKey: UserKeys.name.rawValue)
                    UserDefaults.standard.synchronize()
                    let user = User.defaultUser()
                    if let user = user {
                        Router.launchHome(forUser: user)
                    } else {
                        self?.showAlert()
                    }
                } else {
                    self?.showAlert()
                }
            })
        } else {
            let alert = UIAlertController.init(title: "Error", message: "Please Enter name", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
}
