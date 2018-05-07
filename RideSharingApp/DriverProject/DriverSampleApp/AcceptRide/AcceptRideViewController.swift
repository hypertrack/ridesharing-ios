//
//  AcceptRideViewController.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 12/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol AcceptRideProtocol: class {
    func rideDidAccepted(forHtCollectionId htCollectionId: String, htActionId: String)
    func rideDidCancelled()
}

class AcceptRideViewController: UIViewController, AlertHandler {
    
    @IBOutlet weak var outerCircleView: UIView!
    @IBOutlet weak var innerCircleView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var mapMarkerImageView: UIImageView!
    
    var trip: Trip
    
    weak var delegate: AcceptRideProtocol? = nil
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("use init() method")
    }
    
    init(withTrip trip: Trip) {
        self.trip = trip
        super.init(nibName: "AcceptRideViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        initialSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setMapImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        outerCircleSetup()
        innerCircleSetup()
        mapImageViewSetup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initialSetup() {
        self.view.backgroundColor = UIColor(red:0.93, green:0.95, blue:0.97, alpha:1)
        updateData()
    }
    
    private func outerCircleSetup() {
        setupCircleView(circleView: outerCircleView)
    }
    
    private func innerCircleSetup() {
        setupCircleView(circleView: innerCircleView)
    }
    
    private func setupCircleView(circleView: UIView) {
        circleView.layer.borderWidth = 4
        circleView.layer.borderColor = UIColor.brandColor.cgColor
        circleView.layer.cornerRadius = circleView.frame.size.width / 2.0
    }
    
    private func mapImageViewSetup() {
        mapImageView.layer.cornerRadius = mapImageView.frame.size.width / 2.0
    }
    
    private func updateData() {
        self.addressLabel.text = trip.pickup.displayAddress ?? ""
        self.nameLabel.text = trip.userDetails.name
        //TODO: Rating, Image Integration
        self.ratingLabel.text = "5 ☆ ☆ ☆ ☆ ☆"
    }
    
    private func setMapImage() {
        if self.mapMarkerImageView.isHidden == false {
            return
        }
        //TODO: Code Refactoring.
        //&key=YOUR_API_KEY
        let latitudeString = String(trip.pickup.coordinate.latitude)
        let longitudeString = String(trip.pickup.coordinate.longitude)
        let imageUrl = "https://maps.googleapis.com/maps/api/staticmap?center=\(latitudeString),\(longitudeString)&zoom=18&size=200x200&scale=2&maptype=roadmap"
        //TODO: add map marker logic
        var image: UIImage?
        if let url = URL.init(string: imageUrl) {
            //All network operations has to run on different thread(not on main thread).
            DispatchQueue.global(qos: .userInitiated).async {
                let imageData = NSData(contentsOf: url)
                //All UI operations has to run on main thread.
                DispatchQueue.main.async {
                    if imageData != nil {
                        image = UIImage(data: imageData as! Data)
                        self.mapImageView.image = image
                        self.mapMarkerImageView.isHidden = false
                        //self.mapImageView.sizeToFit()
                    } else {
                        image = nil
                    }
                }
            }
        }

    }
    
    // MARK: Public API Methods
    func updateTrip(trip: Trip) {
        //TODO: handle trip update situation
    }
    
    // MARK: Action Methods
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        //TODO: Firebase call to not accept the ride.
        self.delegate?.rideDidCancelled()
    }
    
    @IBAction func acceptRide(_ sender: UIButton) {
        //TODO: Accept Ride Worker
        let worker = AcceptRiderWorker.init()
        MBProgressHUD.showAdded(to: self.view, animated: true)
        worker.acceptRide(forTrip: trip, successClosure: { (success) in
            MBProgressHUD.hide(for: self.view, animated: true)
            //TODO: Add Hyper Track User Id
            self.delegate?.rideDidAccepted(forHtCollectionId: success.collectionId, htActionId: success.actionId)
        }) { (error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.showAlert(error: error)
        }
    }
}
