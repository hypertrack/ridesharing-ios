import CommonModels
import CoreLocation
import Foundation
import MapKit

public class OrderAnnotation: NSObject, MKAnnotation {
  public var title: String?
  public var coordinate: CLLocationCoordinate2D
  public var order: Order
  public var iconName: String

  public init(order: Order) {
    coordinate = CLLocationCoordinate2D(
      latitude: Double(order.pickup.latitude),
      longitude: Double(order.pickup.longitude)
    )
    iconName = "order_pin_icon"
    self.order = order
  }
}
