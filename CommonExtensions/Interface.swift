import Combine
import Foundation
import SwiftUI

/// For hide keyboard needed
public extension UIApplication {
  func endEditing() {
    sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
  }
}

/// Make color for hex value
public extension Color {
  init(hex: String) {
    let scanner = Scanner(string: hex)
    var rgbValue: UInt64 = 0
    scanner.scanHexInt64(&rgbValue)
    let r = (rgbValue & 0xFF0000) >> 16
    let g = (rgbValue & 0xFF00) >> 8
    let b = rgbValue & 0xFF
    self.init(
      red: Double(r) / 0xFF,
      green: Double(g) / 0xFF,
      blue: Double(b) / 0xFF
    )
  }
}

/// Custom Horizontal Alignment
extension HorizontalAlignment {
  public enum Custom: AlignmentID {
    public static func defaultValue(in d: ViewDimensions) -> CGFloat { d[
      HorizontalAlignment.center
    ] }
  }

  public static let custom = HorizontalAlignment(Custom.self)
}

/// Encodable extension with converter func from Object to Dictionary
public extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(
      with: data,
      options: .allowFragments
    ) as? [String: Any] else {
      throw NSError()
    }
    return dictionary
  }
}

extension DateFormatter {
  public static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

public extension Date {
  func timeAgoSinceDate() -> String {
    /// From Time
    let fromDate = self
    /// To Time
    let toDate = Date()
    /// Estimation
    /// Year
    if let interval = Calendar.current.dateComponents(
      [.year],
      from: fromDate,
      to: toDate
    ).year, interval > 0 {
      return interval == 1 ? "\(interval)" + " " + "year ago" : "\(interval)" + " " + "years ago"
    }
    /// Month
    if let interval = Calendar.current.dateComponents(
      [.month],
      from: fromDate,
      to: toDate
    ).month, interval > 0 {
      return interval == 1 ? "\(interval)" + " " + "month ago" : "\(interval)" + " " + "months ago"
    }
    /// Day
    if let interval = Calendar.current.dateComponents(
      [.day],
      from: fromDate,
      to: toDate
    ).day, interval > 0 {
      return interval == 1 ? "\(interval)" + " " + "day ago" : "\(interval)" + " " + "days ago"
    }
    /// Hours
    if let interval = Calendar.current.dateComponents(
      [.hour],
      from: fromDate,
      to: toDate
    ).hour, interval > 0 {
      return interval == 1 ? "\(interval)" + " " + "hour ago" : "\(interval)" + " " + "hours ago"
    }
    /// Minute
    if let interval = Calendar.current.dateComponents(
      [.minute],
      from: fromDate,
      to: toDate
    ).minute, interval > 0 {
      return interval == 1 ? "\(interval)" + " " + "minute ago" : "\(interval)" + " " + "minutes ago"
    }
    return "a moment ago"
  }
}
