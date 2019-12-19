import Combine
import CommonExtensions
import CommonModels
import CoreLocation
import Foundation
import MapKit
import SwiftUI
import UIKit

public let publishableKey: String = <#Paste your publishable key here#>

/// Instance for observing Applications life-cycle notification events
public let appStateReceiver: ApplicationStateReceiver =
  ApplicationStateReceiver(
  )

/// Open direction on Apple maps
public func openDirectionOnAppleMap(_ place: Order.Place) {
  let latitude = Double(place.latitude)
  let longitude = Double(place.longitude)
  let placeMark = MKPlacemark(
    coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  )
  let mapItem = MKMapItem(placemark: placeMark)
  mapItem
    .openInMaps(launchOptions: [
      MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
    ])
}

/// Make call
public func makeCall(number: String?) {
  guard let phoneNumber = number else { return }
  UIApplication.shared.open(
    URL(string: "telprompt://\(phoneNumber)")!,
    options: [:],
    completionHandler: nil
  )
}

public func screenPadding(_ value: CGFloat) -> CGFloat {
  let screenConstant: Int = 812
  let screenHeight: Int = Int(UIScreen.main.bounds.height)
  if screenHeight >= screenConstant {
    return value + 10.0
  } else {
    return value
  }
}

/// Keyboard responder that handles keyboard behaviour
public final class KeyboardResponder: ObservableObject {
  public let didChange = PassthroughSubject<CGFloat, Never>()
  private var center: NotificationCenter
  public private(set) var currentHeight: CGFloat = 0 {
    willSet {
      print("currentHeight - \(currentHeight)")
      didChange.send(currentHeight)
    }
  }

  public init(center: NotificationCenter = .default) {
    self.center = center
    self.center.addObserver(
      self,
      selector: #selector(keyBoardWillShow(notification:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    self.center.addObserver(
      self,
      selector: #selector(keyBoardWillHide(notification:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  deinit {
    center.removeObserver(self)
  }

  @objc func keyBoardWillShow(notification: Notification) {
    if let keyboardSize = (notification.userInfo?[
      UIResponder.keyboardFrameBeginUserInfoKey
    ] as? NSValue)?.cgRectValue {
      currentHeight = keyboardSize.height
    }
  }

  @objc func keyBoardWillHide(notification _: Notification) {
    currentHeight = 0
  }
}

public func formattedDouble(_ dValue: Double) -> String {
  let divisor = pow(10.0, Double(2))
  let value = (dValue * divisor).rounded() / divisor
  if !(value.truncatingRemainder(dividingBy: 1) == 0) {
    return String(format: "%.2f", value)
  } else {
    return "\(Int(value))"
  }
}

extension MKLocalSearch {
  public static func getSearch(search: MKLocalSearchCompletion) -> MKLocalSearch {
    let searchRequest = Request(completion: search)
    return MKLocalSearch(request: searchRequest)
  }
}

/// Provide functionality hide keyboard for SwiftUI
public struct HideKeyboard: ViewModifier {
  public init() {}

  public func body(content: Content) -> some View {
    content
      .onTapGesture {
        self.endEditing()
      }
  }

  private func endEditing() {
    UIApplication.shared.endEditing()
  }
}

/// Modifier to make special button with text
public struct ButtonText: ViewModifier {
  public let font = Font.system(size: 16).weight(.semibold)

  public init() {}

  public func body(content: Content) -> some View {
    content
      .font(font)
      .foregroundColor(.white)
      .padding(.horizontal, 77)
      .padding(.vertical, 20)
      .background(Color.clear)
  }
}

public struct RidesharingTextFieldStyle: TextFieldStyle {
  public init() {}

  public func _body(
    configuration: TextField<Self._Label>
  ) -> some View {
    VStack(spacing: 4) {
      configuration
      Rectangle()
        .foregroundColor(Color(hex: "359E86"))
        .frame(height: 1.0, alignment: .bottom)
    }.padding(.top, 6)
  }
}

/// Modifier to make special primary text label
public struct PrimaryLabel: ViewModifier {
  public init() {}

  public func body(content: Content) -> some View {
    content
      .font(.system(size: 10))
      .foregroundColor(Color.gray)
  }
}

/// Modifier to make special secondary text label
public struct SecondaryLabel: ViewModifier {
  public init() {}

  public func body(content: Content) -> some View {
    content
      .font(.system(size: 12))
  }
}

/// Modifier to make special divider for summary content view
public struct CenteredDivider: ViewModifier {
  public init() {}

  public func body(content: Content) -> some View {
    content
      .alignmentGuide(.custom) { $0[.top] }
      .background(Color.black)
      .padding()
  }
}

/// Object for observing Applications life-cycle notification events
public final class ApplicationStateReceiver {
  @Published public var notification: Notification = Notification(
    name: Notification.Name(rawValue: "NONE")
  )

  private let appStateSubject = PassthroughSubject<Notification, Never>()
  private var cancellables: [AnyCancellable] = []

  public init() {
    bindInputs()
    bindOutputs()
  }

  private func bindInputs() {
    let didEnterBackgroundPublisher = NotificationCenter.Publisher(
      center: .default, name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    let willEnterForegroundPublisher = NotificationCenter.Publisher(
      center: .default, name: UIApplication.willEnterForegroundNotification,
      object: nil
    )
    let didFinishLaunchingNotification = NotificationCenter.Publisher(
      center: .default, name: UIApplication.didFinishLaunchingNotification,
      object: nil
    )
    let didBecomeActiveNotification = NotificationCenter.Publisher(
      center: .default, name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    let notificationInputStream = didEnterBackgroundPublisher
      .merge(with: willEnterForegroundPublisher)
      .merge(with: didFinishLaunchingNotification)
      .merge(with: didBecomeActiveNotification)
      .share()
      .subscribe(appStateSubject)
    cancellables += [notificationInputStream]
  }

  private func bindOutputs() {
    let notificationOutputStream = appStateSubject
      .assign(to: \.notification, on: self)

    cancellables += [notificationOutputStream]
  }
}

/// Object save method for `T` object and `key`  saved object key
public func save<T: Codable>(object: T?, for key: String) {
  let documentsPath = NSSearchPathForDirectoriesInDomains(
    .documentDirectory, .userDomainMask, true
  )[0]
  let documentsUrl = URL(fileURLWithPath: documentsPath)
  let viewStateUrl = documentsUrl
    .appendingPathComponent(key)
  if object == nil {
    try? FileManager.default.removeItem(at: viewStateUrl)
  } else {
    let data = try! JSONEncoder().encode(object)
    try! data.write(to: viewStateUrl)
  }
}

/// func for load object from UserDefault with specific `key`
public func loadObject<T: Codable>(for key: String) -> T? {
  let documentsPath = NSSearchPathForDirectoriesInDomains(
    .documentDirectory, .userDomainMask, true
  )[0]
  let documentsUrl = URL(fileURLWithPath: documentsPath)
  let viewStateUrl = documentsUrl
    .appendingPathComponent(key)
  guard
    let data = try? Data(contentsOf: viewStateUrl),
    let viewState = try? JSONDecoder().decode(T.self, from: data)
    else { return nil }
  return viewState
}

public func mapViewRegionDidChangeFromUserInteraction(
  _ mapView: MKMapView
) -> Bool {
  let view = mapView.subviews[0]
  //  Look through gesture recognizers to determine
  // whether this region change is from user interaction
  if let gestureRecognizers = view.gestureRecognizers {
    for recognizer in gestureRecognizers {
      if recognizer.state == UIGestureRecognizer.State.began ||
        recognizer.state == UIGestureRecognizer.State.ended {
        return true
      }
    }
  }
  return false
}
