import Combine
import CommonExtensions
import SwiftUI
import Utility

public struct StartTripCardView: View {
  private let isCancelButtinEnabled: Bool
  var cancel: PassthroughSubject<Void, Never>

  private let cardAvatar: String
  private let cardName: String
  private let cardRating: String

  private let cardButtonIcon: String?
  private let cardBtTitle: String?

  private let mainButtonTitle: String?

  private var phoneCallAction: () -> Void
  private var startTripAction: () -> Void

  public init(
    isCancelButtinEnabled: Bool = false,
    cardAvatar: String,
    cardName: String,
    cardRating: String,
    cardButtonIcon: String? = nil,
    cardBtTitle: String? = nil,
    mainButtonTitle: String? = nil,
    phoneCallAction: @escaping () -> Void = {},
    startTripAction: @escaping () -> Void = {},
    cancel: PassthroughSubject<Void, Never>
  ) {
    self.isCancelButtinEnabled = isCancelButtinEnabled
    self.cardAvatar = cardAvatar
    self.cardName = cardName
    self.cardRating = cardRating
    self.cardButtonIcon = cardButtonIcon
    self.cardBtTitle = cardBtTitle
    self.phoneCallAction = phoneCallAction
    self.startTripAction = startTripAction
    self.mainButtonTitle = mainButtonTitle
    self.cancel = cancel
  }

  public var body: some View {
    VStack {
      VStack {
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
          Image(self.cardAvatar)
            .padding(.leading)
          VStack(alignment: .leading) {
            Text(self.cardName)
            Text(self.cardRating)
              .foregroundColor(.gray)
              .font(.subheadline)
          }
          Spacer()
          if self.cardButtonIcon != nil && self.cardBtTitle != nil {
            Spacer()
            Button(action: {
              self.phoneCallAction()
            }) {
              HStack {
                Image(self.cardButtonIcon!)
                Text(self.cardBtTitle!)
              }
              .padding()
              .foregroundColor(Color.green)
              .background(Color.clear)
              .cornerRadius(5)
            }
          }
        }
        .padding([.bottom])
        self.button()
      }
      Spacer()
    }
    .frame(
      width: UIScreen.main.bounds.width - 34,
      height: self
        .isCancelButtinEnabled ? screenPadding(240) : screenPadding(220)
    )
    .clipped()
    .background(Color.white)
    .cornerRadius(15)
    .padding(.horizontal)
    .shadow(radius: 5)
  }

  fileprivate func button() -> some View {
    return Button(action: startTripAction) {
      HStack {
        Text(self.mainButtonTitle ?? "")
          .padding()
          .foregroundColor(Color.white)
        Spacer()
        Image("➞")
          .padding()
          .foregroundColor(Color.white)
      }
    }
    .frame(height: 60)
    .frame(minWidth: 0, maxWidth: .infinity)
    .background(mainButtonTitle == "START TRIP" ? Color(hex: "50E3C2") : Color(
      hex: "E36650"
    ))
    .cornerRadius(5)
    .padding([.bottom, .trailing, .leading])
  }
}
