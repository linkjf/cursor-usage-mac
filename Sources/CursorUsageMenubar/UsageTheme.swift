import AppKit
import SwiftUI

enum UsageTier: Equatable {
  case safe
  case caution
  case warning
  case critical

  static func forRemaining(_ remaining: Int) -> UsageTier {
    switch remaining {
    case 60...: return .safe
    case 40..<60: return .caution
    case 20..<40: return .warning
    default: return .critical
    }
  }

  var color: Color {
    switch self {
    case .safe: return Color(red: 0.30, green: 0.82, blue: 0.55)
    case .caution: return Color(red: 0.98, green: 0.78, blue: 0.28)
    case .warning: return Color(red: 1.00, green: 0.58, blue: 0.22)
    case .critical: return Color(red: 1.00, green: 0.36, blue: 0.38)
    }
  }

  var menuBarNSColor: NSColor {
    menuBarNSColor(for: NSApp?.effectiveAppearance ?? NSAppearance(named: .aqua)!)
  }

  var label: String {
    switch self {
    case .safe: return L10n.text(.tierSafe)
    case .caution: return L10n.text(.tierCaution)
    case .warning: return L10n.text(.tierWarning)
    case .critical: return L10n.text(.tierCritical)
    }
  }
}

enum UsageTheme {
  static let panelWidth: CGFloat = 320

  static func surfaceBase(_ scheme: ColorScheme) -> Color {
    scheme == .dark ? Color(red: 0.10, green: 0.11, blue: 0.13) : Color(red: 0.96, green: 0.96, blue: 0.97)
  }

  static func surfaceRaised(_ scheme: ColorScheme) -> Color {
    scheme == .dark ? Color(red: 0.14, green: 0.15, blue: 0.18) : Color.white
  }

  static func borderSubtle(_ scheme: ColorScheme) -> Color {
    scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
  }

  static func textPrimary(_ scheme: ColorScheme) -> Color {
    scheme == .dark ? .white : Color(red: 0.12, green: 0.13, blue: 0.15)
  }

  static func textSecondary(_ scheme: ColorScheme) -> Color {
    scheme == .dark ? Color.white.opacity(0.58) : Color.black.opacity(0.55)
  }

  static func textTertiary(_ scheme: ColorScheme) -> Color {
    scheme == .dark ? Color.white.opacity(0.36) : Color.black.opacity(0.38)
  }

  static let accentAuto = Color(red: 0.45, green: 0.86, blue: 0.98)
  static let accentAPI = Color(red: 0.55, green: 0.58, blue: 1.00)
}
