import SwiftUI

public struct ScrollableView<Content>: View where Content: View {
  public var axes: Axis.Set = .vertical
  public var reversed: Bool = false
  public var scrollToEnd: Bool = false
  public var content: () -> Content

  @State private var contentHeight: CGFloat = .zero
  @State private var contentOffset: CGFloat = .zero
  @State private var scrollOffset: CGFloat = .zero

  public init(
    axes: Axis.Set = .vertical,
    reversed: Bool = true,
    scrollToEnd: Bool = true,
    content: @escaping () -> Content
  ) {
    self.axes = axes
    self.reversed = reversed
    self.scrollToEnd = scrollToEnd
    self.content = content
  }

  public var body: some View {
    GeometryReader { geometry in
      if self.axes == .vertical {
        self.vertical(geometry: geometry)
      }
    }
    .clipped()
  }

  private func vertical(geometry: GeometryProxy) -> some View {
    VStack {
      content()
    }
    .modifier(ViewHeightKey())
    .onPreferenceChange(ViewHeightKey.self) {
      self.updateHeight(with: $0, outerHeight: geometry.size.height)
    }
    .frame(height: geometry.size.height, alignment: reversed ? .bottom : .top)
    .offset(y: contentOffset + scrollOffset)
    .animation(.easeInOut)
    .background(Color.clear)
    .gesture(DragGesture()
      .onChanged { self.onDragChanged($0) }
      .onEnded { self.onDragEnded($0, outerHeight: geometry.size.height) }
    )
  }

  private func onDragChanged(_ value: DragGesture.Value) {
    scrollOffset = value.location.y - value.startLocation.y
  }

  private func onDragEnded(_ value: DragGesture.Value, outerHeight: CGFloat) {
    let scrollOffset = value.predictedEndLocation.y - value.startLocation.y

    updateOffset(with: scrollOffset, outerHeight: outerHeight)
    self.scrollOffset = 0
  }

  private func updateHeight(with height: CGFloat, outerHeight: CGFloat) {
    let delta = contentHeight - height
    contentHeight = height
    if scrollToEnd {
      contentOffset = reversed ? height - outerHeight - delta : outerHeight - height
    }
    if abs(contentOffset) > .zero {
      updateOffset(with: delta, outerHeight: outerHeight)
    }
  }

  private func updateOffset(with delta: CGFloat, outerHeight: CGFloat) {
    let topLimit = contentHeight - outerHeight

    if topLimit < .zero {
      contentOffset = .zero
    } else {
      var proposedOffset = contentOffset + delta
      if (reversed ? proposedOffset : -proposedOffset) < .zero {
        proposedOffset = 0
      } else if (reversed ? proposedOffset : -proposedOffset) > topLimit {
        proposedOffset = (reversed ? topLimit : -topLimit)
      }
      contentOffset = proposedOffset
    }
  }
}

public struct ViewHeightKey: PreferenceKey {
  public static var defaultValue: CGFloat { 0 }
  public static func reduce(value: inout Value, nextValue: () -> Value) {
    value = value + nextValue()
  }
}

extension ViewHeightKey: ViewModifier {
  public func body(content: Content) -> some View {
    return content.background(GeometryReader { proxy in
      Color.clear.preference(key: Self.self, value: proxy.size.height)
    })
  }
}
