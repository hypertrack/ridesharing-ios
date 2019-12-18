import AppState
import Combine
import SwiftUI
import Utility

struct ProgressBar: View {
  /// Progress line width constant
  let progressWidth: CGFloat = (UIScreen.main.bounds.width - 34) - 68
  /// Update position by interval:
  let frameTimeInterval: Double = 0.01
  /// Update frame per `frameTimeInterval`
  let pointPerFrame: CGFloat = 3.0
  /// ProgressBar X position
  @State private var currentX: CGFloat = 0.0

  var body: some View {
    Rectangle()
      .fill(Color(hex: "50E3C2"))
      .cornerRadius(5)
      .position(x: self.currentX, y: 5)
      .frame(width: self.progressWidth, height: 10)
      .animation(self.currentX != 0.0 ? nil : .default)
      .onAppear {
        Timer.scheduledTimer(
          withTimeInterval: self.frameTimeInterval,
          repeats: true
        ) { _ in
          self.currentX = self.currentX + self.pointPerFrame
          if self.currentX > UIScreen.main.bounds.width + 200 {
            self.currentX = -200
          }
        }
      }
  }
}

struct SearchDriverProgressView: View {
  /// Current position
  @State var position: ProgressViewPosition = .dismissed
  /// Cancel subject
  var cancel: PassthroughSubject<Void, Never>

  var body: some View {
    return VStack {
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
      ProgressBar()
        .cornerRadius(5)
      Text("Connecting you to the nearest driver")
        .foregroundColor(Color.gray)
        .padding(.horizontal)
        .padding(.top, 10)
      Spacer()
    }
    .frame(
      width: UIScreen.main.bounds.width - 34
    )
    .background(Color.white)
    .cornerRadius(15)
    .padding([.leading, .trailing])
    .shadow(radius: 15)
    .offset(y: self.position.offsetFromTop())
    .animation(.spring())
  }

  /// ProgressView position
  enum ProgressViewPosition: CGFloat {
    /// Bottom position
    case bottom
    /// Dismissed, out of bounds
    case dismissed

    func offsetFromTop() -> CGFloat {
      switch self {
        case .bottom:
          return UIScreen.main.bounds.height - 130
        case .dismissed:
          return UIScreen.main.bounds.height + 130
      }
    }
  }
}
