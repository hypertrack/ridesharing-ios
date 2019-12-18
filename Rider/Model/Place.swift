import CommonModels
import Foundation
import SwiftUI

/// Extension that provides Identifiable protocol for ForEach SwiftUI interface function
extension Order.Place: Identifiable {
  public var id: String {
    return UUID().uuidString
  }
}
