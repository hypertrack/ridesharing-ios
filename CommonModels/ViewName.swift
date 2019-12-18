import Foundation

/// enum of name of views
public enum ViewName: Codable, Equatable {
  /// LoginView
  case login
  /// AuthView
  case auth
  /// PermissionsView
  case permissions
  /// HomeView
  case home(HomeState)
  /// ErrorView
  case error

  public enum HomeState: Codable, Equatable {
    case rider(RiderHomeState)
    case driver(DriverHomeState)

    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      if let valStruct = try? values.decode(OneValue<Int>.self, forKey: .rider),
        let state = RiderHomeState(rawValue: valStruct.value) {
        self = .rider(state)
        return
      } else if let valStruct = try? values.decode(
        OneValue<Int>.self,
        forKey: .driver
      ),
        let state = DriverHomeState(rawValue: valStruct.value) {
        self = .driver(state)
        return
      } else {
        fatalError()
      }
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
        case let .rider(state): try container.encode(
        OneValue(value: state),
          forKey: .rider
        )
        case let .driver(state): try container.encode(
        OneValue(value: state),
          forKey: .driver
        )
      }
    }

    public enum CodingKeys: CodingKey {
      case rider, driver
    }
  }

  public enum RiderHomeState: Int, Codable {
    case LOOKING_FOR_RIDES = -1
    case LOOKING_DRIVER = 0
    case PICKING_UP
    case REACHED_PICKUP
    case DROPPING_OFF
    case REACHED_DROPOFF
    case COMPLETED
    case CANCELLED
    case ACCEPTED
    case STARTED_RIDE
  }

  /// enum of possible state HomeView
  public enum DriverHomeState: Int, Codable {
    /// Status for all created and available orders
    case NEW
    /// Status for accepted order (by driver)
    case PICKING_UP
    /// Status when driver ready on spot (by driver) when arrived_at is available
    case REACHED_PICKUP
    /// Status for  when driver push START trip (by driver)
    case DROPPING_OFF
    /// Status for  when
    case REACHED_DROPOFF
    /// Status for  showing summary
    case COMPLETED
    /// Status when order was cancelled
    case CANCELLED
  }

  /// For saving enum associated type
  public struct OneValue<T: Codable>: Codable { let value: T }

  public enum CodingKeys: CodingKey {
    case login, auth, permissions, home, error
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    if let _ = try? values.decode(Bool.self, forKey: .login) {
      self = .login
      return
    } else if let _ = try? values.decode(Bool.self, forKey: .auth) {
      self = .auth
      return
    } else if let _ = try? values.decode(Bool.self, forKey: .permissions) {
      self = .permissions
      return
    } else if let state = try? values.decode(HomeState.self, forKey: .home) {
      self = .home(state)
      return
    } else if let _ = try? values.decode(Bool.self, forKey: .error) {
      self = .error
      return
    } else {
      self = .login
      return
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
      case .login: try container.encode(true, forKey: .login)
      case .auth: try container.encode(true, forKey: .auth)
      case .permissions: try container.encode(true, forKey: .permissions)
      case let .home(state): try container.encode(state, forKey: .home)
      case .error: try container.encode(true, forKey: .error)
    }
  }

  public static func == (lhs: ViewName, rhs: ViewName) -> Bool {
    switch (lhs, rhs) {
      case (.login, .login): return true
      case (.auth, .auth): return true
      case (.permissions, .permissions): return true
      case (.home(_), .home(_)): return true
      case (.error, .error): return true
      default: return false
    }
  }

  public func getDriverValue() -> DriverHomeState {
    switch self {
      case let .home(state):
        switch state {
          case let .driver(driverState):
            return driverState
          default:
            return .NEW
        }
      default:
        return .NEW
    }
  }

  public func getRiderValue() -> RiderHomeState {
    switch self {
      case let .home(state):
        switch state {
          case let .rider(riderState):
            return riderState
          default:
            return .LOOKING_FOR_RIDES
        }
      default:
        return .LOOKING_FOR_RIDES
    }
  }
}
