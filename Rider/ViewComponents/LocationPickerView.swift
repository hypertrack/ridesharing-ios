import Combine
import CommonModels
import MapKit
import SwiftUI
import Utility

struct LocationPickerView: View {
  /// Provide local address search by string
  @ObservedObject var searcher: AddressSearcher = AddressSearcher()
  /// Location picker mode. Describes the picker display mode
  @State var mode: PickerMode = .pickDestination
  /// LocationPicker position from main view
  @State var position: PickerPosition = .bottom
  /// Destination place model. Picking by user
  @State var destination: Order.Place?
  /// Pick up  place model. Picking by user
  @State var pickUp: Order.Place?
  /// Keyboard responder for display the correct keyboard behavior
  @State var keyboard: KeyboardResponder = KeyboardResponder()

  /// Callback for completion picking places
  var callback: (_ destination: Order.Place, _ pickUp: Order.Place) -> Void

  var body: some View {
    UITableView.appearance().separatorStyle = .none
    return VStack {
      VStack {
        Text(self.mode == .pickUserLocation ? "Enter pickup location" : "Where do you wanna go ?")
          .font(.headline)
          .animation(nil)
          .padding(.top, 35)
        HStack {
          if self.position == .top {
            Button(action: {
              self.backToPrevousMode()
            }) {
              Image("back_icon")
            }
            .frame(width: 22, height: 22)
            .padding(.leading, 20)
          }
          TextField(
            self.mode == .pickUserLocation ? "Enter pickup location" : "Enter your destination",
            text: self.$searcher.searchString
          )
          .frame(height: 45)
          .offset(x: 10).padding(.trailing, 10)
          .background(Color(hex: "F8F9FA"))
          .padding(.leading, self.position == .top ? 10 : 40)
          .padding(.trailing, 40)
          .onTapGesture { self.position = .top }
          .animation(.spring())
        }
        List {
          ForEach(self.searcher.searchResult, id: \.self) {
            SearchListRow(order: $0) {
              self.searcher.pickPlace(place: $0)
            }
            .listRowInsets(EdgeInsets(
              top: 5,
              leading: 0,
              bottom: 5,
              trailing: 0
            ))
            .padding(.horizontal)
          }
        }
        .animation(nil)
        .padding(
          .bottom,
          keyboard.currentHeight == 0 ? keyboard.currentHeight : keyboard.currentHeight + self.position.offsetFromTop()
        )
      }
      .rotation3DEffect(
        Angle(degrees: self.mode == .pickUserLocation ? 180 : 0),
        axis: (x: 0, y: 1, z: 0)
      )
      .modifier(HideKeyboard())
      .background(Color.white)
      .cornerRadius(15)
      .shadow(radius: 15)
    }
    .rotation3DEffect(
      Angle(degrees: self.mode == .pickUserLocation ? 180 : 0),
      axis: (x: 0, y: 1, z: 0)
    )
    .onReceive(self.searcher.didChangePickedPlace) {
      self.toNextMode(saveResult: $0)
    }
    .padding([.leading, .trailing])
    .background(Color.clear)
    .offset(y: self.position.offsetFromTop())
    .animation(.spring())
  }

  func backToPrevousMode() {
    if mode.rawValue == 0 { position = .bottom
      UIApplication.shared.endEditing()
      return
    }
    mode = PickerMode(rawValue: mode.rawValue - 1)!
  }

  func toNextMode(saveResult: Order.Place?) {
    if mode == .pickDestination {
      destination = saveResult
      searcher.removeSearchResult()
      withAnimation(.default) {
        self.mode = .pickUserLocation
      }
    } else {
      pickUp = saveResult
      position = .dismissed
      callback(destination!, pickUp!)
    }
  }

  /// Picker mode
  enum PickerMode: Int {
    /// Provide picking destination place
    case pickDestination
    /// Provide picking pick up place
    case pickUserLocation
  }

  /// Picker position
  enum PickerPosition: CGFloat {
    /// Top position
    case top
    /// Bottom position
    case bottom
    /// Dissmised from screen
    case dismissed

    func offsetFromTop() -> CGFloat {
      switch self {
        case .bottom:
          return UIScreen.main.bounds.height - 150
        case .top:
          return 80
        case .dismissed:
          return UIScreen.main.bounds.height + 150
      }
    }
  }
}
