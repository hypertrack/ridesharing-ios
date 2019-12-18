import Foundation

/// Model for user
public struct User: Codable {
  /// unique identifier from Firestore sdk
  public var id: String?
  /// User role depends on uber-for-x application type
  public let role: Role
  /// User name
  public let name: String
  /// User phone number
  public let phone_number: String?
  /// unique device identifier from hypertrack sdk
  public let device_id: String?
  /// car object that contains information about driver car
  public let car: Car?

  /// User role enum
  public enum Role: String, Codable {
    case driver
    case rider
  }

  /// User car object
  public struct Car: Codable {
    /// car model
    public let model: String
    /// car license number plate
    public let license_plate: String

    public init(model: String, license_plate: String) {
      self.model = model
      self.license_plate = license_plate
    }
  }

  public init(
    id: String?,
    role: Role,
    name: String,
    phone_number: String?,
    device_id: String?,
    car: Car?
  ) {
    self.id = id
    self.role = role
    self.name = name
    self.phone_number = phone_number
    self.device_id = device_id
    self.car = car
  }
}

extension User: Equatable {
  public static func == (lhs: User, rhs: User) -> Bool {
    return
      (lhs.role == rhs.role &&
        lhs.name == rhs.name &&
        lhs.phone_number == rhs.phone_number &&
        lhs.car == rhs.car &&
        lhs.id == rhs.id)
  }
}

extension User.Car: Equatable {
  public static func == (lhs: User.Car, rhs: User.Car) -> Bool {
    return
      (lhs.model == rhs.model &&
        lhs.license_plate == rhs.license_plate)
  }
}

/// Create user from firebase responce
public func makeUserFromFirestore(fsUser: [String: Any], userId: String) -> User? {
  do {
    let data = try JSONSerialization.data(
      withJSONObject: fsUser,
      options: .prettyPrinted
    )
    var model: User = try JSONDecoder().decode(User.self, from: data)
    model.id = userId
    return model
  } catch {
    print(error)
    return nil
  }
}
