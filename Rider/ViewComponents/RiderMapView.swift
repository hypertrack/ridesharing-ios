import AppState
import Combine
import CommonModels
import Foundation
import HyperTrackHelper
import HyperTrackViews
import MapKit
import SwiftUI
import Utility

/// Map wrapper that contains LocationManager and RiderMap
/// that updates user location in real time
struct RiderMapViewWrapper: View {
  /// LocationManager instance
  @ObservedObject var locationManager: LocationManager = LocationManager()
  /// Rider dataflow instance
  @ObservedObject var dataflow: RiderDataFlow

  @Binding var isAutoZoomEnabled: Bool

  var body: some View {
    /// Request location permissions for using current user location
    self.locationManager.requestLocationPermissions()
    /// Start updateing user location if permissions is granted
    self.locationManager.startUpdateingLocationsIfNeeded()
    /// Create RiderMapView
    return RiderMapView(
      dataflow: self.dataflow,
      location: self.$locationManager.userLocation,
      isAutoZoomEnabled: self.$isAutoZoomEnabled
    )
  }
}

struct RiderMapView: UIViewRepresentable {
  /// UserDataFlow instance
  var dataflow: RiderDataFlow
  /// User location update
  @Binding var location: CLLocation?
  /// Auto zoom control
  @Binding var isAutoZoomEnabled: Bool

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.showsUserLocation = false
    mapView.showsCompass = false
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
    var control: RiderMapView

    init(_ control: RiderMapView) {
      self.control = control
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      return annotationViewForAnnotation(annotation, onMapView: mapView)
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
      print("self.control.isZoomEnabled = \(control.isAutoZoomEnabled)")
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated _: Bool) {
      if control.isAutoZoomEnabled {
        DispatchQueue.main.async {
          self.control.isAutoZoomEnabled = !mapViewRegionDidChangeFromUserInteraction(mapView)
        }
      }
      print("self.control.isZoomEnabled = \(control.isAutoZoomEnabled)")
    }
  }
}

extension RiderMapView {
  /// Configure mapView behaviour
  private func configure(mapView: MKMapView, from state: ViewName) {
    switch state.getRiderValue() {
      case .LOOKING_FOR_RIDES,
           .LOOKING_DRIVER:
        configureForLookingState(mapView)
      case .REACHED_PICKUP,
           .DROPPING_OFF,
           .PICKING_UP,
           .REACHED_DROPOFF:
        configureForDrivingState(mapView)
      case .COMPLETED:
        configureForComplitedState(mapView)
      case .CANCELLED:
        configureForCancelledState(mapView)
      default:
        break
    }
  }

  /// Configure map behavior from .LOOKING_FOR_RIDES, .LOOKING_DRIVER state
  private func configureForLookingState(_ mapView: MKMapView) {
    guard let location = self.location else { return }
    put(.location(location), onMapView: mapView)
  }

  /// Configure map behavior from .REACHED_PICKUP, .DROPPING_OFF, .PICKING_UP, .REACHED_DROPOFF states
  private func configureForDrivingState(_ mapView: MKMapView) {
    if let movementStatus = self.dataflow.userMovementStatus,
      let trip = movementStatus.trips.first(
        where: { $0.id == self.dataflow.store.value.order?.trip_id }
      ) {
      put(
        .locationWithTrip(movementStatus.location, trip),
        onMapView: mapView
      )
    } else {
      configureForLookingState(mapView)
    }
  }

  /// Configure map behavior from .COMPLITED state
  private func configureForComplitedState(_ mapView: MKMapView) {
    dump(dataflow.tripSummary)
    if let trip = self.dataflow.tripSummary {
      put(.tripSummary(trip), onMapView: mapView)
    }
  }

  /// Configure map behavior from .CANCELLED state
  private func configureForCancelledState(_ mapView: MKMapView) {
    configureForLookingState(mapView)
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
