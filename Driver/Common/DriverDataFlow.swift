import AppState
import Combine
import CommonModels
import protocol Firebase.ListenerRegistration
import HyperTrack
import HyperTrackViews
import SwiftUI
import Utility

private let saveCancelledOrderDefaultFileName = "CancelledOrderFile"

final class DriverDataFlow: ObservableObject {
  /// Cancelled by user object list
  private var cancelledOrderList: [Order] {
    get {
      if let cancelOrders: [Order] = loadObject(
        for: saveCancelledOrderDefaultFileName
      ) {
        return cancelOrders
      } else {
        return []
      }
    }
    set { save(object: newValue, for: saveCancelledOrderDefaultFileName) }
  }

  /// Array of Firestore listeners
  private var firestoreSubscriptions: [ListenerRegistration] = []
  /// HyperTrack Views SDK subscription cancel function
  private var cancelViewsSubscription: Cancel?
  /// Array of subscribers
  private var cancellables: [AnyCancellable] = []
  /// HyperTrack SDK instance
  private let hypertrack: HyperTrack
  /// HyperTrack Views SDK instance
  private let hyperTrackViews = HyperTrackViews(
    publishableKey: publishableKey
  )

  /// Store object for AppState
  let store: Store<AppState, ViewName>
  /// Subject that provides updates from MKMapView delegate
  /// `func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)`
  let selectedOrderWillChange: PassthroughSubject<
    Order?,
    Never
  > = PassthroughSubject<
    Order?,
    Never
  >()
  /// Subject that provides accepted order by user updates
  let acceptedOrderWillChange: PassthroughSubject<
    Order?,
    Never
  > = PassthroughSubject<
    Order?,
    Never
  >()
  /// Subject that provide updates for movement status from HyperTrackViews SDK
  let movementStatusWillChange: PassthroughSubject<
    MovementStatus?,
    Never
  > = PassthroughSubject<
    MovementStatus?,
    Never
  >()
  /// Subject that provide updates for cancel order
  let cancelOrderSubject: PassthroughSubject<Void, Never> = PassthroughSubject<
    Void,
    Never
  >()

  /// All Order object list from Firestore page `orders`
  @Published var orderList: [Order] = []
  /// Sorted array that contains only new created orders on Firestore
  @Published var newCreatedOrderList: [Order] = []
  /// User movement status
  @Published var userMovementStatus: MovementStatus? = nil
  /// Main screen bottom view status
  @Published var driverHomeState: ViewName.DriverHomeState = .NEW
  /// Trip summary
  @Published var tripSummary: MovementStatus.Trip?

  /// Accepted order variable
  var acceptedOrder: Order? {
    willSet { acceptedOrderWillChange.send(newValue) }
  }

  /// Selected order variable
  var selectedOrder: Order? {
    willSet { selectedOrderWillChange.send(newValue) }
  }

  /// Object initializer
  init(store: Store<AppState, ViewName>, hypertrack: HyperTrack) {
    self.store = store
    self.hypertrack = hypertrack
    acceptedOrder = store.value.order
    bindOutputs()
    createAcceptedOrderSubscription()

    if let order = store.value.order,
      let status = ViewName.DriverHomeState(
        rawValue: order.status.toInt()
      ) {
      driverHomeState = status
    }
  }

  /// Binding movementstatus updates
  private func bindOutputs() {
    let movementStatusStream = movementStatusWillChange
      .map { movementStatus -> MovementStatus? in movementStatus }
      .assign(to: \.userMovementStatus, on: self)
    let cancelStream = cancelOrderSubject
      .sink {
        self.cancelOrder()
      }
    cancellables = [
      cancelStream,
      movementStatusStream
    ]
  }

  /// Create subscription to provide movementStatus updates for MapView
  func createUserMovementStatusSubscription() {
    cancelViewsSubscription =
      hyperTrackViews.subscribeToMovementStatusUpdates(
        for: hypertrack.deviceID,
        completionHandler: { [weak self] result in
          guard let self = self else { return }
          switch result {
            case let .success(movementStatus):
              self.movementStatusWillChange.send(movementStatus)
              if let order = self.store.value.order,
                order.status == .COMPLETED {
                self.getTripSummary()
              }
            case let .failure(error):
              dump(error)
              self.createUserMovementStatusSubscription()
          }
        }
      )
  }

  func getTripSummary() {
    guard let trip_id = self.store.value.order?.trip_id else { return }
    _ = hyperTrackViews.trip(trip_id) { [weak self] result in
      guard let self = self else { return }
      switch result {
        case let .success(trip):
          if let _ = trip.summary {
            self.tripSummary = trip
            self.driverHomeState = .COMPLETED
          }
        case let .failure(error):
          dump(error)
      }
    }
  }

  /// For user action, remove object from new orders list
  func removeNewOrderds(by id: String) {
    let removeObjectIndex = newCreatedOrderList.firstIndex { $0.id == id }
    guard let index = removeObjectIndex else { return }
    cancelledOrderList.append(newCreatedOrderList[index])
    newCreatedOrderList.remove(at: index)
  }

  /// Remove all stored data
  func removeAllData() {
    newCreatedOrderList.removeAll()
    firestoreSubscriptions.forEach { $0.remove() }
    firestoreSubscriptions.removeAll()
    orderList.removeAll()

    userMovementStatus = nil
    acceptedOrder = nil
    selectedOrder = nil
    store.value.order = nil

    store.update(.home(.driver(.NEW)))
    update(state: store.value.lastView?.getDriverValue() ?? .NEW)
    driverHomeState = .NEW
  }

  /// Update home view state
  func update(state: ViewName.DriverHomeState) {
    switch state {
      case ViewName.DriverHomeState.NEW:
        getOrders()
      case ViewName.DriverHomeState.REACHED_PICKUP:
        driverHomeState = .REACHED_PICKUP
      case ViewName.DriverHomeState.REACHED_DROPOFF:
        driverHomeState = .REACHED_DROPOFF
      case ViewName.DriverHomeState.COMPLETED:
        getTripSummary()
        firestoreSubscriptions.forEach { $0.remove() }
        firestoreSubscriptions.removeAll()
      case ViewName.DriverHomeState.CANCELLED:
        removeAllData()
      default:
        break
    }
  }
}

// MARK: - Firestore

extension DriverDataFlow {
  /// Accepted selected Order object
  func acceptOredr() {
    guard let order = self.selectedOrder else { return }
    firestoreSubscriptions.forEach { $0.remove() }
    firestoreSubscriptions.removeAll()
    updateOrderOnFireStore(
      db,
      order: updateOrder(order, .ACCEPTED, store.value.user)
    ) { [weak self] result in
      guard let self = self else { return }
      switch result {
        case let .success(order):
          self.acceptedOrder = order
          self.createAcceptedOrderSubscription()
          self.driverHomeState = .PICKING_UP
        case let .failure(error):
          print("acceptOredr | error: \(error)")
      }
    }
  }

  /// Get all orders
  private func getOrders() {
    firestoreSubscriptions.forEach { $0.remove() }
    firestoreSubscriptions.removeAll()
    getOrdersFromFirestore(db) { [weak self] snapshot in
      guard let self = self else { return }
      if let orders = try? snapshot.get() {
        self.orderList = orders.filter { $0.status == .NEW }
        let newOrders = self.orderList.filter { DateFormatter.iso8601Full.date(
          from: $0.created_at
        )! >= Date().addingTimeInterval(-160.0)
        }
        print("newOrders - \(newOrders)")
        if !self.cancelledOrderList.isEmpty {
          let filteredNewOrders = newOrders.filter { orderItem in self.cancelledOrderList.contains { _ in self.cancelledOrderList.first(
            where: { $0.id == orderItem.id }
          ) == nil
          } }
          self.newCreatedOrderList = filteredNewOrders
        } else {
          self.newCreatedOrderList = newOrders
        }
        self.firestoreSubscriptions = [
          makeOrdersSubscription(db, completionHandler: { snapshot in
            switch snapshot {
              case let .success(orders):
                /// Remove all order with status not .NEW
                orders.forEach { order in
                  self.newCreatedOrderList.removeAll { ($0.id == order.id && order.status != .NEW) }
                  self.orderList.removeAll { ($0.id == order.id && order.status != .NEW) }
                }
                /// Filter orders by status .NEW
                let updatedOrderList: [Order] = orders.filter { $0.status == .NEW }
                let newOrders = updatedOrderList.filter { orderItem in self
                  .orderList.contains { _ in self.orderList
                    .first(where: { $0.id == orderItem.id }) == nil
                  }
                }
                if !self.orderList.isEmpty {
                  newOrders.forEach { self.newCreatedOrderList.insert($0, at: 0) }
                } else {
                  updatedOrderList.forEach { self.newCreatedOrderList.insert(
                    $0,
                    at: 0
                  ) }
                }
                self.orderList = updatedOrderList
              case let .failure(error):
                print(error)
            }
          })
        ]
      }
    }
  }

  /// Change status to DROPPING_OFF
  func droppingOffOrder() {
    guard let order = self.acceptedOrder else { return }
    updateOrderStatusOnFireStore(db, order: updateOrder(order, .STARTED_RIDE)) { [
      weak self
    ] _ in
    guard let self = self else { return }
    self.driverHomeState = .DROPPING_OFF
    }
  }

  /// Change status to REACHED_DROPOFF
  func reachedDropOffOrder() {
    guard let order = self.acceptedOrder else { return }
    updateOrderStatusOnFireStore(
      db,
      order: updateOrder(order, .REACHED_DROPOFF)
    ) { _ in }
  }

  /// Change status to COMPLETED
  func completedOrder() {
    guard let order = self.acceptedOrder else { return }
    updateOrderStatusOnFireStore(db, order: updateOrder(order, .COMPLETED)) { _ in
    }
  }

  /// Create subscription to provide order updates
  func createAcceptedOrderSubscription() {
    guard let orderId = self.acceptedOrder?.id else { return }
    firestoreSubscriptions.removeAll()
    firestoreSubscriptions = [
      makeCurrentOrderSubscription(db, orderId, completionHandler: { [weak self] result in
        guard let self = self else { return }
        switch result {
          case let .success(order):
            if let status = ViewName.DriverHomeState(
              rawValue: order.status.toInt()
            ) {
              self.update(state: status)
              self.store.update(.home(.driver(status)))
              self.store.value.order = order
              self.acceptedOrder = order
            }
          case let .failure(error):
            dump(error)
        }
      })
    ]
  }

  /// Change order status to cancel
  func cancelOrder() {
    guard let order = self.store.value.order else { return }
    updateOrderStatusOnFireStore(db, order: updateOrder(order, .CANCELLED)) { [
      weak self
    ] _ in
    guard let self = self else { return }
    self.removeAllData()
    }
  }
}
