//
//  BookTripBottomView.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 23/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack

class BookTripBottomView: HTBaseView {
    
    var bookRideClosure: (()->())? = nil
    var pickupClosure: (()->())? = nil
    var dropClosure: (()->())? = nil
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var etaLabel: UILabel!
    
    
    @IBOutlet weak var pickupAddressLabel: UILabel!
    @IBOutlet weak var dropOffAddressLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        self.topCornerRadius = 14
    }
    
    @IBAction func bookRidePressed(_ sender: UIButton) {
        bookRideClosure?()
    }
    
    @IBAction func pickupPressed(_ sender: UIButton) {
        pickupClosure?()
    }
    
    @IBAction func dropPressed(_ sender: UIButton) {
        dropClosure?()
    }
    
}
