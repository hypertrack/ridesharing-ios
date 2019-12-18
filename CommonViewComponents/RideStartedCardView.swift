import Combine
import SwiftUI
import Utility

public struct RideStartedCardView: View {
  private let isCancelButtinEnabled: Bool
  var cancel: PassthroughSubject<Void, Never>

  private let cardAvatar: String
  private let cardName: String
  private let cardRating: String
  private let cardAddress: String

  public init(
    isCancelButtinEnabled: Bool = false,
    cardAvatar: String,
    cardName: String,
    cardRating: String,
    cardAddress: String,
    cancel: PassthroughSubject<Void, Never>
  ) {
    self.isCancelButtinEnabled = isCancelButtinEnabled
    self.cardAvatar = cardAvatar
    self.cardName = cardName
    self.cardRating = cardRating
    self.cardAddress = cardAddress
    self.cancel = cancel
  }

  public var body: some View {
    VStack {
      VStack {
        if isCancelButtinEnabled {
          HStack {
            Text("DROPOFF")
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding([.leading, .trailing, .top])
              .font(.system(size: 12))
              .foregroundColor(Color.gray)
            Button(action: {
              self.cancel.send()
            }) {
              Image("close_icon")
                .resizable()
                .frame(width: 15, height: 15)
            }
            .frame(width: 30, height: 30)
            .background(Color.black)
            .foregroundColor(Color.white)
            .clipped()
            .cornerRadius(15)
            .padding([.trailing, .top], 5)
          }
        }
        Spacer()
          .frame(height: 5)
        Text(self.cardAddress)
          .bold()
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding([.leading, .trailing])
        HStack {
          Image(self.cardAvatar)
          Text(self.cardName)
          Spacer()
          Text(self.cardRating)
        }
        .padding([.leading, .trailing, .top])
        Spacer()
          .frame(height: 40)
      }
      Spacer()
    }
    .frame(width: UIScreen.main.bounds.width - 34, height: screenPadding(185))
    .clipped()
    .background(Color.white)
    .cornerRadius(15)
    .shadow(radius: 5)
  }
}
