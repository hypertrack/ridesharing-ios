import Foundation
import HyperTrack
import UIKit

/// Struct that provide HyperTrack errors for ErrorView
public struct HError {
  /// Title error
  public let title: String
  /// Subtitle error
  public let subTitle: String
  /// Title for button on ErrorView
  public let btTitle: String
  /// Specific deep link
  public let settingDeepLink: String
  /// Type of HyperTrack error, one of: `HyperTrack.TrackingError` or `RestorableError` of `UnrestorableError`
  public let type: Error

  /// Create instance for error
  public static func makeHError(error: HyperTrack.TrackingError) -> HError? {
    switch error {
      case let .restorableError(restorable):
        return HError(error: restorable)
      case let .unrestorableError(unrestorable):
        return HError(error: unrestorable)
    }
  }

  /// Initialize the error with `RecoverableError`
  private init?(error: HyperTrack.RestorableError) {
    switch error {
    case .locationPermissionsDenied,
         .locationPermissionsRestricted,
         .locationPermissionsNotDetermined,
         .locationServicesDisabled:
      title = "Where are you?"
      subTitle = "We need location permission to connect you to riders near you. Please go into Settings grant access your device’s location for Hypertrack"
      btTitle = "Give location permissions"
      settingDeepLink = "\(UIApplication.openSettingsURLString)/prefs:root=Privacy&path=LOCATION"
      type = error
    case .motionActivityServicesDisabled,
         .motionActivityPermissionsRestricted,
         .motionActivityPermissionsNotDetermined:
      title = "Provide Motion & Fitness permissions"
      subTitle = "Ridesharing uses your movement to optimize battery usage. It will only send data when you are on the go. Please turon on  Motion & Fitness permissions for Ridesharing in Settings.app > Privacy > Motion & Fitness"
      btTitle = "Give motion permission"
      settingDeepLink = "\(UIApplication.openSettingsURLString)/prefs:root=Privacy&path=MOTION"
      type = error
    case .paymentDefault:
      title = ""
      subTitle = "There is a problem with your payment method. Please update payment information in HyperTrack's dashboard https://dashboard.hypertrack.com/setup"
      btTitle = ""
      settingDeepLink = ""
      type = error
    case .trialEnded:
      title = ""
      subTitle = "HyperTrack's trial period has ended. Please add payment information in HyperTrack's dashboard https://dashboard.hypertrack.com/setup"
      btTitle = ""
      settingDeepLink = ""
      type = error
    default:
      return nil
    }
  }

  /// Initialize the error with `UnrecoverableError`
  private init?(error: HyperTrack.UnrestorableError) {
    switch error {
      case .invalidPublishableKey:
        title = ""
        subTitle = "Invalid Publishable Key. Please check it again in HyperTrack dashboard https://dashboard.hypertrack.com/setup"
        btTitle = ""
        settingDeepLink = ""
        type = error
      case .motionActivityPermissionsDenied:
        title = "Provide Motion & Fitness permissions"
        subTitle = "Ridesharing uses your movement to optimize battery usage. It will only send data when you are on the go. Please turon on  Motion & Fitness permissions for Ridesharing in Settings.app > Privacy > Motion & Fitness"
        btTitle = "Give motion permission"
        settingDeepLink = "\(UIApplication.openSettingsURLString)/prefs:root=Privacy&path=MOTION"
        type = error
    }
  }

  /// Initialize the error with `ProductionError`
  public init?(error: HyperTrack.ProductionError) {
    switch error {
      case .locationServicesUnavalible:
        title = "Where are you?"
        subTitle = "We need location permission to connect you to riders near you. Please go into Settings grant access your device’s location for Hypertrack"
        btTitle = "Give location permissions"
        settingDeepLink = "\(UIApplication.openSettingsURLString)/prefs:root=Privacy&path=LOCATION"
        type = error
      case .motionActivityServicesUnavalible, .motionActivityPermissionsDenied:
        title = "Provide Motion & Fitness permissions"
        subTitle = "Ridesharing uses your movement to optimize battery usage. It will only send data when you are on the go. Please turon on  Motion & Fitness permissions for Ridesharing in Settings.app > Privacy > Motion & Fitness"
        btTitle = "Give motion permission"
        settingDeepLink = "\(UIApplication.openSettingsURLString)/prefs:root=Privacy&path=MOTION"
        type = error
    }
  }
}

/// provide `UnrecoverableError` if needed
public func errorIfNeeded(error: HError) -> HError {
  if let errorType = error.type as? HyperTrack.UnrestorableError {
    switch errorType {
      case .motionActivityPermissionsDenied:
        return error
      default:
        fatalError("\(error.subTitle)")
    }
  } else {
    return error
  }
}
