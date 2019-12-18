import SwiftUI
import Utility

public struct BlackTopView: View {
  private let iconName: String
  private let title: String
  private var action: (() -> Void)?

  public init(iconName: String, title: String, action: (() -> Void)? = nil) {
    self.iconName = iconName
    self.title = title
    self.action = action
  }

  public var body: some View {
    VStack {
      HStack {
        Button(action: {
          self.action?()
        }) {
          Image(iconName)
            .foregroundColor(Color.white)
            .padding(.leading)
          Text(title)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.trailing)
        }
        .disabled(self.action == nil)
      }
      .padding(.top, 13)
      Spacer()
    }
    .frame(width: (UIScreen.main.bounds.width - 34) - 90, height: 62)
    .clipped()
    .background(Color.black)
    .cornerRadius(15)
    .shadow(radius: 5)
  }
}
