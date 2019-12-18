import AppState
import Combine
import CommonModels
import CommonViewComponents
import CommonViews
import Foundation
import SwiftUI
import Utility

struct RiderHomeView: View {
  /// RIder data store
  @ObservedObject var dataflow: RiderDataFlow
  /// Trigger for showing share sheet
  @State private var showShareSheet = false
  /// Trigger for showing call sheet
  private let callPublisher = PassthroughSubject<Void, Never>()
  /// for disable auto zoom
  @State var isAutoZoomEnabled = true

  var body: some View {
    dump(self.dataflow.tripSummary)
    return ZStack {
      /// HomeVIew map
      RiderMapViewWrapper(
        dataflow: self.dataflow,
        isAutoZoomEnabled: self.$isAutoZoomEnabled
      )
      .edgesIgnoringSafeArea(.all)
      VStack {
        Spacer()
        HStack {
          Spacer()
          Button(action: {
            self.isAutoZoomEnabled.toggle()
          }) {
            Image("zoom_icon")
              .renderingMode(.original)
          }
          .frame(width: 50, height: 50)
          .opacity(self.isAutoZoomEnabled ? 0.0 : 1.0)
          .padding(.trailing)
        }
        Spacer()
          .frame(
            height: zoomRiderButtonPadding[
              (self.dataflow.store.value.lastView?
                .getRiderValue().rawValue ?? 0) + 1
            ] - screenPadding(10)
          )
      }
      .edgesIgnoringSafeArea(.all)
      self.makeView()
        .edgesIgnoringSafeArea(.all)
    }
    .sheet(isPresented: $showShareSheet) {
      ShareSheet(activityItems: [self.dataflow.getCurrentShareLink()!])
    }
    .onReceive(self.callPublisher) { _ in
      makeCall(number: self.dataflow.store.value.order?.driver?.phone_number)
    }
  }

  private func makeView() -> some View {
    let homeState = dataflow.store.value.lastView?.getRiderValue()
    switch homeState {
      case .LOOKING_FOR_RIDES:
        return AnyView(LocationPickerView(
          mode: .pickDestination,
          callback: {
            self.dataflow.sendOrderOnFireStore(
              order: self.dataflow.makeOrderFrom(
                destination: $0,
                pickup: $1
              )
            )
          }
        ))
      case .LOOKING_DRIVER:
        dataflow.makeSubscriptionOnCurrentOrder()
        return AnyView(SearchDriverProgressView(
          position: .bottom,
          cancel: dataflow.cancelOrderSubject
        ))
      case .PICKING_UP,
           .DROPPING_OFF,
           .REACHED_DROPOFF,
           .REACHED_PICKUP:
        dataflow.createUserMovementStatusSubscription()
        let name = dataflow.store.value.order?.driver?.name ?? ""
        let carModel = dataflow.store.value.order?.driver?.car?.model ?? ""
        let carLicensePlate = dataflow.store.value.order?.driver?.car?
          .license_plate ?? ""
        return AnyView(SlideContainer(
          tContent: BlackTopView(
            iconName: "share_icon",
            title: "SHARE TRIP",
            action: {
              print("SHARE TRIP")
              if self.dataflow.getCurrentShareLink() != nil {
                self.showShareSheet.toggle()
              }
            }
          ),
          bContent: TripCardView(
            isCancelButtinEnabled: true,
            cardAvatar: "Male-white",
            cardTitle: name,
            cardSubTitle: "\(carModel) | \(carLicensePlate)",
            cardButtonIcon: "call",
            cardBtTitle: "Call",
            action: {
              self.callPublisher.send()
            },
            cancel: dataflow.cancelOrderSubject
          )
        ))
      case .COMPLETED:
        let name = dataflow.store.value.order?.driver?.name ?? ""
        let distance = dataflow.tripSummary?.summary?.distance ?? 0.0
        let distanceMeters = Measurement(
          value: distance,
          unit: UnitLength.meters
        )
        let distanceMiles = distanceMeters.converted(to: .miles)
        let rideTime = dataflow.tripSummary?.summary?.duration ?? 0.0
        let time = Time(Int(rideTime))
        let price = distanceMiles * 2
        return AnyView(SlideContainer(
          tContent: BlackTopView(
            iconName: "",
            title: "BOOK ANOTHER RIDE",
            action: {
              self.dataflow.removeAllData()
            }
          ),
          bContent: SummaryCardView(
            distance: formattedDouble(distanceMiles.value),
            rideTime: time.toSrting,
            name: name,
            price: "\(Int(price.value))"
          )
        ))
      case .CANCELLED:
        return AnyView(EmptyView())
      default:
        return AnyView(EmptyView())
    }
  }
}
