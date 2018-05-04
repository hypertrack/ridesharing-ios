//
//  UIViewController+Alert.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 16/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import UIKit
import HyperTrack

//TODO: Constants Enum
let genericErrorMessage = "Oops something went wrong. Please try again later"

protocol AlertHandler {
    func showAlert(error: NSError)
    func showAlert(error: HTError?)
}

extension AlertHandler where Self: UIViewController {
    
    func showAlert(error: NSError = NSError.defaultError()) {
        let alertVC = UIAlertController.init(title: error.errorTitle(), message: error.errorMessage(), preferredStyle: .alert)
        let action = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func showAlert(error: HTError?) {
        let message = error?.errorMessage ?? genericErrorMessage
        let alertVC = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
        alertVC.addAction(action)
        self.present(alertVC, animated: true, completion: nil)
    }
    
}

extension NSError {
    static func defaultError() -> NSError {
        let error = NSError.init(domain: "", code: 5000, userInfo: ["title": "Error", "message" : "Oops something went wrong. Please try again later"])
        return error
    }
    
    func errorTitle() -> String {
        return self.userInfo["title"] as? String ?? "Error"
    }
    
    func errorMessage() -> String {
        return self.userInfo["message"] as? String ?? "Oops something went wrong. Please try again later"
    }
    
}
