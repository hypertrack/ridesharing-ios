import AppState
import Combine
import CommonModels
import Foundation
import HyperTrackHelper
import HyperTrackViews
import MapKit
import SwiftUI
import Utility

struct DriverMapView: UIViewRepresentable {
  /// UserDataFlow instance
  var dataflow: DriverDataFlow
  /// User movement status update
  @Binding var movementStatus: MovementStatus?
  /// auto zoom controll
  @Binding var isAutoZoomEnabled: Bool

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = false
    mapView.showsScale = false
    mapView.isRotateEnabled = false
    return mapView
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func updateUIView(_ uiView: MKMapView, context _: Context) {
    guard let lastView = self.dataflow.store.value.lastView else { return }
    configure(mapView: uiView, from: lastView)
    isZoomNeeded(uiView)
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var control: DriverMapView

    init(_ control: DriverMapView) {
      self.control = control
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      guard let orderAnnotation = view.annotation as? OrderAnnotation else { return }
      control.dataflow.selectedOrder = orderAnnotation.order
      mapView.deselectAnnotation(view.annotation, animated: false)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      if let orderAnnotation = annotation as? OrderAnnotation {
        let reuseIdentifier = "OrderAnnotation"
        if let deviceAnnotationView = mapView.dequeueReusableAnnotationView(
          withIdentifier: reuseIdentifier
        ) {
          deviceAnnotationView.image = UIImage(named: orderAnnotation.iconName)
          return deviceAnnotationView
        } else {
          let ann = MKAnnotationView(
            annotation: orderAnnotation,
            reuseIdentifier: reuseIdentifier
          )
          ann.image = UIImage(named: orderAnnotation.iconName)
          return ann
        }
      } else {
        return annotationViewForAnnotation(annotation, onMapView: mapView)
      }
    }

    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      return rendererForOverlay(overlay)!
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
      if control.isAutoZoomEnabled {
        DispatchQueue.main.async {
          self.control.isAutoZoomEnabled = !mapViewRegionDidChangeFromUserInteraction(mapView)
        }
      }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated _: Bool) {
      if control.isAutoZoomEnabled {
        DispatchQueue.main.async {
          self.control.isAutoZoomEnabled = !mapViewRegionDidChangeFromUserInteraction(mapView)
        }
      }
    }
  }
}

extension DriverMapView {
  /// Configure mapView behavior, depending on the order status
  private func configure(mapView: MKMapView, from state: ViewName) {
    switch state.getDriverValue() {
      case .NEW:
        configureForNewState(mapView)
      case .REACHED_PICKUP,
           .DROPPING_OFF,
           .PICKING_UP,
           .REACHED_DROPOFF:
        configureForDrivingState(mapView)
      case .COMPLETED:
        configureForComplitedState(mapView)
      case .CANCELLED:
        configureForCancelledState(mapView)
    }
  }

  /// Configure map behavior for .NEW state
  private func configureForNewState(_ mapView: MKMapView) {
    removeAllAnnotationExceptDeviceAnnotation(mapView: mapView)
    mapView.addAnnotations(dataflow.orderList.map { OrderAnnotation(
      order: $0
    ) })
    if let mStatus = self.movementStatus {
      put(
        .location(mStatus.location),
        onMapView: mapView
      )
    }
  }

  /// Configure map behavior for .REACHED_PICKUP, .DROPPING_OFF, .PICKING_UP, .REACHED_DROPOFF states
  private func configureForDrivingState(_ mapView: MKMapView) {
    removeAllAnnotationExceptDeviceAnnotation(mapView: mapView)
    if let movementStatus = self.movementStatus,
      let trip = movementStatus.trips.first(
        where: { $0.id == self.dataflow.store.value.order?.trip_id }
      ) {
      put(
        .locationWithTrip(movementStatus.location, trip),
        onMapView: mapView
      )
    }
  }

  /// Configure map behavior for .COMPLETED state
  private func configureForComplitedState(_ mapView: MKMapView) {
    if let trip = self.dataflow.tripSummary {
      put(.tripSummary(trip), onMapView: mapView)
    }
  }

  /// Configure map behavior for .CANCELLED state
  private func configureForCancelledState(_ mapView: MKMapView) {
    removeAllAnnotationExceptDeviceAnnotation(mapView: mapView)
  }

  /// Remove all annotations from map except user location dot
  private func removeAllAnnotationExceptDeviceAnnotation(mapView: MKMapView) {
    let annotationForRemove = mapView.annotations
      .filter { $0 is OrderAnnotation }
    mapView.removeAnnotations(annotationForRemove)
  }

  private func isZoomNeeded(_ mapView: MKMapView) {
    if isAutoZoomEnabled {
      zoom(
        withMapInsets: .all(100),
        interfaceInsets: .custom(
          top: 10,
          leading: 10,
          bottom: 250,
          trailing: 10
        ),
        onMapView: mapView
      )
    }
  }
}
