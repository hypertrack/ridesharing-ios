//
//  DriverDetailsViewController.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 01/05/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import MBProgressHUD

class DriverDetailsViewController: UIViewController, AlertHandler {

    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var carDetailsTextField: UITextField!
    
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
        if let name = nameTextField.text, name.count > 0, let carDetails = carDetailsTextField.text, carDetails.count > 0 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            DataService.instance.createDriver(uid: uid, name: name, phone: phoneNumber, carDetails: carDetails, completionHandler: {[weak self] (isUserCreated, error) in
                self?.view.endEditing(true)
                if let view = self?.view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
                if isUserCreated == true {
                    UserDefaults.standard.set(name, forKey: DriverKeys.name.rawValue)
                    UserDefaults.standard.set(carDetails, forKey: DriverKeys.carDetails.rawValue)
                    UserDefaults.standard.synchronize()
                    if let driver = Driver.defaultDriver() {
                        Router.launchHome(forDriver: driver)
                    } else {
                        self?.showAlert()
                    }
                } else {
                    self?.showAlert()
                }
            })
        } else {
            let alert = UIAlertController.init(title: "Error", message: "Please Enter details", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }

}
