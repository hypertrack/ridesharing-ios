import CommonModels
import SwiftUI

public struct InfoView: View {
  /// Error model provide info for view
  public let error: HError?
  /// title view
  public let title: String
  /// sub title view
  public let subTitle: String
  /// main button title
  public let buttonTitle: String
  /// action for main button
  public let buttonAction: () -> Void

  public init(
    _ error: HError? = nil,
    _ title: String,
    _ subTitle: String,
    _ buttonTitle: String,
    _ action: @escaping () -> Void = {}
  ) {
    self.error = error
    self.title = title
    self.subTitle = subTitle
    self.buttonTitle = buttonTitle
    buttonAction = action
  }

  public var body: some View {
    GeometryReader { geometry in
      VStack() {
        Text(self.title)
          .font(.system(size: 26))
          .fontWeight(.semibold)
          .padding(.top, geometry.size.height * 0.164)
        Text(self.subTitle)
          .font(.system(size: 16))
          .fontWeight(.semibold)
          .lineLimit(nil)
          .multilineTextAlignment(.center)
          .foregroundColor(Color(hex: "9B9B9B"))
          .padding(.top, 20)
          .padding(.horizontal, 30)
        Button(action: {
          self.buttonAction()
        }) {
          Text(self.buttonTitle)
            .font(.system(size: 16))
            .lineLimit(1)
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .foregroundColor(.white)
            .background(Color.black)
            .cornerRadius(3)
        }
        .background(Color.black)
        .cornerRadius(4)
        .padding(.top, 20)
        .padding(.horizontal, geometry.size.height * 0.04)
        Spacer()
      }
      .background(
        Image("background_permission")
          .resizable()
          .scaledToFill()
      )
      .edgesIgnoringSafeArea(.all)
    }
  }
}
