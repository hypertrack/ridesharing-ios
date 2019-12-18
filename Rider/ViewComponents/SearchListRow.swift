import MapKit
import SwiftUI
import Utility

struct SearchListRow: View {
  /// Row order model
  var order: MKLocalSearchCompletion
  /// Tap action for search address
  var action: (MKLocalSearchCompletion) -> Void

  var body: some View {
    HStack {
      Image("place_icon")
      VStack(alignment: .leading) {
        Text(order.title)
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "47556C"))
        Text(order.subtitle)
          .font(.system(size: 12))
          .foregroundColor(Color.gray)
      }
    }
    .frame(height: 56)
    .background(Color.white)
    .onTapGesture {
      self.action(self.order)
    }
  }
}
