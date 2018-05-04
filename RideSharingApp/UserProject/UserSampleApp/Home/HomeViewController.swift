//
//  HomeViewController.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 20/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import UIKit
import HyperTrack
import CoreLocation
import MBProgressHUD

enum UserState {
    case start
    case bookRide
    case tripTracking
    case undefined
}

class HomeViewController: UIViewController, HTPlaceSelectionDelegate, HTUseCaseNavigationDelegate, BookTripUseCaseProtocol, AlertHandler, TripTrackingUseCaseHandlerDelegate {
    
    var user: User
    let htMapContainer: HTMapContainer = HTMapContainer.init(frame: CGRect.zero)
    var placeSelectionUseCase: HTPlaceSelectionUseCase? = nil
    var bookTripUseCase: BookTripUseCase? = nil
    var tripTrackingHandler: TripTrackingUseCaseHandler? = nil
    var bookTimer = Timer()
    
    var pickupLocation: Location = Location(coordinate: CLLocationCoordinate2D.zero, displayAddress: "")
    var dropLocation:   Location = Location(coordinate: CLLocationCoordinate2D.zero, displayAddress: "")
    
    var isChangingDrop: Bool = true
    
    let defaultCoordinate = CLLocationCoordinate2D.zero
    
    var trip: Trip? = nil
    
    var state: UserState = .undefined
    
    @IBOutlet weak var mapContainerView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("use init() method")
    }
    
    init(withUser user: User) {
        self.user = user
        super.init(nibName: "HomeViewController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // TODO: Permission Handling
        initialSetup()
        // TODO: Put this in a loop for error handling case.
        if let driverId = TripHelper.getCurrentTripDriverId() {
            listenForCurrentActiveTrip(forDriverId: driverId)
        } else if let actionId = TripHelper.getLastTripActionId() {
            let hyperTrackInfo = HyperTrackActionInfo(collectionId: "", pickupActionId: nil, dropActionId: actionId)
            self.setOrderTracking(forHyperTrackInfo: hyperTrackInfo)
        } else {
            self.pickupLocation = Location(coordinate: HyperTrack.getCurrentLocation()?.coordinate ?? CLLocationCoordinate2D.zero, displayAddress: "")
            self.dropSetup()
        }
    }
    
    private func listenForCurrentActiveTrip(forDriverId driverId: String) {
        DataService.instance.listenForTrip(forDriverId: driverId, tripReceived: { [weak self](result) in
            self?.trip = result.trip
            if let trip = result.trip {
                self?.setOrderTracking(forHyperTrackInfo: trip.hyperTrackInfo)
            } else {
                TripHelper.resetCurrentTripDriverId()
                let lastTripActionId = TripHelper.getLastTripActionId()
                let hyperTrackInfo = HyperTrackActionInfo(collectionId: "", pickupActionId: nil, dropActionId: lastTripActionId)
                self?.setOrderTracking(forHyperTrackInfo: hyperTrackInfo)
            }
        })
    }

    private func setOrderTracking(forHyperTrackInfo hyperTrackInfo: HyperTrackActionInfo?) {
        HTProvider.destinationMarkerSize = CGSize(width: 20, height: 20)
        self.state = .tripTracking
        self.placeSelectionUseCase?.mapDelegate?.cleanUp()
        self.bookTripUseCase?.cleanup()
        var actionId: String? = nil
        if let dropActionId = hyperTrackInfo?.dropActionId {
            actionId = dropActionId
        } else if let pickupActionId = hyperTrackInfo?.pickupActionId {
            actionId = pickupActionId
        }
        if let actionId = actionId {
            if tripTrackingHandler?.getCurrentActionId() != actionId {
                tripTrackingHandler?.stopTracking()
                tripTrackingHandler = nil
                tripTrackingHandler = TripTrackingUseCaseHandler(withActionId: actionId, mapContainer: htMapContainer, forTrip: self.trip)
                tripTrackingHandler?.handlerDelgate = self
                self.tripTrackingHandler?.startTracking()
            }
        } else {
            DataService.instance.stopListeningForTrip()
            dropSetup()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func locationAuthorization() {
        
        HyperTrack.requestAlwaysLocationAuthorization(completionHandler: { (completed) in
            // TODO: Handle
            print(completed)
        })
        //TODO: Do we require motion tracking permission here.
        HyperTrack.requestMotionAuthorization()
    }
    
    private func initialSetup() {
        locationAuthorization()
        mapSetup()
    }
    
    func mapSetup() {
        mapContainerView.addSubview(htMapContainer)
        htMapContainer.edges() // this will add the edge to edge autolayout constraints
        htMapContainer.showCurrentLocation = true
        setupMapColorsAndMarkers()
        HTProvider.shouldShowCallouts = true
        //setupMapColorsAndMarkers()
    }
    
    // MARK: Use Case Setup Methods
    
    
    func dropSetup() {
        self.state = .start
        let location = Location(coordinate: HyperTrack.getCurrentLocation()?.coordinate ?? CLLocationCoordinate2D.zero, displayAddress: "")
        showPlaceSelectionUseCase(forLocation: location, toHideBack: true, placeHolderText: "Enter Your Destination", toShowCurrentLocation: false)
        HyperTrack.getCurrentLocation { [weak self] (location, error) in
            if let location = location {
                let loc = Location(coordinate: location.coordinate, displayAddress: nil)
                self?.fetchNearbyCars(forLocation: loc)
            }
        }
    }
    
    func showPlaceSelectionUseCase(forLocation location: Location, toHideBack: Bool, placeHolderText: String, toShowCurrentLocation: Bool) {
        self.bookTripUseCase?.cleanup()
        let useCase = HTPlaceSelectionUseCase(coordinate: location.coordinate)
        useCase.delegate = self
        useCase.navigationDelegate = self
        useCase.isPrimaryActionHidden = toHideBack
        useCase.searchBarPlaceHolderText = placeHolderText
        useCase.enableCurrentLocationSelection = toShowCurrentLocation
        htMapContainer.setBottomViewWithUseCase(useCase)
        
        self.placeSelectionUseCase = useCase
    }
    
    func showBookTripUseCase(forPickup pickup: Location, forDrop drop: Location) {
        HTProvider.destinationMarkerSize = CGSize(width: 20, height: 20)
        self.state = .bookRide
        self.placeSelectionUseCase?.mapDelegate?.cleanUp()
        self.placeSelectionUseCase?.isPrimaryActionHidden = true
        self.placeSelectionUseCase = nil
        let btUseCase = BookTripUseCase.init(pickupLocation: pickup, dropLocation: drop)
        btUseCase.useCaseDelegate = self
        self.bookTripUseCase = btUseCase
        htMapContainer.setBottomViewWithUseCase(btUseCase)
    }
    
    // MARK: Mock Cars Methods
    private func fetchNearbyCars(forLocation location: Location) {
        /*
         String url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=" + <your_latitude>+ "," + <your_longitude>
         + "&radius=500&type=restaurant&key=<your_google_maps_key>";
         */
        let coordinates = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinates)&radius=500&type=restaurant&key=AIzaSyAfV3N5sQtp3wUS9kYq0YD54ZyL-_L81IE"
        let url = URL.init(string: urlString)
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) {[weak self] (data, response, error) in
            if self?.state != UserState.start {
                return
            }
            if let _ = error{
                //INTERNET ERROR
                DispatchQueue.main.async(execute: { () -> Void in
                    //DO Nothing, unable to fetch route
                })
            } else {
                guard let httpResponse:HTTPURLResponse = response as? HTTPURLResponse,  let data:Data = data, let result:NSDictionary = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())) as? NSDictionary else{
                    // Do Nothing, unable to parse JSON
                    return
                }
                if httpResponse.statusCode == 200 {
                    print(result)
                    //TODO: Data Parsing and showing it in map.
                    self?.showCars(forResult: result)
                }
            }
        }
        task.resume()
        
    }
    
    private func showCars(forResult result: NSDictionary) {
        if let places = result.value(forKey: "results") as? [Dictionary<String, AnyObject>] {
            var annotationData: [HTAnnotationData] = []
            var coordinates:[CLLocationCoordinate2D] = []
            for (index, place) in places.enumerated() {
                if index == 5 {
                    break
                }
                if let location = place["geometry"]?["location"] as? Dictionary<String, Double> {
                    if let lat = location["lat"], let lng = location["lng"] {
                        let annotation = HTAnnotationData(id: "car\(index)", coordinate: CLLocationCoordinate2DMake(lat, lng), metaData: HTAnnotationData.MetaData(isPulsating: false, type: HTAnnotationType.destination, actionInfo: nil), callout: nil)
                        coordinates.append(CLLocationCoordinate2DMake(lat, lng))
                        annotationData.append(annotation)
                    }
                }
            }
            if self.state == .start {
                DispatchQueue.main.async {
                    self.htMapContainer.cleanUp()
                    HTProvider.destinationMarkerSize = CGSize(width: 65, height: 65)
                    //HTProvider.userMarkerSize = CGSize(width: 65, height: 65)
                    
                    self.htMapContainer.showCurrentLocation = true
                    self.htMapContainer.addAnnotations(annotationData)
                    self.htMapContainer.showCoordinates(coordinates)
                }
            }
        }
    }
    
    // MARK: Place Delegate
    func expectedPlaceSet(_ data: HTPlace) {
        if isChangingDrop == true {
            // drop is changed
            if let lat = data.location?.coordinates[1], let longitude = data.location?.coordinates[0] {
                let drop = Location.init(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: longitude), displayAddress: data.address)
                dropLocation = drop
            }
        } else {
            // pickup is changed
            if let lat = data.location?.coordinates[1], let longitude = data.location?.coordinates[0] {
                let pickup = Location.init(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: longitude), displayAddress: data.address)
                pickupLocation = pickup
            }
        }
        showBookTripUseCase(forPickup: pickupLocation, forDrop: dropLocation)
    }
    
    func cancelClicked() {
        
    }
    
    // MARK: Navigation Delegate
    func backClicked() {
        if self.bookTripUseCase != nil {
            self.bookTripUseCase?.showMapPolyline()
            htMapContainer.setBottomViewWithUseCase(self.bookTripUseCase!)
        }
    }
    
    func bookTripPressed(forPickup pickup: Location, drop: Location) {
        pickupLocation = pickup
        dropLocation   = drop
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if isOkToBook() == false {
            MBProgressHUD.hide(for: view, animated: true)
            return
        }
        bookTimer.invalidate()
        let timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(HomeViewController.timerReached), userInfo: nil, repeats: false)
        bookTimer = timer
        DataService.instance.findDriver(forPickup: pickup, drop: drop, user: user) { [weak self](result) in
            self?.bookTimer.invalidate()
            if let view = self?.view {
                MBProgressHUD.hide(for: view, animated: true)
            }
            if let driverId = result.driverId, let _ = result.trip?.hyperTrackInfo?.collectionId, let _ = result.trip?.pickup {
                TripHelper.saveCurrentTripDriverId(driverId: driverId)
                self?.setOrderTracking(forHyperTrackInfo: result.trip?.hyperTrackInfo)
                self?.listenForCurrentActiveTrip(forDriverId: driverId)
            } else {
                self?.showBookFailAlert()
            }
        }
    }
    
    @objc private func timerReached() {
        MBProgressHUD.hide(for: self.view, animated: true)
        bookTimer.invalidate()
        DataService.instance.stopListeningForTrip()
        showBookFailAlert()
    }
    
    private func showBookFailAlert() {
        let alert = UIAlertController.init(title: "Error", message: "Sorry Cant find the driver. Please try again later", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: Tracking Use Case Delegate Methods
    
    func bookAnotherRide() {
        self.tripTrackingHandler?.stopTracking()
        user.endTrip()
        TripHelper.resetCurrentTripDriverId()
        TripHelper.resetLastTripActionId()
        dropSetup()
    }
    
    func pickupChangedPressed(forPickup pickup: Location) {
        isChangingDrop = false
        showPlaceSelectionUseCase(forLocation: pickup, toHideBack: false, placeHolderText: "Enter Your Pickup", toShowCurrentLocation: true)
    }
    
    func dropChangedPressed(forDropup dropup: Location) {
        isChangingDrop = true
        showPlaceSelectionUseCase(forLocation: dropup, toHideBack: false, placeHolderText: "Enter Your Destination", toShowCurrentLocation: false)
    }
    
    func shareRide() {
        //TODO: Share Ride functionality
    }
    
    // MARK: Validity Check Methods
    func isOkToBook() -> Bool {
        //TODO: Test it properly
        var isOk = true
        var message = ""
        if pickupLocation.coordinate.latitude == dropLocation.coordinate.latitude,
            pickupLocation.coordinate.longitude == dropLocation.coordinate.longitude {
            isOk = false
            message = "Pickup and drop points are same"
        } else if pickupLocation.coordinate.latitude == defaultCoordinate.latitude,
                  pickupLocation.coordinate.longitude == defaultCoordinate.longitude  {
            isOk = false
            message = "Invalid Pickup point"
        } else if dropLocation.coordinate.latitude == defaultCoordinate.latitude,
                  dropLocation.coordinate.longitude == defaultCoordinate.longitude  {
            isOk = false
            message = "Invalid Drop point"
        }
        
        
        if isOk == false {
            let alert = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
            let action = UIAlertAction.init(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
        return isOk
    }
    
}
