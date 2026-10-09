import Foundation
import ServiceManagement

/// Open at Login via `SMAppService` (macOS 13+). Shows up in System Settings > General > Login Items.
enum LaunchAtLoginManager {
  private static let defaultAppliedKey = "launchAtLoginDefaultApplied"
  private static let legacyLabels = [AppSettings.launchAgentLabel, "com.linkjf.cursor-usage-menubar"]

  private static var service: SMAppService { .mainApp }

  /// Registered and active, or registered and waiting for approval in System Settings.
  static var isRegistered: Bool {
    switch service.status {
    case .enabled, .requiresApproval: return true
    default: return false
    }
  }

  static var requiresApproval: Bool {
    service.status == .requiresApproval
  }

  /// Turns Open at Login on the first time this install runs from the app bundle.
  /// Later changes made by the user are respected.
  static func applyDefaultOnFirstLaunch() {
    guard Bundle.main.bundlePath.hasSuffix(".app") else { return }
    let defaults = UserDefaults.standard
    guard !defaults.bool(forKey: defaultAppliedKey) else { return }
    if setEnabled(true) {
      defaults.set(true, forKey: defaultAppliedKey)
    }
  }

  @discardableResult
  static func setEnabled(_ enabled: Bool) -> Bool {
    if enabled {
      do {
        try service.register()
        return true
      } catch {
        return false
      }
    }

    try? service.unregister()
    return true
  }

  /// Deletes LaunchAgent plists written by earlier builds. Login is handled by the Login Item now.
  static func removeLegacyLaunchAgents() {
    let agents = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    for label in legacyLabels {
      try? FileManager.default.removeItem(at: agents.appendingPathComponent("\(label).plist"))
    }
  }
}
