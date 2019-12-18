import Foundation

public struct Time {
  public let totalSeconds: Int
  public var years: Int {
    return totalSeconds / 31_536_000
  }

  public var days: Int {
    return (totalSeconds % 31_536_000) / 86400
  }

  public var hours: Int {
    return (totalSeconds % 86400) / 3600
  }

  public var minutes: Int {
    return (totalSeconds % 3600) / 60
  }

  public var seconds: Int {
    return totalSeconds % 60
  }

  public var hoursMinutesAndSeconds: (hours: Int, minutes: Int, seconds: Int) {
    return (hours, minutes, seconds)
  }

  public enum TimeUnit: String {
    case mins
    case hours
  }

  public init(_ totalSeconds: Int) {
    self.totalSeconds = totalSeconds
  }
}

extension Time {
  public var toSrting: String {
    let hoursText = timeText(from: hours, timeUnit: .hours)
    let minutesText = timeText(from: minutes, timeUnit: .mins)
    return "\(hoursText)\(minutesText)"
  }

  private func timeText(from number: Int, timeUnit: TimeUnit) -> String {
    if number > 0 {
      return " \(number) \(timeUnit.rawValue)"
    }
    return ""
  }
}
