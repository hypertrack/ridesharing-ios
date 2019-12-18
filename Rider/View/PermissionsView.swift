import AppState
import CommonModels
import CommonViewComponents
import CommonViews
import HyperTrack
import HyperTrackHelper
import SwiftUI

struct PermissionsView: View {
  /// LocationManager provide updates user locations
  private var locationManager: LocationManager
  /// Rider data store
  @ObservedObject var store: Store<AppState, ViewName>

  init(store: Store<AppState, ViewName>) {
    self.store = store
    locationManager = LocationManager()
  }

  var body: some View {
    InfoView(
      nil,
      "Where are you ?",
      "We need location permission to connect you to riders near you. Please go into Settings grant access your device’s location for Hypertrack",
      "Give location permission"
    ) {
      /// Request location permissions
      self.locationManager.requestLocationPermissions()
    }
    .onReceive(locationManager.$authStatus) {
      if $0 == .notDetermined { return }
      self.store.update(.home(.rider(.LOOKING_FOR_RIDES)))
    }
  }
}
