import AppState
import Combine
import CommonModels
import CommonViews
import CoreLocation
import CoreMotion
import SwiftUI

final class PermissionsProvider: NSObject, ObservableObject {
  let locationManager: CLLocationManager = CLLocationManager()
  let motionActivityManager = CMMotionActivityManager()
  let motionActivityQueue = OperationQueue()

  @Published var isFullAccessGranted: Bool = false

  override init() {
    super.init()
    locationManager.delegate = self
  }

  func requestPermissions() {
    /// Location permissions response will request motion permissions
    requestLocationPermissions()
  }

  private func requestLocationPermissions() {
    print("Current Location authorization status: \(CLLocationManager.authorizationStatus())")
    locationManager.requestAlwaysAuthorization()
  }

  private func requestMotionPermissions() {
    if CMMotionActivityManager.isActivityAvailable() {
      print(
        "Current Motion Activity authorization status: \(CMMotionActivityManager.authorizationStatus())"
      )

      motionActivityManager.queryActivityStarting(
        from: Date.distantPast, to: Date(), to: motionActivityQueue
      ) { activities, error in
        if error != nil {
          print("Motion Activity permissions denied")
        } else if activities != nil || error == nil {
          print("Motion Activity permissions authorized")
          DispatchQueue.main.async {
            self.isFullAccessGranted = true
          }
        }
      }
    } else {
      print("This is not an iPhone, or it doesn't have Motion Activity hardware")
    }
  }
}

extension PermissionsProvider: CLLocationManagerDelegate {
  func locationManager(
    _: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    if status == .authorizedAlways ||
      status == .authorizedWhenInUse {
      requestMotionPermissions()
    }
  }
}

public struct PermissionsView: View {
  @ObservedObject public var store: Store<AppState, ViewName>
  private let permissionsProvier = PermissionsProvider()

  public init(store: Store<AppState, ViewName>) {
    self.store = store
  }

  public var body: some View {
    InfoView(
      nil,
      "Where are you ?",
      "We need location permission to connect you to riders near you. Please go into Settings grant access your device’s location for Hypertrack",
      "Give location permission"
    ) {
      self.permissionsProvier.requestPermissions()
    }
    .onReceive(permissionsProvier.$isFullAccessGranted) { output in
      if output { self.store.update(.home(.driver(.NEW))) }
    }
  }
}
