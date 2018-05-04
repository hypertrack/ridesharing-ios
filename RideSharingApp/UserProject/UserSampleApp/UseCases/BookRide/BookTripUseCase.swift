//
//  BookTripUseCase.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 23/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import HyperTrack
import CoreLocation


protocol BookTripUseCaseProtocol: class {
    func bookTripPressed(forPickup pickup: Location, drop: Location)
    func pickupChangedPressed(forPickup pickup: Location)
    func dropChangedPressed(forDropup dropup: Location)
}

class BookTripUseCase: HTBaseUseCase, HTMapViewUseCase {
    
    var polylineData: [HTPolylineData]? = nil
    var coordinates: [CLLocationCoordinate2D]? = nil
    var pickupAddress: String? = nil
    
    weak var useCaseDelegate: BookTripUseCaseProtocol? = nil
    
    func update() {
        
    }
    
    required init(mapDelegate: HTMapUseCaseDelegate?) {
        
    }
    
    weak public var mapDelegate: HTMapUseCaseDelegate? {
        didSet {
            mapDelegate?.showCurrentLocation = false
            mapDelegate?.setBottomView(bookTripView)
            
//            if let polylineData = polylineData {
//                mapDelegate?.addPolyline(polylineData)
//            }
        }
    }
    
    fileprivate var bookTripView: BookTripBottomView!
    
    func cleanup() {
        mapDelegate?.cleanUp()
    }
    
    // required when pickup/ drop is called and back is pressed
    func showMapPolyline() {
        self.mapDelegate?.cleanUp()
        self.mapDelegate?.showCurrentLocation = false
        guard let coordinates = self.coordinates else {
            return
        }
        self.mapDelegate?.addPolyline([HTPolylineData(id: "abcd", type: .filled, coordinates: coordinates)])
        var annotationData: [HTAnnotationData] = []
        if let coordinate = coordinates.first {
            //TODO: Call out information
            let annotation = HTAnnotationData(id: "start", coordinate: coordinate, metaData: HTAnnotationData.MetaData(isPulsating: false, type: HTAnnotationType.user, actionInfo: nil), callout: nil)
            annotationData.append(annotation)
        }
        if let coordinate = coordinates.last {
            let annotation = HTAnnotationData(id: "expected", coordinate: coordinate, metaData: HTAnnotationData.MetaData(isPulsating: false, type: HTAnnotationType.destination, actionInfo: nil), callout: nil)
            annotationData.append(annotation)
        }
        self.mapDelegate?.addAnnotations(annotationData)
        self.mapDelegate?.showCoordinates(coordinates)
        self.mapDelegate?.showCurrentLocation = false
    }
    
    init(pickupLocation: Location, dropLocation: Location) {
        super.init()
        let view = Bundle.main.loadNibNamed("BookTripBottomView", owner: self, options: nil)?.first as! BookTripBottomView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.pickupAddressLabel.text = pickupLocation.displayAddress ?? "Current Location"
        view.dropOffAddressLabel.text = dropLocation.displayAddress ?? ""
        view.bookRideClosure = { [weak self] in
            let pickup = Location.init(coordinate: pickupLocation.coordinate, displayAddress: self?.pickupAddress)
            self?.useCaseDelegate?.bookTripPressed(forPickup: pickup, drop: dropLocation)
        }
        view.pickupClosure = { [weak self] in
            let pickup = Location.init(coordinate: pickupLocation.coordinate, displayAddress: self?.pickupAddress)
            self?.useCaseDelegate?.pickupChangedPressed(forPickup: pickup)
        }
        view.dropClosure = { [weak self] in
            self?.useCaseDelegate?.dropChangedPressed(forDropup: dropLocation)
        }
        
        view.priceLabel.text = ""
        view.etaLabel.text = ""
        // no need to add constraints, set bottom view, will take care of it.
        self.fetchRoute(fromPickup: pickupLocation, toDrop: dropLocation)
        self.fetchDistance(fromPickup: pickupLocation, toDrop: dropLocation)
        bookTripView = view
    }
    
    private func fetchDistance(fromPickup pickup: Location, toDrop drop: Location) {
        let origin = "\(pickup.coordinate.latitude),\(pickup.coordinate.longitude)"
        let destination = "\(drop.coordinate.latitude),\(drop.coordinate.longitude)"
        let urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(origin)&destinations=\(destination)"
        let url = URL.init(string: urlString)
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) {[weak self] (data, response, error) in
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
                    DispatchQueue.main.async {
                        let originAddresses = result["origin_addresses"] as? Array<String>
                        let originAddress   = originAddresses?.first
                        self?.pickupAddress       = originAddress
                        self?.bookTripView.pickupAddressLabel.text = originAddress ?? "Current Location"
                        if let rows = result.value(forKey: "rows") as? Array<Dictionary<String, AnyObject>> {
                            let first = rows.first
                            if let elements = first?["elements"] as? Array<Dictionary<String, AnyObject>> {
                                let firstElement = elements.first
                                let distance = firstElement?["distance"] as? Dictionary<String, AnyObject>
                                let duration = firstElement?["duration"] as? Dictionary<String, AnyObject>
                                let distanceText = distance?["text"] as? String ?? ""
                                let durationText = duration?["text"] as? String ?? ""
                                self?.bookTripView.etaLabel.text = distanceText + " | " + durationText
                                if let distanceValue = distance?["value"] as? Double {
                                    // its in meters, 1609.344
                                    // Hardcoded to miles and $
                                    
                                    //let locale = NSLocale.current
                                    let symbol = "$"
                                        //locale.currencySymbol ?? ""
                                    
                                    let distanceInMiles = distanceValue/1609.344
                                    var price = distanceInMiles
                                    price = price * 1
//                                    if symbol != "$" {
//
//                                    }
                                    let priceString = String.init(format: "%.1f", price)
                                    self?.bookTripView.priceLabel.text = symbol + " " + priceString
                                }
                            }
                        }
                    }
                } else {
                    // Error, doing nothing
                }
                
            }
        }
        task.resume()
//        https://maps.googleapis.com/maps/api/distancematrix/json?origins=Vancouver+BC|Seattle&destinations=San+Francisco|Victoria+BC&key=
    }
    
    private func fetchRoute(fromPickup pickup: Location, toDrop drop: Location) {
        let origin = "\(pickup.coordinate.latitude),\(pickup.coordinate.longitude)"
        let destination = "\(drop.coordinate.latitude),\(drop.coordinate.longitude)"
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving"
        let url = URL.init(string: urlString)
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) { (data, response, error) in
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
                    if let routes = result["routes"] as? [NSDictionary] {
                        for route in routes {
                            if let routeOverviewPolyline = route["overview_polyline"] as? NSDictionary {
                                if let encodedPolyline = routeOverviewPolyline["points"] as? String {
                                    guard let coordinates = PolylineUtils.decodePolyline(encodedPolyline) else {
                                        self.coordinates = nil
                                        return
                                    }
                                    self.coordinates = coordinates
                                    self.showMapPolyline()
                                }
                            }
                        }
                    }
                }
                else {
                    // Do Noting,
                }
            }
        }
        task.resume()
    }
    
}

