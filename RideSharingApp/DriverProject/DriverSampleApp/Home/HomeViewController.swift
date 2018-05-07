//
//  HomeViewController.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 11/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack
import MapKit
import MBProgressHUD

enum CurrentUseCase {
    case lookingForRide
    case onRide
    case none
}

class HomeViewController: UIViewController, AcceptRideProtocol, TripTrackingDelegate, AlertHandler, LocationPermissionProtocol {
    
    @IBOutlet weak var mapContainerView: UIView!
    
    var driver:         Driver
    let htMapContainer: HTMapContainer = HTMapContainer.init(frame: CGRect.zero)
    var acceptRideVC:   AcceptRideViewController? = nil
    var trip:           Trip? = nil
    var currentUseCase: CurrentUseCase = .none
    var lookingForRideUseCase: LookingForRideUseCase? = nil
    var tripTrackingHandler: TripTrackingUseCaseHandler? = nil
    var locationPermissionVC: LocationPermissionViewController? = nil
    var isFirstTimeSetup = false
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("use init() method")
    }
    
    init(withDriver driver: Driver) {
        self.driver = driver
        super.init(nibName: "HomeViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //initialSetup()
        //testRemoveAllActions()
        mapSetup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initialSetup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //TODO: Separate view controller, for failure handling
    private func locationAuthorization() {
        
        if (!HyperTrack.locationServicesEnabled()) {
            
            HyperTrack.requestLocationServices()
            return
        }
        // Check for Location Authorization Status (Always by default)
        if (HyperTrack.locationAuthorizationStatus() != .authorizedAlways) {
            
        } else if (HyperTrack.locationAuthorizationStatus() == .authorizedAlways) {
            if(HyperTrack.isActivityAvailable()){
                HyperTrack.requestMotionAuthorization()
            }else{
                
            }
        }
        
        if HyperTrack.locationServicesEnabled(), HyperTrack.locationAuthorizationStatus() == .authorizedAlways {
            
        }
        HyperTrack.requestAlwaysLocationAuthorization(completionHandler: { (completed) in
            // TODO: Handle
            print(completed)
        })
        HyperTrack.requestMotionAuthorization()
    }
    
    private func initialSetup() {
        var toShowLocationPermissionScreen = false
        if (!HyperTrack.locationServicesEnabled()) {
            // OS Level Location is Disabled
            toShowLocationPermissionScreen = true
        } else if (HyperTrack.locationAuthorizationStatus() != .authorizedAlways) {
            // APP Specific Check
            toShowLocationPermissionScreen = true
        }
        if toShowLocationPermissionScreen == true {
            launchLocationPermissionScreen()
        } else {
            // Motion Check
            if(HyperTrack.isActivityAvailable()) {
                // Motion Data Available on device
                HyperTrack.motionAuthorizationStatus(completionHandler: { (authorized) in
                    if (!authorized) {
                        self.launchLocationPermissionScreen()
                    } else {
                        self.firstTimeSetup()
                    }
                })
            } else {
                // Motion Data not available
                firstTimeSetup()
            }
        }
    }
    
    private func launchLocationPermissionScreen() {
        //TODO: Handling if any other screen is presented above it
        let permissionVC = Router.launchLocationPermission(inParent: self)
        permissionVC.permissionDelegate = self
    }
    
    func firstTimeSetup() {
        if isFirstTimeSetup == false {
            isFirstTimeSetup = true
            // TODO: Data from local cache
            DataService.instance.fetchDriverDetails(forDriverId: driver.firebaseId) {[weak self] (snapshot) in
                self?.driver.updateDriver(fromSnapshot: snapshot)
                self?.listenForTrip()
            }
        }
        
    }
    
    func mapSetup() {
        mapContainerView.addSubview(htMapContainer)
        htMapContainer.edges() // this will add the edge to edge autolayout constraints
        htMapContainer.showCurrentLocation = true
        setupMapColorsAndMarkers()
        HTProvider.shouldShowCallouts = true
    }
    
    func setupInitialUseCase() {
        if self.lookingForRideUseCase == nil {
        // 1. Create Use case
            let useCase = LookingForRideUseCase.init(withDriver: driver)
            // 2. Add to bottom view of map to show UI
            lookingForRideUseCase = useCase
        }
        htMapContainer.setBottomViewWithUseCase(lookingForRideUseCase!)
        self.currentUseCase = .lookingForRide
        //htMapContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 20).isActive = true
    }
    
    func listenForTrip() {
        DataService.instance.listenForTrip(forDriver: driver) {[unowned self](trip) in
            //TODO: Weak Self
            //TODO: Improve logic
            self.trip = trip
            if let hypertrackInfo = self.trip?.hyperTrackInfo {
                if self.currentUseCase != .onRide {
                    self.createOrderTrackingUseCase(forHyperTrackInfo: hypertrackInfo)
                }
                self.stopListeningForTrip()
                self.currentUseCase = .onRide
                return
            } else {
                // may be on trip, and then trip get cancelled from firebase
                self.tripTrackingHandler?.stopTracking(isMapCleanup: true)
                self.tripTrackingHandler = nil
                self.setupInitialUseCase()
            }
            if let trip = trip {
                // show Accept Ride
                // if already show update it with trip information
                if self.acceptRideVC == nil {
                    self.acceptRideVC = Router.launchAcceptRide(forTrip: trip, presentOverViewController: self)
                } else {
                    self.acceptRideVC?.updateTrip(trip: trip)
                }
                self.acceptRideVC?.delegate = self
            } else {
                // if its shown, then dismiss it
                self.acceptRideVC?.dismiss(animated: true, completion: nil)
                self.acceptRideVC = nil
                self.setupInitialUseCase()
            }
        }
    }
    
    func stopListeningForTrip() {
        DataService.instance.stopListeningForTrip()
    }
    
    // MARK: Accept Ride Protocol
    func rideDidAccepted(forHtCollectionId htCollectionId: String, htActionId: String) {
        self.dismiss(animated: true, completion: nil)
        self.acceptRideVC = nil
        self.lookingForRideUseCase?.cleanup()
//        self.trip?.updateDriverInfo(forDriverId: driver.firebaseId, forName: driver.name ?? "", forCarDetails: driver.carDetails ?? "")
        self.trip?.updateAcceptTrip(forCollectionId: htCollectionId, pickupActionId: htActionId, driverId: driver.firebaseId)
        if let userId = self.trip?.userDetails.firebaseId {
            DataService.instance.updateTripCollectionId(forUserId: userId, collectionId: htCollectionId)
        }
        if let hypertrackInfo = trip?.hyperTrackInfo {
            createOrderTrackingUseCase(forHyperTrackInfo: hypertrackInfo)
        }
        stopListeningForTrip()
    }
    
    func rideDidCancelled() {
        self.acceptRideVC?.dismiss(animated: true, completion: {
            self.acceptRideVC = nil
        })
    }
    
    private func createOrderTrackingUseCase(forHyperTrackInfo hyperTrackInfo: HyperTrackActionInfo) {
        guard let trip = trip else {
            return
        }
        var actionId: String? = nil
        if let dropActionId = hyperTrackInfo.dropActionId {
            actionId = dropActionId
        } else if let pickupActionId = hyperTrackInfo.pickupActionId {
            actionId = pickupActionId
        }
        if let actionId = actionId {
            if tripTrackingHandler?.getCurrentActionId() != actionId {
                tripTrackingHandler?.stopTracking(isMapCleanup: true)
                tripTrackingHandler = nil
                tripTrackingHandler = TripTrackingUseCaseHandler(withActionId: actionId, trip: trip, mapContainer: htMapContainer)
                tripTrackingHandler?.handlerDelegate = self
                tripTrackingHandler?.startTracking()
            }
        }
    }
    
//    private func createOrderTrackingUseCase(forCollectionId collectionId: String) {
//        guard let trip = trip else {
//            return
//        }
//        if tripTrackingHandler == nil {
//            tripTrackingHandler = TripTrackingUseCaseHandler(withActionId: collectionId, trip: trip, mapContainer: htMapContainer)
//            tripTrackingHandler?.handlerDelegate = self
//        }
//        tripTrackingHandler?.startTracking()
//    }
    
    private func testRemoveAllActions() {
        HyperTrack.completeAction("86a1b3a8-0828-4b23-ad2e-ec7731805add")
    }
    
    func startTripClicked() {
        // create a drop action
        guard let trip = trip, let collectionId = trip.hyperTrackInfo?.collectionId, let pickupActionId = trip.hyperTrackInfo?.pickupActionId else {
            //TODO: Error case handling
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let worker = TripWorker.init()
        worker.startTrip(forCollectionId: collectionId, trip: trip, pickupActionId: pickupActionId, successClosure: { (action) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.trip?.updateStartTrip(forDropActionId: action.id, driverId: self.driver.firebaseId)
            if let hypertrackInfo = self.trip?.hyperTrackInfo {
                self.createOrderTrackingUseCase(forHyperTrackInfo: hypertrackInfo)
            }
        }) { (error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.showAlert(error: error)
        }
    }
    
    func endTripClicked() {
        //let dropActionId = trip.hyperTrackInfo?.dropActionId
        guard let trip = trip, let collectionId = trip.hyperTrackInfo?.collectionId  else {
            //TODO: Error case handling
            return
        }
        //self.tripUseCaseHandler?.stopTracking(isMapCleanup: false)
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let worker = TripWorker.init()
        worker.endTrip(forCollectionId: collectionId, trip: trip, dropActionId: trip.hyperTrackInfo?.dropActionId) { [weak self](result) in
            if let view = self?.view {
                MBProgressHUD.hide(for: view, animated: true)
            }
            if result.success == true {
                // YAY Trip Completed
                self?.driver.updateDriver(isOnRide: false)
                if let hyperTrackInfo = self?.trip?.hyperTrackInfo {
                    self?.tripTrackingHandler?.stopTracking(isMapCleanup: true)
                    self?.tripTrackingHandler = nil
                    self?.createOrderTrackingUseCase(forHyperTrackInfo: hyperTrackInfo)
                }
                //self?.tripUseCaseHandler?.tripCompleted()
            } else {
                self?.showAlert(error: result.error)
            }
        }
    }
    
    func findNewTripClicked() {
        self.driver.updateDriver(isOnRide: false)
        if let trip = self.trip {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            DataService.instance.delete(trip: trip, forDriver: driver, completionHandler: { [weak self](success, error) in
                if let view = self?.view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
                if success == true {
                    self?.trip = nil
                    self?.tripTrackingHandler?.stopTracking(isMapCleanup: true)
                    self?.tripTrackingHandler = nil
                    self?.setupInitialUseCase()
                    self?.listenForTrip()
                } else {
                    self?.showAlert()
                }
            })
        } else {
            self.listenForTrip()
        }
    }
    
    func userCallPressed() {
        if let number = self.trip?.userDetails.phone {
                let phoneNumber: String = "telprompt://".appending(number)
                let url = URL.init(string: phoneNumber)
                UIApplication.shared.open(url!, options: [:], completionHandler: { (success) in
            })
        }
    }
    
    func directionPressedPickup() {
        if let location = self.trip?.pickup {
            launchMap(forDestination: location)
        }
    }
    
    func directionPressedDrop() {
        if let location = self.trip?.drop {
            launchMap(forDestination: location)
        }
    }
    
    private func launchMap(forDestination destination: Location) {
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
            let urlString = "http://maps.google.com/?daddr=\(destination.coordinate.latitude),\(destination.coordinate.longitude)&directionsmode=driving"
            // use bellow line for specific source location
            //let urlString = "http://maps.google.com/?saddr=\(sourceLocation.latitude),\(sourceLocation.longitude)&daddr=\(destinationLocation.latitude),\(destinationLocation.longitude)&directionsmode=driving"
            UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: nil)
            
        } else {
            //let urlString = "http://maps.apple.com/maps?saddr=\(sourceLocation.latitude),\(sourceLocation.longitude)&daddr=\(destinationLocation.latitude),\(destinationLocation.longitude)&dirflg=d"
            let urlString = "http://maps.apple.com/maps?daddr=\(destination.coordinate.latitude),\(destination.coordinate.longitude)&dirflg=d"
            UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: nil)
        }
    }
    
    
    // MARK: Location Permission Delegate
    func didFinishedAskingPermissions(currentController: UIViewController) {
        firstTimeSetup()
    }
    
    // MARK: Trip Tracking Delegate Methods
    
    
}

