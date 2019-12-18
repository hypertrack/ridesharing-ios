import Combine
import SwiftUI
import Utility

public struct TripCardView: View {
  private let isCancelButtinEnabled: Bool
  var cancel: PassthroughSubject<Void, Never>

  private let cardAvatar: String
  private let cardTitle: String
  private let cardSubTitle: String

  private let cardButtonIcon: String?
  private let cardBtTitle: String?

  private var action: () -> Void

  public init(
    isCancelButtinEnabled: Bool = false,
    cardAvatar: String,
    cardTitle: String,
    cardSubTitle: String,
    cardButtonIcon: String? = nil,
    cardBtTitle: String? = nil,
    action: @escaping () -> Void = {},
    cancel: PassthroughSubject<Void, Never>
  ) {
    self.isCancelButtinEnabled = isCancelButtinEnabled
    self.cardAvatar = cardAvatar
    self.cardTitle = cardTitle
    self.cardSubTitle = cardSubTitle
    self.cardButtonIcon = cardButtonIcon
    self.cardBtTitle = cardBtTitle
    self.action = action
    self.cancel = cancel
  }

  public var body: some View {
    return VStack {
      if isCancelButtinEnabled {
        HStack {
          Spacer()
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
      HStack {
        Image(cardAvatar)
          .padding(.leading)
        VStack(alignment: .leading) {
          Text(cardTitle)
          Text(cardSubTitle)
            .foregroundColor(.gray)
            .font(.subheadline)
        }
        Spacer()
        if cardButtonIcon != nil && cardBtTitle != nil {
          Spacer()
          Button(action: action) {
            HStack {
              Image(cardButtonIcon!)
              Text(cardBtTitle!)
            }
            .padding()
            .foregroundColor(Color.green)
            .background(Color.clear)
          }
        }
      }
      .padding(.top, self.isCancelButtinEnabled ? 0 : 23)
      Spacer()
    }
    .frame(
      width: UIScreen.main.bounds.width - 34,
      height: self
        .isCancelButtinEnabled ? screenPadding(150) : screenPadding(130)
    )
    .clipped()
    .background(Color.white)
    .cornerRadius(15)
    .padding(.horizontal)
    .shadow(radius: 5)
  }
}
