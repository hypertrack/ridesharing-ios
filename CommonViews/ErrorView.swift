import AppState
import Combine
import CommonModels
import CommonViewComponents
import SwiftUI
import Utility

/// Ridesharing error view
public struct ErrorView: View {
  /// AppState store object
  @ObservedObject public var store: Store<AppState, ViewName>
  /// Error model for ErrorView
  public let error: HError?

  public init(store: Store<AppState, ViewName>, error: HError?) {
    self.store = store
    self.error = error
  }

  public var body: some View {
    InfoView(
      nil,
      self.error?.title ?? "",
      self.error?.subTitle ?? "",
      error?.btTitle ?? ""
    ) {
      self.getiOSSettings()
    }
    .onReceive(appStateReceiver.$notification) { notification in
      if notification.name == UIApplication.didEnterBackgroundNotification {
        self.store.update(.home(.driver(.NEW)))
      }
    }
  }

  /// Get settings URL
  private func getiOSSettings() {
    guard let deppLink = URL(string: self.error?.settingDeepLink ?? "")
      else { return }
    UIApplication.shared.open(deppLink)
  }
}
