import AppState
import Combine
import CommonModels
import CommonViews
import HyperTrack
import HyperTrackHelper
import SwiftUI
import Utility

struct ContentView: View {
  /// Rider store
  @ObservedObject var store: Store<AppState, ViewName>
  /// Rider dataflow
  var dataflow: RiderDataFlow

  var body: some View {
    ZStack {
      self.currentView()
        .animation(.default)
    }
  }

  func currentView() -> some View {
    if store.value.lastView == ViewName.auth {
      return AnyView(AuthView(store: store))
    } else if store.value.lastView == ViewName.permissions {
      return AnyView(PermissionsView(store: store))
    } else if store.value.lastView == ViewName.home(.rider(.LOOKING_FOR_RIDES)) {
      return AnyView(RiderHomeView(dataflow: dataflow))
    } else if store.value.lastView == ViewName.error {
      return AnyView(ErrorView(store: store, error: hyperTrackReceiver.error))
    } else {
      return AnyView(LoginView(store: store))
    }
  }
}
