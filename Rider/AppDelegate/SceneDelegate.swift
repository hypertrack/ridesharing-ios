import AppState
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo _: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) {
    let store = Store(
      initialValue: AppState(),
      reducer: appReducer
    )
    let dataflow = RiderDataFlow(
      store: store
    )
    /// Use a UIHostingController as window root view controller.
    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = UIHostingController(
        rootView: ContentView(
          store: store,
          dataflow: dataflow
        )
      )
      self.window = window
      window.makeKeyAndVisible()
    }
  }
}
