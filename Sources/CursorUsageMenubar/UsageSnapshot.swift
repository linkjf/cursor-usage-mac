import Foundation

struct UsageSnapshot: Equatable {
  let membership: String
  let accountEmail: String?
  let totalPercentUsed: Int
  let autoPercentUsed: Int
  let apiPercentUsed: Int
  let limitCents: Int?
  let remainingCents: Int?
  let autoMessage: String?
  let apiMessage: String?
  let cycleEnd: String

  var apiPercentRemaining: Int { max(0, min(100, 100 - apiPercentUsed)) }
  var apiTier: UsageTier { .forRemaining(apiPercentRemaining) }

  var membershipLabel: String {
    membership.replacingOccurrences(of: "_", with: " ").capitalized
  }

  func menuBarCompactLabel() -> String {
    "\(apiPercentRemaining)% | \(autoPercentUsed)/\(totalPercentUsed)"
  }

  func menuBarStackedLabel() -> (top: String, bottom: String) {
    ("\(apiPercentRemaining)%", "\(autoPercentUsed)/\(totalPercentUsed)")
  }

  func adviceTitle() -> String {
    if apiPercentUsed >= 80 { return L10n.text(.adviceUseAuto) }
    if apiPercentUsed >= 60 { return L10n.text(.adviceCarefulAPI) }
    if autoPercentUsed >= 70 { return L10n.text(.adviceAutoHigh) }
    return L10n.text(.adviceAPIMargin)
  }

  func adviceBody() -> String {
    if apiPercentUsed >= 80 { return L10n.text(.adviceBodyAuto) }
    if apiPercentUsed >= 60 {
      return String(format: L10n.text(.adviceBodyCareful), max(0, apiPercentRemaining))
    }
    if autoPercentUsed >= 70 { return L10n.text(.adviceBodyAutoHigh) }
    return L10n.text(.adviceBodyMargin)
  }

  func formattedCycleEnd() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: cycleEnd) {
      return date.formatted(date: .abbreviated, time: .omitted)
    }
    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: cycleEnd) {
      return date.formatted(date: .abbreviated, time: .omitted)
    }
    return cycleEnd
  }

  var apiAttributedRemainingCents: Int? {
    guard let limitCents, limitCents > 0 else { return nil }
    return max(0, limitCents - Int((Double(limitCents) * Double(apiPercentUsed) / 100.0).rounded()))
  }

  var poolRemainingDollars: Double? {
    guard let remainingCents else { return nil }
    return Double(remainingCents) / 100.0
  }
}
