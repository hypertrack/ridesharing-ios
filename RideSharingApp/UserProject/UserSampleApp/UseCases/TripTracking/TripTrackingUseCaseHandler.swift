//
//  RideTrackingUseCaseHandler.swift
//  UserSampleApp
//
//  Created by Ashish Asawa on 24/04/18.
//  Copyright © 2018 Ashish Asawa. All rights reserved.
//

import Foundation
import HyperTrack

protocol TripTrackingUseCaseHandlerDelegate: class {
    func bookAnotherRide()
    func shareRide(forAction action: HTAction)
    func callPressed()
}

enum TripState {
    case arriving           // before pickup
    case arrivingNow        // near pickup
    case started            // trip started
    case arrived            // reached destination
    case completed          // trip completed
    case undefined          // dont know
}

enum ActionType: String {
    case pickup = "Pickup"
    case drop   = "Drop"
}

enum ActionStatusKeys: String {
    case arriving    = "arriving"
    case arrived     = "arrived"
    case completed   = "completed"
    case canceled    = "canceled"
}


class TripTrackingUseCaseHandler: NSObject, HTOrderTrackingStackViewProviderProtocol {
   
    private var stackView: UIStackView!
    private var previousState: TripState
    private var state: TripState
    
    private var driverDetailView: DriverDetailView?
    private var summaryView: TripSummaryView?
    
    var delegate: HTBottomViewUseCaseDelegate?
    
    var containerView: UIView {
        return stackView
    }
    
    func updateData(_ data: [HTComponentProtocol]) {
        
    }
    
    func reloadData() {
        
    }
    
    private let actionId: String
    private var action: HTAction?
    private weak var mapContainer: HTMapContainer?
    private let trip: Trip?
    
    private var orderTrackingUseCase: HTOrderTrackingUseCase? = nil
    
    
    weak var handlerDelgate: TripTrackingUseCaseHandlerDelegate? = nil
    
    init(withActionId actionId: String, mapContainer: HTMapContainer, forTrip trip: Trip?) {
        self.actionId       = actionId
        self.mapContainer   = mapContainer
        self.state          = .undefined
        self.previousState  = .undefined
        self.trip           = trip
        super.init()
        prepareInitialUI()
    }
    
    private func prepareInitialUI() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.alignment = .fill
    }
    
    func getCurrentActionId() -> String {
        return actionId
    }
    
    func getCurrentState() -> TripState {
        return state
    }
    
    func startTracking() {
        if orderTrackingUseCase == nil {
            let useCase = HTOrderTrackingUseCase.init(viewModel: nil, provider: self)
            useCase.isBackButtonHidden = true
            useCase.isPrimaryActionHidden = true
            //useCase.trackingDelegate = self
            orderTrackingUseCase = useCase
            useCase.primaryAction.addTarget(self, action: #selector(TripTrackingUseCaseHandler.primaryButtonTap), for: .touchUpInside)
        }
        if let orderTrackingUseCase = orderTrackingUseCase {
            mapContainer?.setBottomViewWithUseCase(orderTrackingUseCase)
            orderTrackingUseCase.trackActionWithIds([actionId], pollDuration: orderTrackingUseCase.pollDuration, completionHandler: {[weak self] (actions, error) in
                if let actions = actions {
                    self?.handleActionsReceived(actions: actions)
                }
            })
        }
    }
    
    private func handleActionsReceived(actions: [HTAction]) {
        guard let action = actions.first else {
            // TODO: No action received handling
            return
        }
        self.action = action
        calculateState(forAction: action)
        prepareUIForState(forAction: action)
    }
    
    private func calculateState(forAction action: HTAction) {
        if previousState == .completed {
            // Trip Completed no need to do anything now
            return
        }
        previousState = self.state
        // Ideally this should be done at server end,
        // and client should read the state from firebase.
        // So it wont have to calculate state again and again.
        self.state = .undefined
        if action.type.caseInsensitiveCompare(ActionType.pickup.rawValue) == .orderedSame {
            if action.arrivalStatus.caseInsensitiveCompare(ActionStatusKeys.arriving.rawValue) == .orderedSame ||
                action.arrivalStatus.caseInsensitiveCompare(ActionStatusKeys.arrived.rawValue) == .orderedSame {
                self.state = .arrivingNow
            } else {
                self.state = .arriving
            }
        } else if action.type.caseInsensitiveCompare(ActionType.drop.rawValue) == .orderedSame {
            TripHelper.saveLastTripActionId(actionId: actionId)
            if action.status.caseInsensitiveCompare(ActionStatusKeys.completed.rawValue) == .orderedSame {
                self.state = .completed
                // State Completed stop the listener. TODO: send this info via protocol
                // No Need to listen further
                //self.orderTrackingUseCase?.stop()
                DataService.instance.stopListeningForTrip()
            }
            else if action.arrivalStatus.caseInsensitiveCompare(ActionStatusKeys.arriving.rawValue) == .orderedSame ||
                action.arrivalStatus.caseInsensitiveCompare(ActionStatusKeys.arrived.rawValue) == .orderedSame {
                self.state = .arrived
            } else {
                self.state = .started
            }
        }
    }
    
    private func prepareUIForState(forAction action: HTAction) {
        //TODO: UI Preparation separate worker class ?
        // UI preparation logic is based on the assumption, trip can not go backward
        // it will always start with arriving, arriving now, started, arrived. with only exception completed can be call any time
        // This can get call multiple times
        if previousState == state {
            return
        }
        switch state {
            case .arriving:         prepareUIDuringRide(forAction: action)
            case .arrivingNow:      prepareUIDuringRide(forAction: action)
            case .started:          prepareUIDuringRide(forAction: action)
            case .arrived:          prepareUIDuringRide(forAction: action)
            case .completed:        prepareUIAfterRideCompletion(forAction: action)
            case .undefined:        prepareUIForUndefined()
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
            case .arriving:         prepareUIDuringRide(forAction: action)
            case .arrivingNow:      prepareUIDuringRide(forAction: action)
            case .started:          prepareUIDuringRide(forAction: action)
            case .arrived:          prepareUIDuringRide(forAction: action)
            case .completed:        prepareUIAfterRideCompletion(forAction: action)
            case .undefined:        prepareUIForUndefined()
        }
    }
    
    private func prepareUIForUndefined() {
        if let driverDetailView = self.driverDetailView {
            self.stackView.removeArrangedSubview(driverDetailView)
            driverDetailView.removeFromSuperview()
        }
        self.driverDetailView = nil
        
    }
    
    private func prepareUIDuringRide(forAction action: HTAction?) {
        if let _ = self.driverDetailView {
            // alreading showing, do nothing
        } else {
            let driverDetailView = Bundle.main.loadNibNamed("DriverDetailView", owner: self, options: nil)?.first as! DriverDetailView
            driverDetailView.titleLabel.text = trip?.driverDetails?.name ?? action?.user?.name
            driverDetailView.subtitleLabel.text = trip?.driverDetails?.carDetails ?? "TOYOTA Prius | N1KH1L6"
            driverDetailView.callPressedClosure = { [weak self] in
                self?.handlerDelgate?.callPressed()
            }
            stackView.addArrangedSubview(driverDetailView)
            if action?.type.caseInsensitiveCompare(ActionType.drop.rawValue) == .orderedSame {
                orderTrackingUseCase?.primaryAction.setTitle("SHARE", for: .normal)
                orderTrackingUseCase?.isPrimaryActionHidden = false
            } else {
                orderTrackingUseCase?.isPrimaryActionHidden = true
            }
            self.driverDetailView = driverDetailView
        }
    }
    
    private func prepareUIAfterRideCompletion(forAction action: HTAction?) {
        if let driverDetailView = self.driverDetailView {
            self.stackView.removeArrangedSubview(driverDetailView)
            driverDetailView.removeFromSuperview()
            self.driverDetailView = nil
        }
        if let _ = self.summaryView {
            // already showing, do nothing
        } else {
            let tripSummaryView = Bundle.main.loadNibNamed("TripSummaryView", owner: self, options: nil)?.first as! TripSummaryView
            tripSummaryView.feedData(withAction: action, driverName: action?.user?.name ?? "Joe West")
            stackView.addArrangedSubview(tripSummaryView)
            self.summaryView = tripSummaryView
            orderTrackingUseCase?.primaryAction.setTitle("BOOK ANOTHER RIDE", for: .normal)
            orderTrackingUseCase?.isPrimaryActionHidden = false
        }
    }
    
    func stopTracking() {
        orderTrackingUseCase?.mapDelegate?.cleanUp()
        orderTrackingUseCase?.stop()
    }
    
    @objc private func primaryButtonTap() {
        if self.state == .completed {
            handlerDelgate?.bookAnotherRide()
        } else {
            if let action = self.action {
                handlerDelgate?.shareRide(forAction: action)
            }
        }
    }
    
}
