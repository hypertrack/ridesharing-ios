import SwiftUI
import Utility

public struct SummaryCardView: View {
  public var distance: String
  public var rideTime: String
  public var name: String
  public var price: String

  public init(
    distance: String,
    rideTime: String,
    name: String,
    price: String
  ) {
    self.distance = distance
    self.rideTime = rideTime
    self.name = name
    self.price = price
  }

  public var body: some View {
    return HStack {
      Spacer()
      VStack(alignment: .custom, spacing: 0) {
        HStack {
          Text("Fare")
            .font(.system(size: 26))
            .fontWeight(.semibold)
          Rectangle()
            .fill(Color.black)
            .alignmentGuide(.custom) { d in d[.top] }
            .frame(width: 3, height: 25)
            .padding([.top, .bottom])
          Text("$\(self.price)")
            .font(.system(size: 26))
            .fontWeight(.semibold)
        }
        .frame(width: UIScreen.main.bounds.width - 34)
        HStack {
          Image("checkmark")
          Text("Paid by Wallet")
            .font(.system(size: 13))
            .fontWeight(.semibold)
            .foregroundColor(Color.green)
        }
        .frame(width: UIScreen.main.bounds.width - 34)
        HStack {
          VStack(alignment: .trailing) {
            Text("DISTANCE").modifier(PrimaryLabel())
            Text("\(self.distance) miles").modifier(SecondaryLabel())
          }
          Divider()
            .modifier(CenteredDivider())
          VStack(alignment: .leading) {
            Text("RIDE TIME").modifier(PrimaryLabel())
            Text("\(self.rideTime)").modifier(SecondaryLabel())
          }
        }
        .frame(width: UIScreen.main.bounds.width - 34)
        HStack {
          VStack(alignment: .trailing) {
            Text("CATEGORY").modifier(PrimaryLabel())
            Text("Premium").modifier(SecondaryLabel())
          }
          Divider()
            .modifier(CenteredDivider())
          VStack(alignment: .leading) {
            Text("NAME").modifier(PrimaryLabel())
            Text("\(self.name)").modifier(SecondaryLabel())
          }
        }
        .frame(width: UIScreen.main.bounds.width - 34)
        Spacer()
          .frame(height: 20)
          .padding(.bottom, 20)
      }
      Spacer()
    }
    .frame(width: UIScreen.main.bounds.width - 34, height: screenPadding(250))
    .clipped()
    .background(Color.white)
    .cornerRadius(15)
    .shadow(radius: 5)
  }
}
