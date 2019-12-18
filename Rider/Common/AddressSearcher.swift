import Combine
import CommonModels
import MapKit
import SwiftUI
import Utility

final class AddressSearcher: NSObject, ObservableObject {
  /// Subject that provide complition search with `MKLocalSearchCompleter`
  var didChangePickedPlace = PassthroughSubject<Order.Place?, Never>()
  /// A utility object for generating a list of completion strings
  /// based on a partial search string that you provide.
  private var searchCompleter = MKLocalSearchCompleter()
  /// List of completion address strings
  @Published var searchResult: [MKLocalSearchCompletion] = []
  /// String that provide user local address search
  @Published var searchString: String = "" {
    willSet { makeSearch(searchString: newValue) }
  }

  /// Pickerd place from list
  @Published var pickedPlace: Order.Place? {
    willSet { didChangePickedPlace.send(newValue) }
  }

  override init() {
    searchCompleter = MKLocalSearchCompleter()
    super.init()

    searchCompleter.delegate = self
  }

  func makeSearch(searchString: String) {
    searchCompleter.queryFragment = searchString
  }

  func pickPlace(place: MKLocalSearchCompletion) {
    MKLocalSearch.getSearch(search: place).start { response, _ in
      let items = response?.mapItems ?? []
      guard let first = items.first else { return }
      let order = Order.Place(
        latitude: Float(first.placemark.coordinate.latitude),
        longitude: Float(first.placemark.coordinate.longitude),
        address: "\(place.title)"
      )
      DispatchQueue.main.async { self.pickedPlace = order }
    }
  }

  func removeSearchResult() {
    searchString = ""
    searchResult.removeAll()
  }
}

extension AddressSearcher: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    searchResult = completer.results
  }
}
