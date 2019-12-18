import AppState
import Combine
import CommonModels
import protocol Firebase.ListenerRegistration
import Foundation
import HyperTrackHelper
import HyperTrackViews
import Utility

final class RiderDataFlow: ObservableObject {
  /// Store object for AppState
  var store: Store<AppState, ViewName>
  /// Array of Firestore references
  private var firestoreSubscriptions: [ListenerRegistration] = []
  /// Array of HyperTrack references
  private var cancelViewsSubscription: [Cancel] = []
  /// Array of subscribers
  private var cancellables: [AnyCancellable] = []
  /// Subject that provide updates for movement status from HyperTrackViews SDK
  let movementStatusWillChange: PassthroughSubject<MovementStatus?, Never> = PassthroughSubject<
    MovementStatus?,
    Never
  >()
  /// Subject that provide updates for cancel order
  let cancelOrderSubject: PassthroughSubject<Void, Never> = PassthroughSubject<
    Void,
    Never
  >()
  /// User movement status
  @Published var userMovementStatus: MovementStatus? = nil
  /// Trip summary
  @Published var tripSummary: MovementStatus.Trip? = nil

  init(store: Store<AppState, ViewName>) {
    self.store = store
    bindOutputs()
    makeSubscriptionOnCurrentOrder()
    createUserMovementStatusSubscription()
  }

  /// Binding movementstatus updates
  private func bindOutputs() {
    let movementStatusStream = movementStatusWillChange
      .map { movementStatus -> MovementStatus? in movementStatus }
      .assign(to: \.userMovementStatus, on: self)
    cancellables = [
      movementStatusStream
    ]
    let cancelStream = cancelOrderSubject
      .sink {
        self.cancelOrder()
      }
    cancellables = [
      cancelStream,
      movementStatusStream
    ]
  }

  /// Create order from `destination` and `pickup`
  func makeOrderFrom(destination: Order.Place, pickup: Order.Place) -> Order? {
    guard let user = self.store.value.user else { return nil }
    return Order(
      id: "",
      status: .NEW,
      rider: user,
      pickup: pickup,
      dropoff: destination,
      created_at: DateFormatter.iso8601Full.string(from: Date()),
      driver: nil,
      trip_id: "",
      updated_at: DateFormatter.iso8601Full.string(from: Date())
    )
  }

  /// Sending rider order
  func sendOrderOnFireStore(order: Order?) {
    guard let uOrder = order else { return }
    setNewFirestoreOrder(db, uOrder) { [weak self] result in
      guard let self = self else { return }
      switch result {
        case let .success(order):
          self.store.value.order = order
          self.store.update(.home(.rider(.LOOKING_DRIVER)))
          print("ORDER MODEL")
          dump(order.id)
        case let .failure(error):
          print("Create order | error: \(error)")
      }
    }
  }

  /// Make subscription for specific `order` firebase page
  func makeSubscriptionOnCurrentOrder() {
    guard let orderId = self.store.value.order?.id else { return }
    firestoreSubscriptions.removeAll()
    firestoreSubscriptions += [
      makeCurrentOrderSubscription(db, orderId) { [weak self] result in
        guard let self = self else { return }
        switch result {
          case let .success(order):
            print("makeSubscriptionOnCurrentOrder - \(order)")
            if let status = ViewName.RiderHomeState(
              rawValue: order.status.toInt()
            ) {
              if order.status.toInt() == ViewName.RiderHomeState.ACCEPTED.rawValue ||
                order.status.toInt() == ViewName.RiderHomeState.STARTED_RIDE.rawValue {
                return
              }

              if order.status.toInt() == ViewName.RiderHomeState.CANCELLED.rawValue {
                self.removeAllData()
                print("CANCEL ORDER")
                return
              }

              let currentTripId = self.store.value.order?.trip_id ?? ""
              let incomingTripId = order.trip_id

              if currentTripId != incomingTripId {
                self.store.value.order = order
                self.store.update(.home(.rider(status)))
                return
              }

              if status.rawValue == self.store.value.order?.status.toInt() {
                return
              }

              if order.status.toInt() == ViewName.RiderHomeState.COMPLETED.rawValue {
                self.store.value.order = order
                return
              }

              self.store.value.order = order
              self.store.update(.home(.rider(status)))
            }
          case let .failure(error):
            print("Create order | error: \(error)")
        }
      }
    ]
  }

  /// Create trip share link
  func getCurrentShareLink() -> String? {
    let tripID = store.value.order?.trip_id
    if let trip = self.userMovementStatus?.trips.first(
      where: { $0.id == tripID }
    ) {
      return trip.views.shareURL.absoluteString
    } else {
      return nil
    }
  }

  /// Create subscription to provide movementStatus updates for MapView
  func createUserMovementStatusSubscription() {
    cancelViewsSubscription.removeAll()
    guard let deviceId = self.store.value.order?.driver?.device_id
      else { return }
    cancelViewsSubscription = [
      hyperTrackViews.subscribeToMovementStatusUpdates(
        for: deviceId, completionHandler: { [weak self] result in
          guard let self = self else { return }
          switch result {
            case let .success(mStatus):
              dump(mStatus)
              self.movementStatusWillChange.send(mStatus)
              self.getTripSummary()
            case let .failure(error):
              self.createUserMovementStatusSubscription()
              dump(error)
          }
        }
      )
    ]
  }

  /// Getting trip summary
  func getTripSummary() {
    guard let order = self.store.value.order else { return }
    guard let tripID = self.store.value.order?.trip_id else { return }
    _ = hyperTrackViews.trip(tripID) { [weak self] result in
      guard let self = self else { return }
      switch result {
        case let .success(trip):
          if let _ = trip.summary,
            order.status == .COMPLETED {
            self.tripSummary = trip
            self.store.update(.home(.rider(.COMPLETED)))
            self.firestoreSubscriptions.forEach { $0.remove() }
            self.firestoreSubscriptions.removeAll()
          }
          dump(trip)
        case let .failure(error):
          dump(error)
      }
    }
  }

  /// Change order status to canceled
  func cancelOrder() {
    guard let order = self.store.value.order else { return }
    updateOrderStatusOnFireStore(db, order: updateOrder(order, .CANCELLED)) { [
      weak self
    ] _ in
    guard let self = self else { return }
    self.removeAllData()
    }
  }

  /// Removed all stored data
  func removeAllData() {
    firestoreSubscriptions.forEach { $0.remove() }
    firestoreSubscriptions.removeAll()
    cancelViewsSubscription.removeAll()

    userMovementStatus = nil
    store.value.order = nil

    store.update(.home(.rider(.LOOKING_FOR_RIDES)))
  }
}
