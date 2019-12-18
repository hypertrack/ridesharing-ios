import CommonExtensions
import CoreLocation
import Foundation

/// Order that describes the trip
public struct Order: Codable, Identifiable {
  /// uniqum order identifier that provide from cloudstore
  public var id: String?
  /// Order status
  public let status: Status
  /// Order rider model
  public let rider: User
  /// Object that provide place we were need rider pickup
  public let pickup: Place
  /// Object that provide place we were need rider drop off
  public let dropoff: Place
  /// Time when order was created
  public let created_at: String
  /// Driver object that provide driver which accepted order
  public var driver: User?
  /// hypertrack trip identifier
  public var trip_id: String?
  /// updated order time
  public var updated_at: String?

  /// Order status
  public enum Status: String, Codable {
    /// Status for all created and available orders
    case NEW
    /// Status for processing trip creation
    case ACCEPTED
    /// Status for accepted order (by driver)
    case PICKING_UP
    /// Status when driver ready on spot (by driver) when arrived_at is available
    case REACHED_PICKUP
    /// Status for  when driver push START trip (by driver)
    case DROPPING_OFF
    /// Status for processing trip creation
    case STARTED_RIDE
    /// Status for  when
    case REACHED_DROPOFF
    /// Status for  showing summary
    case COMPLETED
    /// Status when order was cancelled
    case CANCELLED
  }

  /// Order place stuct
  public struct Place: Codable {
    public let latitude: Float
    public let longitude: Float
    public let address: String

    public init(latitude: Float, longitude: Float, address: String) {
      self.latitude = latitude
      self.longitude = longitude
      self.address = address
    }
  }

  public init(
    id: String?,
    status: Status,
    rider: User,
    pickup: Place,
    dropoff: Place,
    created_at: String,
    driver: User?,
    trip_id: String?,
    updated_at: String?
  ) {
    self.id = id
    self.status = status
    self.rider = rider
    self.pickup = pickup
    self.dropoff = dropoff
    self.created_at = created_at
    self.driver = driver
    self.trip_id = trip_id
    self.updated_at = updated_at
  }
}

extension Order {
  public func getCreatedTime() -> String {
    return DateFormatter.iso8601Full.date(from: created_at)?.timeAgoSinceDate() ?? ""
  }
}

extension Order: Equatable {
  public static func == (lhs: Order, rhs: Order) -> Bool {
    return
      (lhs.status == rhs.status &&
        lhs.rider == rhs.rider &&
        lhs.pickup == rhs.pickup &&
        lhs.dropoff == rhs.dropoff &&
        lhs.created_at == rhs.created_at &&
        lhs.driver == rhs.driver &&
        lhs.trip_id == rhs.trip_id &&
        lhs.id == rhs.id)
  }
}

extension Order.Place: Equatable {
  public static func == (lhs: Order.Place, rhs: Order.Place) -> Bool {
    return
      (lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.address == rhs.address)
  }
}

extension Order.Status {
  public func toInt() -> Int {
    switch self {
      case .NEW: return 0
      case .PICKING_UP: return 1
      case .REACHED_PICKUP: return 2
      case .DROPPING_OFF: return 3
      case .REACHED_DROPOFF: return 4
      case .COMPLETED: return 5
      case .CANCELLED: return 6
      case .ACCEPTED: return 7
      case .STARTED_RIDE: return 8
    }
  }
}

/// Create order from firebase responce
public func makeOrderFromFirestore(fsOrder: [String: Any], orderId: String) -> Order? {
  do {
    let data = try JSONSerialization.data(
      withJSONObject: fsOrder,
      options: .prettyPrinted
    )
    var model: Order = try JSONDecoder().decode(Order.self, from: data)
    model.id = orderId
    return model
  } catch {
    print(error)
    return nil
  }
}

/// Update current order with new status
/// #return Order
public func updateOrder(
  _ order: Order,
  _ status: Order.Status,
  _ driver: User? = nil
) -> Order {
  return Order(
    id: order.id,
    status: status,
    rider: order.rider,
    pickup: order.pickup,
    dropoff: order.dropoff,
    created_at: order.created_at,
    driver: driver == nil ? order.driver : driver,
    trip_id: order.trip_id,
    updated_at: order.updated_at
  )
}
