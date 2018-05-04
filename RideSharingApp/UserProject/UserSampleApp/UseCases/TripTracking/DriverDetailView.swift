//
//  DriverDetailView.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 29/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack

class DriverDetailView: HTBaseView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override func awakeFromNib() {
        super.awakeFromNib()
        self.topCornerRadius = 14
        //TODO: Call button functionality.
        //TODO: Color related changes
        //UIColor(red:0.44, green:0.44, blue:0.44, alpha:1)
    }
    
}
