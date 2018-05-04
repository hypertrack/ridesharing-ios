//
//  TripSummaryView.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 25/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack



class TripSummaryView: UIView {
    
    @IBOutlet weak var containerView: HTBaseView!
    
    @IBOutlet weak var priceTitleLabel: UILabel!
    @IBOutlet weak var priceValueLabel: UILabel!
    
    @IBOutlet weak var distanceTitleLabel: UILabel!
    @IBOutlet weak var distanceValueLabel: UILabel!
    
    @IBOutlet weak var rideTimeTitleLabel: UILabel!
    @IBOutlet weak var rideTimeValueLabel: UILabel!
    
    
    @IBOutlet weak var categoryTitleLabel: UILabel!
    @IBOutlet weak var categoryValueLabel: UILabel!
    
    
    @IBOutlet weak var nameTitleLabel: UILabel!
    @IBOutlet weak var nameValueLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.topCornerRadius = 14
        //TODO: Font and color changes
        
    }
    
    func feedData(withAction action: HTAction?, driverName: String) {
        nameValueLabel.text = driverName
        if let action = action {
            let distanceInMeters = Double(action.distance)
            let distanceInMiles  = distanceInMeters/1609.344
            distanceValueLabel.text = String.init(format: "%.1f", distanceInMiles)
            priceValueLabel.text = priceString(fromDistanceValue: Double(action.distance))
            if let duration = action.duration {
                //TODO: Convert it in to time
                let minutes = Int(floor(duration/60))
                rideTimeValueLabel.text = "\(minutes) mins"
                
            } else {
                rideTimeValueLabel.text = ""
            }
        } else {
            distanceValueLabel.text = ""
            priceValueLabel.text = ""
            rideTimeValueLabel.text = ""
        }
    }
    
    //TODO: Common Place
    private func priceString(fromDistanceValue distanceValue: Double) -> String {
        //let locale = NSLocale.current
        let symbol = "$"
            //locale.currencySymbol ?? ""
        
        let distanceInMiles = distanceValue/1609.344
        var price = distanceInMiles
        price = price * 1
        let priceString = symbol + " " + String.init(format: "%.0f", price)
        return priceString
    }
    
}
