import CommonModels
import SwiftUI

struct OrderRow: View {
  /// Order model
  var order: Order
  /// Delate action
  var onDelete: (String?) -> Void
  /// Accept action
  var onAccept: (String?) -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack {
          Text("NEW ORDER")
            .padding(.top, 14)
            .padding(.leading, 15)
            .font(.system(size: 12))
            .foregroundColor(Color.white)
          Spacer()
          Text(order.getCreatedTime())
            .padding(.top, 14)
            .padding(.trailing, 15)
            .font(.system(size: 12))
            .foregroundColor(Color.white)
        }.frame(height: 40.0)
        Text("\(order.pickup.address)")
          .frame(height: 40.0)
          .font(.system(size: 12))
          .foregroundColor(Color.white)
          .padding(.bottom, 14)
          .padding(.leading, 15)
          .padding(.trailing, 15)
      }
      .frame(height: 80)
      .background(Color.black)
      .cornerRadius(14.0)
      .onTapGesture {
        self.onAccept(self.order.id)
      }
      Spacer()
        .frame(width: 10)
      Button(action: {
        self.onDelete(self.order.id)
      }) {
        Image("close_icon")
      }
      .frame(width: 80, height: 80)
      .background(Color.black)
      .foregroundColor(Color.white)
      .cornerRadius(14.0)
    }
    .background(Color.clear)
  }
}
