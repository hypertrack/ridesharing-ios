import AppState
import Combine
import CommonModels
import CommonViewComponents
import MapKit
import SwiftUI
import Utility

struct DriverHomeView: View {
  /// Variable that controls the display of the `AcceptView`
  @State var showAccepted: Bool = false
  /// Variable that controls the call sheet
  private let callPublisher = PassthroughSubject<Void, Never>()
  /// Variable that controls the call sheet
  private let directionsPublisher = PassthroughSubject<Void, Never>()
  /// Driver data store
  @ObservedObject var dataflow: DriverDataFlow
  /// For disabling auto zoom
  @State var isAutoZoomEnabled = true

  init(dataflow: DriverDataFlow) {
    self.dataflow = dataflow
    self.dataflow.createUserMovementStatusSubscription()
    self.dataflow.update(
      state: self.dataflow.store.value.lastView?.getDriverValue() ?? .NEW
    )

    /// This allows us to display driver's orders with clear background
    UITableView.appearance().backgroundColor = .clear
    UITableView.appearance().separatorStyle = .none
    UITableViewCell.appearance().backgroundColor = .clear
    UITableViewCell.appearance().selectionStyle = .none
  }

  var body: some View {
    return ZStack {
      /// HomeView map
      DriverMapView(
        dataflow: self.dataflow,
        movementStatus: self.$dataflow.userMovementStatus,
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
            height: zoomDriverButtonPadding[
              self.dataflow.driverHomeState.rawValue
            ] - screenPadding(10)
          )
      }
      .edgesIgnoringSafeArea(.all)
      VStack {
        /// New order from firestore list
        if self.dataflow.driverHomeState == .NEW {
          ScrollableView {
            ForEach(self.dataflow.newCreatedOrderList) { item in
              OrderRow(order: item, onDelete: { orderId in
                guard let id = orderId else { return }
                self.dataflow.removeNewOrderds(by: id)
              }) { orderId in
                guard let id = orderId else { return }
                self.dataflow.selectedOrder = self.dataflow.orderList.first { $0.id == id
                }
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
          .frame(
            height: self.dataflow.newCreatedOrderList.count < 3 ?
              CGFloat(self.dataflow.newCreatedOrderList.count) * CGFloat(88) : CGFloat(3) * CGFloat(88)
          )
        }
        Spacer()
        makeView()
          .edgesIgnoringSafeArea(.all)
      }
      if showAccepted {
        AcceptView(dataflow: self.dataflow)
          .animation(.default)
      }
    }
    .onReceive(self.dataflow.selectedOrderWillChange) {
      if $0 != nil { self.showAccepted = true }
    }
    .onReceive(self.dataflow.acceptedOrderWillChange) { _ in
      self.showAccepted = false
    }
    .onReceive(self.callPublisher) { _ in
      makeCall(number: self.dataflow.acceptedOrder?.rider.phone_number)
    }
    .onReceive(self.directionsPublisher) { _ in
      guard let dropoffModel = self.dataflow.acceptedOrder?.dropoff
        else { return }
      openDirectionOnAppleMap(dropoffModel)
    }
  }

  private func makeView() -> some View {
    switch dataflow.driverHomeState {
      case .NEW:
        let name = dataflow.store.value.user?.name ?? ""
        return AnyView(SlideContainer(
          tContent: BlackTopView(
            iconName: "search_icon",
            title: "Finding riders near you"
          ),
          bContent: TripCardView(
            isCancelButtinEnabled: false,
            cardAvatar: "Male-white",
            cardTitle: name,
            cardSubTitle: "4.8",
            cancel: dataflow.cancelOrderSubject
          )
        ))
      case .PICKING_UP:
        let name = dataflow.acceptedOrder?.rider.name ?? ""
        return AnyView(SlideContainer(
          tContent: BlackTopView(
            iconName: "directions_icon",
            title: "GET DIRECTIONS"
          ) {
            self.directionsPublisher.send()
          },
          bContent: TripCardView(
            isCancelButtinEnabled: true,
            cardAvatar: "female",
            cardTitle: name,
            cardSubTitle: "4.8",
            cardButtonIcon: "call",
            cardBtTitle: "Call",
            action: {
              self.callPublisher.send()
            },
            cancel: dataflow.cancelOrderSubject
          )
        ))
      case .REACHED_PICKUP:
        let name = dataflow.acceptedOrder?.rider.name ?? ""
        return AnyView(SlideContainer(
          tContent: EmptyView(),
          bContent: StartTripCardView(
            isCancelButtinEnabled: true,
            cardAvatar: "female",
            cardName: name,
            cardRating: "4.8",
            cardButtonIcon: "call",
            cardBtTitle: "Call",
            mainButtonTitle: "START TRIP",
            phoneCallAction: {
              self.callPublisher.send()
            }, startTripAction: {
              self.dataflow.droppingOffOrder()
            }, cancel: dataflow.cancelOrderSubject
          )
        ))
      case .DROPPING_OFF:
        let name = dataflow.acceptedOrder?.rider.name ?? ""
        let address = dataflow.acceptedOrder?.dropoff.address ?? ""
        return AnyView(SlideContainer(
          tContent: BlackTopView(
            iconName: "directions_icon",
            title: "GET DIRECTIONS"
          ) {
            self.directionsPublisher.send()
          },
          bContent: RideStartedCardView(
            isCancelButtinEnabled: true,
            cardAvatar: "female",
            cardName: name,
            cardRating: "4.8",
            cardAddress: address,
            cancel: dataflow.cancelOrderSubject
          )
        ))
      case .REACHED_DROPOFF:
        let name = dataflow.acceptedOrder?.rider.name ?? ""
        return AnyView(SlideContainer(
          tContent: EmptyView(),
          bContent: StartTripCardView(
            isCancelButtinEnabled: true,
            cardAvatar: "female",
            cardName: name,
            cardRating: "4.8",
            cardButtonIcon: "call",
            cardBtTitle: "Call",
            mainButtonTitle: "END TRIP",
            phoneCallAction: {
              self.callPublisher.send()
            }, startTripAction: {
              self.dataflow.completedOrder()
            }, cancel: dataflow.cancelOrderSubject
          )
        ))
      case .COMPLETED:
        let name = dataflow.acceptedOrder?.rider.name ?? ""
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
            iconName: "search_icon",
            title: "FIND NEW RIDERS"
          ) {
            self.dataflow.removeAllData()
          },
          bContent: SummaryCardView(
            distance: formattedDouble(distanceMiles.value),
            rideTime: time.toSrting,
            name: name,
            price: "\(Int(price.value))"
          )
        ))
      default:
        return AnyView(EmptyView())
    }
  }
}
