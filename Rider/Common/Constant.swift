import AppState
import CommonViews
import class Firebase.Firestore
import Foundation
import HyperTrackViews
import SwiftUI
import UIKit
import Utility

/// Firestore database reference
let db = Firestore.firestore()

let zoomRiderButtonPadding: [CGFloat] = [
  screenPadding(180),
  screenPadding(160),
  screenPadding(140) + 32,
  screenPadding(140) + 32,
  screenPadding(140) + 32,
  screenPadding(140) + 32,
  screenPadding(250) + 32,
  0
]

/// Instance to provide HyperTrackView SDK
let hyperTrackViews = HyperTrackViews(
  publishableKey: publishableKey
)
