import SwiftUI

public struct ShareSheet: UIViewControllerRepresentable {
  /// Share sheet сallback
  public typealias Callback = (
    _ activityType: UIActivity.ActivityType?,
    _ completed: Bool,
    _ returnedItems: [Any]?,
    _ error: Error?
  ) -> Void

  /// The array of data objects on which to perform the activity. The type of objects in the array is variable
  /// and dependent on the data your application manages.
  /// For example, the data might consist of one or more string or image objects representing the currently selected content.
  public let activityItems: [Any]
  /// An array of `UIActivity` objects representing the custom services that your application supports. This parameter may be nil.
  public let applicationActivities: [UIActivity]?
  /// The list of services that should not be displayed.
  public let excludedActivityTypes: [UIActivity.ActivityType]?
  /// Share sheet callback
  public let callback: Callback?

  public init(
    activityItems: [Any],
    applicationActivities: [UIActivity]? = nil,
    excludedActivityTypes: [UIActivity.ActivityType]? = nil,
    callback: Callback? = nil
  ) {
    self.activityItems = activityItems
    self.applicationActivities = applicationActivities
    self.excludedActivityTypes = excludedActivityTypes
    self.callback = callback
  }

  public func makeUIViewController(context _: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: applicationActivities
    )
    controller.excludedActivityTypes = excludedActivityTypes
    controller.completionWithItemsHandler = callback
    return controller
  }

  public func updateUIViewController(
    _: UIActivityViewController,
    context _: Context
  ) {
    // nothing to do here
  }
}
