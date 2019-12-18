import CommonModels
import class Firebase.DocumentReference
import class Firebase.Firestore
import protocol Firebase.ListenerRegistration
import Foundation
import SwiftUI

/// firestore pages
private let users = "users"
private let orders = "orders"

/// Callback for user
public typealias UserCompletionHandler = (Result<User, Error>) -> Void
public typealias UserListCompletionHandler = (Result<[User], Error>) -> Void

/// Callback for order
public typealias OrdersCompletionHandler = (Result<[Order], Error>) -> Void
public typealias OrderCompletionHandler = (Result<Order, Error>) -> Void

/// List of errors for firebase operations
public enum FirebaseCustomError: Error {
  /// Empty order id error, can happen while working with orders
  case emptyOrderID
  case emptyOrder
  case mappingError
}

/// Create new user on firestore `users` page
public func setNewFirestoreUser(
  _ db: Firestore,
  _ user: User,
  completionHandler: @escaping UserCompletionHandler
) {
  guard var uObject = try? user.asDictionary() else { return }
  uObject.removeValue(forKey: "id")
  var ref: DocumentReference?
  ref = db.collection(users).addDocument(data: uObject) { error in
    if let error = error {
      print("Error adding document: \(error)")
      completionHandler(.failure(error))
    } else {
      print("Document added with ID: \(ref!.documentID)")
      completionHandler(.success(
        User(
          id: ref!.documentID,
          role: user.role,
          name: user.name,
          phone_number: user.phone_number,
          device_id: user.device_id ?? "",
          car: user.car
        )))
    }
  }
}

/// Get all orders from  firestore`orders` page
public func getUserListFromFirestore(
  _ db: Firestore,
  completionHandler: @escaping UserListCompletionHandler
) {
  db.collection(users).getDocuments { ordersSnapshot, error in
    if let error = error {
      print("Error getting documents: \(error)")
      completionHandler(.failure(error))
    } else {
      guard let FSUsers = ordersSnapshot?.documents else { return completionHandler(.success([
      ])) }
      var userList: [User] = []
      for document in FSUsers {
        if let user = makeUserFromFirestore(
          fsUser: document.data(),
          userId: document.documentID
        ) {
          userList.append(user)
        }
      }
      completionHandler(.success(userList))
    }
  }
}

/// Get all orders from  firestore`orders` page
public func getOrdersFromFirestore(
  _ db: Firestore,
  completionHandler: @escaping OrdersCompletionHandler
) {
  db.collection(orders).getDocuments { ordersSnapshot, error in
    if let error = error {
      print("Error getting documents: \(error)")
      completionHandler(.failure(error))
    } else {
      guard let FSOrders = ordersSnapshot?.documents else { return completionHandler(.success([
      ])) }
      var orderList: [Order] = []
      for document in FSOrders {
        if let order = makeOrderFromFirestore(
          fsOrder: document.data(),
          orderId: document.documentID
        ) {
          orderList.append(order)
        }
      }
      completionHandler(.success(orderList))
    }
  }
}

/// Create subscription on firestore`orders` page
/// when some orders was added or modified `OrdersCompletionHandler` will be called
public func makeOrdersSubscription(
  _ db: Firestore,
  completionHandler: @escaping OrdersCompletionHandler
) -> ListenerRegistration {
  return db.collection(orders).addSnapshotListener { ordersSnapshot, error in
    if let error = error {
      completionHandler(.failure(error))
    } else {
      guard let FSOrders = ordersSnapshot?.documents else { return completionHandler(.success([
      ])) }
      var orderList: [Order] = []
      for document in FSOrders {
        if let order = makeOrderFromFirestore(
          fsOrder: document.data(),
          orderId: document.documentID
        ) {
          orderList.append(order)
        }
      }
      completionHandler(.success(orderList))
    }
  }
}

/// Create subscription on firestore current`order`
/// when some orders was added or modified `OrdersCompletionHandler` will be called
public func makeCurrentOrderSubscription(
  _ db: Firestore,
  _ orderId: String,
  completionHandler: @escaping OrderCompletionHandler
) -> ListenerRegistration {
  return db.collection(orders).document(orderId).addSnapshotListener(
    includeMetadataChanges: true
  ) { orderSnapshot, error in
    if let error = error {
      completionHandler(.failure(error))
    } else {
      guard let order = orderSnapshot, let orderData = order.data() else { completionHandler(.failure(FirebaseCustomError.emptyOrder))
        return
      }
      guard let model = makeOrderFromFirestore(
        fsOrder: orderData,
        orderId: order.documentID
      ) else { completionHandler(.failure(FirebaseCustomError.mappingError))
        return
      }
      completionHandler(.success(model))
    }
  }
}

/// Update order status with `order` and new `status`
public func updateOrderOnFireStore(
  _ db: Firestore,
  order: Order,
  completionHandler: @escaping OrderCompletionHandler
) {
  guard let id = order.id, let car = try? order.driver.asDictionary() else {
    completionHandler(.failure(FirebaseCustomError.emptyOrderID))
    return
  }
  db.collection(orders).document(id).updateData([
    "status": "\(order.status)",
    "driver": car
  ]) { error in
    if let error = error {
      completionHandler(.failure(error))
    } else {
      completionHandler(.success(updateOrder(
        order,
        order.status,
        order.driver ?? nil
      )))
    }
  }
}

/// Update order status with `order` and new `status`
public func updateOrderStatusOnFireStore(
  _ db: Firestore,
  order: Order,
  completionHandler: @escaping OrderCompletionHandler
) {
  guard let id = order.id else {
    completionHandler(.failure(FirebaseCustomError.emptyOrderID))
    return
  }
  db.collection(orders).document(id).updateData([
    "status": "\(order.status)"
  ]) { error in
    if let error = error {
      completionHandler(.failure(error))
    } else {
      completionHandler(.success(updateOrder(
        order,
        order.status,
        order.driver ?? nil
      )))
    }
  }
}

public func setNewFirestoreOrder(
  _ db: Firestore,
  _ order: Order,
  completionHandler: @escaping OrderCompletionHandler
) {
  guard var uObject = try? order.asDictionary() else { return }
  uObject.removeValue(forKey: "id")
  var ref: DocumentReference?
  ref = db.collection(orders).addDocument(data: uObject) { error in
    if let error = error {
      print("Error adding document: \(error)")
      completionHandler(.failure(error))
    } else {
      print("Document added with ID: \(ref!.documentID)")
      completionHandler(.success(
        Order(
          id: ref!.documentID,
          status: order.status,
          rider: order.rider,
          pickup: order.pickup,
          dropoff: order.dropoff,
          created_at: order.created_at,
          driver: order.driver,
          trip_id: order.trip_id,
          updated_at: order.updated_at
        )))
    }
  }
}
