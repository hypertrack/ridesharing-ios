import AppState
import Combine
import HyperTrackHelper
import MapKit
import SwiftUI
import Utility

/// AcceptVIew for accepting selected order
struct AcceptView: View {
  /// show card with animation
  @State var isShow: Bool = false
  /// `pulsate` stored behaviour of pulsate animation
  @State var pulsate: Bool = false
  /// UserDataFlow provides accepting order action
  @ObservedObject var dataflow: DriverDataFlow

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color(hex: "EBF0F8"))
        .opacity(90)
        .edgesIgnoringSafeArea(.all)
      VStack {
        AcceptView.MapView(
          annotation: OrderAnnotation(order: self.dataflow.selectedOrder!)
        )
        .aspectRatio(contentMode: .fit)
        .clipped()
        .clipShape(Circle())
        .padding()
        .overlay(
          pulse()
            .padding(.vertical, 70)
            .padding([.leading, .trailing], 28)
            .clipped())
        .clipShape(Circle())
        .padding(.horizontal, 45)
        .padding(.top, 20)
        Spacer()
        if isShow {
          VStack {
            ViewCard(dataflow: self.dataflow)
          }
          VStack {
            HStack(alignment: .center) {
              cancelButton
              acceptButton
            }.padding([.leading, .trailing], 58)
          }
        }
        Spacer()
      }
    }
    .onAppear {
      withAnimation {
        self.isShow.toggle()
      }
    }
  }

  fileprivate var cancelButton: some View {
    return Button(action: {
      self.dataflow.acceptedOrder = nil
    }) {
      Image("close_icon")
        .padding()
        .foregroundColor(Color.white)
    }
    .frame(width: 70, height: 70)
    .background(Color.black)
    .cornerRadius(5)
    .padding(.top, 25)
  }

  fileprivate var acceptButton: some View {
    return Button(action: {
      self.dataflow.acceptOredr()
    }) {
      HStack {
        Text("ACCEPT RIDE")
          .lineLimit(2)
          .scaledToFill()
          .padding()
          .foregroundColor(Color.white)
        Spacer()
        Image("➞")
          .padding()
          .foregroundColor(Color.white)
      }
    }
    .frame(height: 70)
    .background(Color(hex: "50E3C2"))
    .cornerRadius(5)
    .padding(.top, 25)
  }

  func pulse() -> some View {
    GeometryReader { _ in
      ZStack {
        Circle()
          .stroke(Color(hex: "50E3C2"), lineWidth: 1)
          .background(Color.clear)
          .scaleEffect(self.pulsate ? 2.8 : 0)
          .opacity(self.pulsate ? 0 : 1)
          .animation(Animation.easeOut(duration: 3)
            .repeatForever(autoreverses: false))
        Circle()
          .stroke(Color(hex: "50E3C2"), lineWidth: 1)
          .background(Color.clear)
          .scaleEffect(self.pulsate ? 2.8 : 0)
          .opacity(self.pulsate ? 0 : 1)
          .animation(Animation.easeOut(duration: 3.5)
            .repeatForever(autoreverses: false))
          .onAppear {
            self.pulsate.toggle()
          }
        Circle()
          .stroke(Color(hex: "50E3C2"), lineWidth: 1)
          .background(Color.clear)
          .scaleEffect(self.pulsate ? 2.8 : 0)
          .opacity(self.pulsate ? 0 : 1)
          .animation(Animation.easeOut(duration: 4)
            .repeatForever(autoreverses: false))
      }
    }
  }
}

struct ViewCard: View {
  @ObservedObject var dataflow: DriverDataFlow

  var body: some View {
    VStack {
      VStack {
        Text("PICKUP")
          .padding([.top, .trailing])
          .padding(.leading, 25)
          .font(.system(size: 12))
          .foregroundColor(Color.gray)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(self.dataflow.selectedOrder?.pickup.address ?? "")
          .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
          .padding(.trailing)
          .padding(.top, 5)
          .padding(.leading, 25)
          .lineLimit(nil)
      }
      HStack {
        Image("female")
          .padding(.leading)
          .padding([.bottom, .top], 10)
        HStack {
          Text(self.dataflow.selectedOrder?.rider.name ?? "")
          Spacer()
          Text("4.8")
            .padding(.trailing)
            .padding([.bottom, .top], 10)
            .foregroundColor(.gray)
            .font(.subheadline)
        }
        Spacer()
      }
      .background(Color(hex: "F9FAFC"))
    }
    .background(Color.white)
    .cornerRadius(4)
    .shadow(radius: 4)
    .padding(.top, 15)
    .padding([.leading, .trailing], 35)
  }
}

/// Simple map for AcceptView
extension AcceptView {
  struct MapView: UIViewRepresentable {
    var annotation: OrderAnnotation

    func makeUIView(context: Context) -> MKMapView {
      let map = MKMapView()
      map.delegate = context.coordinator
      map.showsUserLocation = false
      return map
    }

    func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    func updateUIView(_ uiView: MKMapView, context _: Context) {
      uiView.removeAnnotations(uiView.annotations)
      uiView.addAnnotation(annotation)
      let viewRegion = MKCoordinateRegion(
        center: annotation.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
      )
      uiView.setRegion(uiView.regionThatFits(viewRegion), animated: true)
      uiView.isUserInteractionEnabled = false
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
      var control: MapView

      init(_ control: MapView) {
        self.control = control
      }

      func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(
          withIdentifier: reuseIdentifier
        )
        if annotationView == nil {
          annotationView = MKAnnotationView(
            annotation: annotation,
            reuseIdentifier: reuseIdentifier
          )
          annotationView?.canShowCallout = true
        } else {
          annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "order_pin_icon")
        return annotationView
      }
    }
  }
}
