import Combine
import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject {
  var willChange = PassthroughSubject<LocationManager, Never>()
  let locationManager: CLLocationManager

  @Published var authStatus: CLAuthorizationStatus = .notDetermined
  @Published var userLocation: CLLocation? {
    willSet { willChange.send(self) }
  }

  override init() {
    locationManager = CLLocationManager()
    super.init()

    locationManager.delegate = self
  }

  func requestLocationPermissions() {
    locationManager.requestAlwaysAuthorization()
  }

  func startUpdateingLocationsIfNeeded() {
    startUpdateLocation(status: authStatus)
  }

  private func startUpdateLocation(status: CLAuthorizationStatus) {
    switch status {
      case .authorizedAlways, .authorizedWhenInUse:
        locationManager.startUpdatingLocation()
      default: break
    }
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManager(
    _: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    authStatus = status
    startUpdateLocation(status: status)
  }

  func locationManager(
    _: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    userLocation = locations.first
  }
}
