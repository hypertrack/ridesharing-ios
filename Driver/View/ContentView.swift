import AppState
import Combine
import CommonModels
import CommonViews
import HyperTrack
import HyperTrackHelper
import SwiftUI
import Utility

struct ContentView: View {
  @ObservedObject var store: Store<AppState, ViewName>
  var dataflow: DriverDataFlow
  /// HyperTrack SDK instance
  let hypertrack: HyperTrack

  var body: some View {
    ZStack {
      self.currentView()
    }
    .onReceive(hyperTrackReceiver.$error) { _ in
      if let error = hyperTrackReceiver.error {
        _ = errorIfNeeded(error: error)
        self.store.update(.error)
      }
    }
    .onReceive(appStateReceiver.$notification) { notification in
      switch (notification.name, self.store.value.user) {
        case (UIApplication.didEnterBackgroundNotification, _):
          self.hypertrack.syncDeviceSettings()
        case let (UIApplication.didBecomeActiveNotification, user):
          if user != nil { self.hypertrack.start() }
        default:
          break
      }
    }
  }

  func currentView() -> some View {
    if store.value.lastView == ViewName.auth {
      return AnyView(AuthView(hypertrack: hypertrack, store: store))
    } else if store.value.lastView == ViewName.permissions {
      return AnyView(PermissionsView(store: store))
    } else if store.value.lastView == ViewName.home(.driver(.NEW)) {
      hypertrack.start()
      return AnyView(DriverHomeView(dataflow: dataflow))
    } else if store.value.lastView == ViewName.error {
      return AnyView(ErrorView(store: store, error: hyperTrackReceiver.error))
    } else {
      return AnyView(LoginView(store: store))
    }
  }
}
