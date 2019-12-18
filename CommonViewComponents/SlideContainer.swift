import SwiftUI

public struct SlideContainer<TopContent: View, BottomContent: View>: View {
  public let tContent: TopContent
  public let bContent: BottomContent

  public init(tContent: TopContent, bContent: BottomContent) {
    self.tContent = tContent
    self.bContent = bContent
  }

  public var body: some View {
    VStack(spacing: 0.0) {
      Spacer()
      self.tContent
        .animation(.none)
        .offset(y: 60)
      self.bContent
        .animation(.none)
        .offset(y: 40)
    }
    .background(Color.clear)
    .transition(.move(edge: .bottom))
  }
}
