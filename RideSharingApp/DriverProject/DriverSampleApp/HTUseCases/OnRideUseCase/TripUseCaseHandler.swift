//
//  OnRideUseCase.swift
//  DriverSampleApp
//
//  Created by Ashish Asawa on 17/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import HyperTrack


enum TripState {
    case arriving           // before pickup
    case arrivingNow        // near pickup
    case started            // trip started
    case arrived            // reached destination
    case completed          // trip completed
    case undefined          // dont know
}

protocol TripUseCaseHandlerProtocol: class {
//    func startTripClicked()
//    func endTripClicked()
//    func findNewTripClicked()
//    func userCallPressed()
//    func directionPressedPickup()
//    func directionPressedDrop()
}


class TripUseCaseHandler: NSObject, HTOrderTrackingStackViewProviderProtocol, HTOrderTrackingUseCaseDelegate {
    
    func placeOrderClicked() {
        
    }
    
    func orderTrackingEnded(_ type: HTTrackWithTypeData) {
        self.state = .completed
        //prepareUIForCompleted()
    }
    
    func showLoader(_ show: Bool) {
        
    }
    
    var data: [HTComponentProtocol]
    
    var delegate: HTBottomViewUseCaseDelegate?
    
    var containerView: UIView {
        return stackView
    }
    
    func updateData(_ data: [HTComponentProtocol]) {
        
    }
    
    func reloadData() {
        
    }
    
    var orderTrackingUseCase: HTOrderTrackingUseCase? = nil
    private var state: TripState
    private var previousState: TripState
    
    private let collectionId: String
    private let trip: Trip?
    private weak var mapContainer: HTMapContainer?
    
    // UI outlets
    private var stackView: UIStackView!         // our UI will be prepared in this stack view
    private var destinationView: UIView?
    private var userDetailView: UserDetailsView?
    private var userDetailSmallView: UserDetailsSmallView?
    
    private var tripView: UIView?
    private var tripButton: UIButton?
    weak var handlerDelegate: TripUseCaseHandlerProtocol? = nil
    
    // Constraints
    var tripLeadingConstraint: NSLayoutConstraint? = nil
    var tripTrailingConstraint: NSLayoutConstraint? = nil
    var tripTopConstraint: NSLayoutConstraint? = nil
    
    
    init(withCollectionId collectionId: String, trip: Trip, mapContainer: HTMapContainer) {
        self.collectionId   = collectionId
        self.state          = .undefined  //TODO: Calculate state based on hypertrack sdk
        self.previousState  = .undefined
        self.trip           = trip
        self.mapContainer   = mapContainer
        self.data = []
        super.init()
        self.prepareInitialUI()
    }
    
    func startTracking() {
        if orderTrackingUseCase == nil {
            let useCase = HTOrderTrackingUseCase.init(viewModel: nil, provider: self)
            useCase.primaryAction.setTitle("GET DIRECTIONS", for: .normal)
            useCase.primaryAction.titleLabel?.textColor = UIColor.white
            useCase.primaryAction.titleLabel?.font = UIFont(name: WorkSansFontName.semiBold.rawValue, size: 12)
            useCase.isBackButtonHidden = true
            useCase.isPrimaryActionHidden = true
            mapContainer?.setBottomViewWithUseCase(useCase)
            orderTrackingUseCase = useCase
            orderTrackingUseCase?.primaryAction.addTarget(self, action: #selector(TripUseCaseHandler.directionPressed), for: .touchUpInside)
        }
//        mapContainer?.setBottomViewWithUseCase(orderTrackingUseCase)
        if let orderTrackingUseCase = orderTrackingUseCase {
            orderTrackingUseCase.trackActionWithCollectionId(collectionId, pollDuration: orderTrackingUseCase.pollDuration) {[weak self] (actions, error) in
                //self?.mapContainer?.setBottomView((self?.stackView)!)
                if let actions = actions {
                    self?.calculateState(fromActions: actions)
                    self?.prepareUIForState(forAction: actions.first)
                }
                
            }
        }
    }
    
    func stopTracking(isMapCleanup: Bool) {
        if isMapCleanup == true {
            orderTrackingUseCase?.mapDelegate?.cleanUp()
        }
        orderTrackingUseCase?.stop()
    }
    
//    func tripStarted() {
//        self.state = .started
//        prepareUIForState()
//    }
    
//    func tripCompleted() {
//        self.state = .completed
//        prepareUIForState()
//    }
    
    // MARK: Private Methods
    
    private func calculateState(fromActions actions:[HTAction]?) {
        if previousState == .completed {
            // Trip Completed no need to do anything now
            return
        }
        previousState = self.state
        // Ideally this should be done at server end,
        // and client should read the state from firebase.
        // So it wont have to calculate state again and again.
        self.state = .undefined
        if let actions  = actions {
            let action = actions.first(where: { (action) -> Bool in
                //TODO: improve method
                action.status != "completed" || action.status != "canceled"
            })
            if let action = action {
                if action.type.caseInsensitiveCompare("pickup") == .orderedSame {
                    if action.arrivalStatus.caseInsensitiveCompare("arriving") == .orderedSame ||
                        action.arrivalStatus.caseInsensitiveCompare("arrived") == .orderedSame {
                        self.state = .arrivingNow
                    } else {
                        self.state = .arriving
                    }
                } else if action.type.caseInsensitiveCompare("drop") == .orderedSame {
                    if action.status.caseInsensitiveCompare("completed") == .orderedSame {
                        self.state = .completed
                    }
                    else if action.arrivalStatus.caseInsensitiveCompare("arriving") == .orderedSame ||
                        action.arrivalStatus.caseInsensitiveCompare("arrived") == .orderedSame {
                        self.state = .arrived
                    } else {
                        self.state = .started
                    }
                }
            }
        }
    }
    
    private func prepareUIForState(forAction action: HTAction?) {
        //TODO: UI Preparation separate worker class ?
        // UI preparation logic is based on the assumption, trip can not go backward
        // it will always start with arriving, arriving now, started, arrived. with only exception completed can be call any time
        // This can get call multiple times
        if previousState == state {
            return
        }
        switch state {
            case .arriving:         prepareUIForArriving()
            case .arrivingNow:      prepareUIForArrivingNow()
            case .started:          prepareUIForStarted()
            case .arrived:          prepareUIForArrived()
            case .completed:        prepareUIForCompleted(forAction: action)
            case .undefined:        prepareUIForUndefined()
        }
    }
    
    private func prepareInitialUI() {
        stackView         = UIStackView()
        // Preparing all views
        // based on situation, hide unhide view
        
        // 2. Stack View Setup
        // 2.1 Stack View properties setup
        //stackView?.spacing = 10
        stackView?.axis = .vertical
        stackView?.clipsToBounds = true
        stackView.alignment = .fill
        
        //3. DropOff View
        destinationView = dropOffView()
        destinationView?.isHidden = true
        stackView.addArrangedSubview(destinationView!)
        
        //4. User Detail View
        //TODO: User view padding
        //userView.topAnchor.constraint(equalTo: innerStackView!.topAnchor, constant: 23).isActive = true
        userDetailView = Bundle.main.loadNibNamed("UserDetailsView", owner: self, options: nil)?.first as! UserDetailsView
        userDetailView?.backgroundColor = UIColor.clear
        userDetailView?.isHidden = true
        userDetailView?.feed(fromTrip: trip)
        userDetailView?.callPressedClosure = { [weak self] in
            //self?.handlerDelegate?.userCallPressed()
        }
        stackView.addArrangedSubview(userDetailView!)
        
        userDetailSmallView = Bundle.main.loadNibNamed("UserDetailsSmallView", owner: self, options: nil)?.first as! UserDetailsSmallView
        userDetailSmallView?.backgroundColor = UIColor.clear
        userDetailSmallView?.isHidden = true
        userDetailSmallView?.feed(fromTrip: trip)
        stackView.addArrangedSubview(userDetailSmallView!)
        
        //5. Trip View
        let tripView = UIView.init()
        tripView.backgroundColor = UIColor.clear
        tripView.heightAnchor.constraint(equalToConstant: 77).isActive = true
        stackView.addArrangedSubview(tripView)
        let tripButton = UIButton.init()
        tripButton.translatesAutoresizingMaskIntoConstraints = false
        tripView.addSubview(tripButton)
        tripButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        //startTripButton.centerXAnchor.constraint(equalTo: startTripView.centerXAnchor, constant: 0).isActive = true
//        tripButton.centerYAnchor.constraint(equalTo: tripView.centerYAnchor, constant: 0).isActive = true
        tripButton.setTitle("", for: .normal)
        tripButton.titleLabel?.textColor = UIColor.white
        tripButton.titleLabel?.font = UIFont(name: WorkSansFontName.semiBold.rawValue, size: 12)
        tripButton.addTarget(self, action: #selector(tripButtonPressed(sender:)), for: .touchUpInside)
        tripLeadingConstraint = tripButton.leadingAnchor.constraint(equalTo: tripView.leadingAnchor, constant: 24)
        tripLeadingConstraint?.isActive = true
        tripTrailingConstraint = tripButton.trailingAnchor.constraint(equalTo: tripView.trailingAnchor, constant: -23)
        tripTrailingConstraint?.isActive = true
        tripTopConstraint = tripButton.topAnchor.constraint(equalTo: tripView.topAnchor, constant: 6)
        tripTopConstraint?.isActive = true
        tripButton.layer.cornerRadius = 4
        //TODO: Theming
        self.tripView = tripView
        self.tripButton = tripButton
        tripView.clipsToBounds = true
        self.tripView?.isHidden = true
        
        // Add Gestures
        let upGesture = UISwipeGestureRecognizer.init()
        upGesture.direction = .up
        upGesture.addTarget(self, action: #selector(TripUseCaseHandler.upGestureCompleted))
        stackView.addGestureRecognizer(upGesture)
        
        let downGesture = UISwipeGestureRecognizer.init()
        downGesture.direction = .down
        downGesture.addTarget(self, action: #selector(TripUseCaseHandler.downGestureCompleted))
        stackView.addGestureRecognizer(downGesture)
    }
    
    private func dropOffView() -> UIView {
        let dropOffView = UIView.init()
        dropOffView.backgroundColor = UIColor.clear
        let titleLabel = UILabel.init()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dropOffView.addSubview(titleLabel)
        titleLabel.text = "DROPOFF"
        titleLabel.textColor = UIColor.lightGray
        titleLabel.font = UIFont(name: WorkSansFontName.semiBold.rawValue, size: 12)

        let subtitleLabel = UILabel.init()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        dropOffView.addSubview(subtitleLabel)
        subtitleLabel.text = trip?.drop.displayAddress
        subtitleLabel.textColor = UIColor.black
        subtitleLabel.font = UIFont(name: WorkSansFontName.regular.rawValue, size: 14)


        // constraints
        titleLabel.topAnchor.constraint(equalTo: dropOffView.topAnchor, constant: 21).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: dropOffView.leadingAnchor, constant: 31).isActive = true

        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6).isActive = true
        subtitleLabel.leadingAnchor.constraint(equalTo: dropOffView.leadingAnchor, constant: 31).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: dropOffView.trailingAnchor, constant: -31).isActive = true

        dropOffView.heightAnchor.constraint(equalToConstant: 59).isActive = true
        
        return dropOffView
    }
    
    // before pickup
    private func prepareUIForArriving() {
        orderTrackingUseCase?.isPrimaryActionHidden = false
        destinationView?.isHidden = true
        userDetailView?.isHidden = false
        userDetailSmallView?.isHidden = true
        tripButton?.backgroundColor = UIColor.brandColor
        tripButton?.setTitle("START TRIP", for: .normal)
        tripTopConstraint?.constant = 6
        tripLeadingConstraint?.constant = 24
        tripTrailingConstraint?.constant = -23
        //tripView?.isHidden = false
    }
    
    // near pickup
    private func prepareUIForArrivingNow() {
        orderTrackingUseCase?.isPrimaryActionHidden = true
        destinationView?.isHidden = true
        userDetailView?.isHidden = false
        userDetailSmallView?.isHidden = true
        tripButton?.backgroundColor = UIColor.brandColor
        tripButton?.setTitle("START TRIP", for: .normal)
        tripTopConstraint?.constant = 6
        tripLeadingConstraint?.constant = 24
        tripTrailingConstraint?.constant = -23
        tripView?.isHidden = false
    }
    
    // trip started
    private func prepareUIForStarted() {
        orderTrackingUseCase?.isPrimaryActionHidden = false
        destinationView?.isHidden = false
        userDetailView?.isHidden = true
        userDetailSmallView?.isHidden = false
        tripButton?.backgroundColor = UIColor(red:0.89, green:0.4, blue:0.31, alpha:1)
        tripButton?.setTitle("END TRIP", for: .normal)
        tripTopConstraint?.constant = 0
        tripLeadingConstraint?.constant = 31
        tripTrailingConstraint?.constant = -31
        tripView?.isHidden = true
    }
    
    // trip arrived
    private func prepareUIForArrived() {
        orderTrackingUseCase?.isPrimaryActionHidden = true
        destinationView?.isHidden = false
        userDetailView?.isHidden = true
        userDetailSmallView?.isHidden = false
        tripButton?.backgroundColor = UIColor(red:0.89, green:0.4, blue:0.31, alpha:1)
        tripButton?.setTitle("END TRIP", for: .normal)
        tripTopConstraint?.constant = 0
        tripLeadingConstraint?.constant = 31
        tripTrailingConstraint?.constant = -31
        tripView?.isHidden = true
    }
    
    // trip completed, summary view
    private func prepareUIForCompleted(forAction action: HTAction?) {
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        self.orderTrackingUseCase?.isPrimaryActionHidden = false
        self.orderTrackingUseCase?.primaryAction.setTitle("FIND NEW RIDES", for: .normal)
        self.orderTrackingUseCase?.primaryAction.titleLabel?.textColor = UIColor.white
        self.orderTrackingUseCase?.primaryAction.titleLabel?.font = UIFont(name: WorkSansFontName.semiBold.rawValue, size: 12)
        self.orderTrackingUseCase?.primaryAction.addTarget(self, action: #selector(TripUseCaseHandler.findNewTrip), for: .touchUpInside)
        self.orderTrackingUseCase?.isBackButtonHidden = true
        let tripSummaryView = Bundle.main.loadNibNamed("TripSummaryView", owner: self, options: nil)?.first as! TripSummaryView
        tripSummaryView.feedData(withAction: action, passengerName: trip?.userDetails.name ?? "")
        stackView.addArrangedSubview(tripSummaryView)
    }
    
    private func prepareUIForUndefined() {
        
    }
    
    @objc private func upGestureCompleted() {
        self.tripView?.isHidden = false
    }
    
    @objc private func downGestureCompleted() {
        if self.state == .arrivingNow || self.state == .arrived {
            return
        }
        self.tripView?.isHidden = true
    }
    
    @objc private func tripButtonPressed(sender: UIButton) {
        if self.state == .arrivingNow || self.state == .arriving {
        //    self.handlerDelegate?.startTripClicked()
        } else if self.state == .started ||  self.state == .arrived {
          //  self.handlerDelegate?.endTripClicked()
        }
    }
    
    @objc private func findNewTrip() {
        //self.handlerDelegate?.findNewTripClicked()
    }
    
    @objc private func directionPressed() {
        if self.state == .arrivingNow || self.state == .arriving {
          //  self.handlerDelegate?.directionPressedPickup()
        } else if self.state == .started ||  self.state == .arrived {
            //self.handlerDelegate?.directionPressedDrop()
        }
    }
    
}
