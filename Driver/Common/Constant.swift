import AppState
import CommonModels
import CommonViews
import class Firebase.Firestore
import HyperTrack
import SwiftUI
import UIKit
import Utility

/// Firestore database reference
let db = Firestore.firestore()

let zoomDriverButtonPadding: [CGFloat] = [
  screenPadding(130) + 32,
  screenPadding(150) + 32,
  screenPadding(240),
  screenPadding(175) + 32,
  screenPadding(250) + 32,
  0
]

/// Makes initial screen
public func getBackInitialView() -> some View {
  switch HyperTrack.makeSDK(
    publishableKey: HyperTrack.PublishableKey(publishableKey)!
  ) {
    case let .success(hypertrack):
      let store = Store(
        initialValue: AppState(),
        reducer: appReducer
      )
      let dataflow = DriverDataFlow(store: store, hypertrack: hypertrack)
      return AnyView(ContentView(
        store: store,
        dataflow: dataflow,
        hypertrack: hypertrack
      ))
    case let .failure(error):
      switch error {
        case let .developmentError(devError):
          fatalError("\(devError)")
        case let .productionError(prodError):
          return AnyView(ErrorView(store: Store(
            initialValue: AppState(),
            reducer: appReducer
          ), error: HError(error: prodError)))
      }
  }
}
