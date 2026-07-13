import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case es

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .en: return "English"
        case .es: return "Español"
        }
    }
}

enum MenuBarLayout: String, CaseIterable, Identifiable {
    case compact
    case stacked

    var id: String { rawValue }
}

enum AppSettings {
    static let launchAtLoginKey = "launchAtLogin"
    static let appLanguageKey = "appLanguage"
    static let menuBarLayoutKey = "menuBarLayout"
    static let menuBarColorsKey = "menuBarColors"

    static let launchAgentLabel = "com.cursorusage.menubar"
    static let appBundlePath = "\(NSHomeDirectory())/Applications/Cursor Usage Menubar.app/Contents/MacOS/CursorUsageMenubar"

    static let menuBarAppearanceDidChange = Notification.Name("menuBarAppearanceDidChange")
}
