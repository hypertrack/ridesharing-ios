//
//  HomeViewController+HTExtension.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 13/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import HyperTrack

extension HomeViewController {
    func setupMapColorsAndMarkers() {
        HTProvider.mapCustomizationDelegate = self
        HTProvider.style.colors = self
    }
}

extension HomeViewController: HTMapCustomizationDelegate {
    func userMarkerImage(annotationType: HTAnnotationType) -> UIImage? {
//        if annotationType == .user {
//            return UIImage(named: "ic_pickup_marker")
//        } else if annotationType == .destination {
//            return UIImage(named: "ic_destination_marker")
//        }
        return UIImage(named: "ic_drive")
    }
    
    func expectedPlaceMarkerImage() -> UIImage? {
        return UIImage(named: "ic_destination_marker")
    }
}

extension HomeViewController: HTColorProviderProtocol {
    var `default`: UIColor {
        return UIColor.black
    }
    var text: UIColor {
        return UIColor.white
    }
    var primary: UIColor {
        return UIColor(red: 37.0 / 255.0, green: 13.0 / 255.0, blue: 71.0 / 255.0, alpha: 1.0)
    }
    var secondary: UIColor {
        return UIColor(red: 71.0 / 255.0, green: 85.0 / 255.0, blue: 108.0 / 255.0, alpha: 1.0)
    }
    var gray: UIColor {
        return UIColor(red: 171.0 / 255.0, green: 180.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
    }
    var error: UIColor {
        return UIColor(red: 252.0 / 255.0, green: 95.0 / 255.0, blue: 91.0 / 255.0, alpha: 1.0)
    }
    var brand: UIColor {
        return UIColor(red:0.31, green:0.89, blue:0.76, alpha:1)
    }
    var positive: UIColor {
        return UIColor(red: 0.0, green: 201.0 / 255.0, blue: 75.0 / 255.0, alpha: 1.0)
    }
    var dropShadow: UIColor {
        return UIColor(red: 134.0 / 255.0 , green: 134.0 / 255.0, blue: 134.0 / 255.0, alpha: 0.5)
    }
    var errorDark: UIColor {
        return UIColor(red: (202/255), green: (77/255), blue: (74/255), alpha: 1)
    }
    var lightGray: UIColor {
        return UIColor(red: (230/255), green: (230/255), blue: (230/255), alpha: 1)
    }
}

