import CommonModels
import Foundation
import HyperTrackViews
import SwiftUI
import Utility

/// Key for saving last view state
public let saveStateDefaultFileName = "viewstate.json"
/// Key for saving current user model
public let saveUserDefaultFileName = "user.json"
/// Key for saving accepted order model
public let saveOrderDefaultFileName = "order.json"

public final class Store<Value, Action>: ObservableObject {
  private let reducer: (inout Value, Action) -> Void
  @Published public private(set) var value: Value

  public init(
    initialValue: Value,
    reducer: @escaping (inout Value, Action) -> Void
  ) {
    self.reducer = reducer
    value = initialValue
  }

  public func update(_ action: Action) {
    reducer(&value, action)
  }
}

/// AppState object provide state of `order`, `user`, `lastView`
public final class AppState {
  public init() {}

  /// Stores an object that contains accepted order by driver
  public var order: Order? {
    get {
      if let last: Order = loadObject(for: saveOrderDefaultFileName) {
        return last
      } else {
        return nil
      }
    }
    set { save(object: newValue, for: saveOrderDefaultFileName) }
  }

  /// Stores an object that contains user model
  public var user: User? {
    get {
      if let last: User = loadObject(for: saveUserDefaultFileName) {
        return last
      } else {
        return nil
      }
    }
    set { save(object: newValue, for: saveUserDefaultFileName) }
  }

  /// Stores an enum that contains last ViewName
  public var lastView: ViewName? {
    get {
      if let last: ViewName = loadObject(for: saveStateDefaultFileName) {
        return last
      } else {
        return nil
      }
    }
    set { save(object: newValue, for: saveStateDefaultFileName) }
  }
}

/// applied new state at lastView
public func appReducer(_ state: inout AppState, newState: ViewName) {
  state.lastView = newState
}
