import AppState
import Combine
import CommonModels
import Foundation
import HyperTrack
import HyperTrackViews
import SwiftUI
import UIKit
import Utility

/// Instance for observing HyperTrack SDK notification events
public let hyperTrackReceiver: HyperTrackEventReceiver =
  HyperTrackEventReceiver(
  )

/// Object for observing HyperTrack notification events
public final class HyperTrackEventReceiver {
  /// Marker for receiving HyperTrack error
  @Published public var showingError = false
  /// HyperTrack received error
  @Published public var error: HError? = nil
  /// HyperTrack tracking status from notifications
  @Published public var isTracking: Bool = false

  /// Subjects
  private let errorSubject = PassthroughSubject<HError, Never>()
  private let trackingSubject = PassthroughSubject<Notification, Never>()
  private var cancellables: [AnyCancellable] = []

  public init() {
    bindInputs()
    bindOutputs()
  }

  private func bindInputs() {
    let startedTrackingPublisher = NotificationCenter.Publisher(
      center: .default, name: HyperTrack.startedTrackingNotification,
      object: nil
    )
    let stoppedTrackingPublisher = NotificationCenter.Publisher(
      center: .default, name: HyperTrack.stoppedTrackingNotification,
      object: nil
    )

    let trackingInputStream = startedTrackingPublisher
      .merge(with: stoppedTrackingPublisher)
      .share()
      .subscribe(trackingSubject)

    let unrecoverableErrorInputStream = NotificationCenter.Publisher(
      center: .default,
      name: HyperTrack.didEncounterUnrestorableErrorNotification, object: nil
    )
    let recoverableErrorMessageInputStream = NotificationCenter.Publisher(
      center: .default,
      name: HyperTrack.didEncounterRestorableErrorNotification, object: nil
    )

    let errorInputStream = unrecoverableErrorInputStream
      .merge(with: recoverableErrorMessageInputStream)
      .share()
      .compactMap { $0.hyperTrackTrackingError() }
      .compactMap { HError.makeHError(error: $0) }
      .subscribe(errorSubject)

    cancellables += [
      trackingInputStream,
      errorInputStream
    ]
  }

  private func bindOutputs() {
    let trackingStream = trackingSubject
      .map { notification in
        switch notification.name {
          case HyperTrack.startedTrackingNotification: return true
          case HyperTrack.stoppedTrackingNotification: return false
          default: return false
        }
      }
      .assign(to: \.isTracking, on: self)

    let errorStream = errorSubject
      .map { error -> HError? in error }
      .assign(to: \.error, on: self)

    let isErrorStream = errorSubject
      .map { _ in true }
      .assign(to: \.showingError, on: self)

    cancellables += [
      errorStream,
      trackingStream,
      isErrorStream
    ]
  }
}
