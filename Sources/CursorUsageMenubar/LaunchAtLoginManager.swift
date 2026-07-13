import Foundation

enum LaunchAtLoginManager {
  static var plistURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents/\(AppSettings.launchAgentLabel).plist")
  }

  static var isEnabled: Bool {
    FileManager.default.fileExists(atPath: plistURL.path)
  }

  @discardableResult
  static func setEnabled(_ enabled: Bool) -> Bool {
    if enabled {
      return install()
    }
    return uninstall()
  }

  @discardableResult
  static func install() -> Bool {
    let appPath = "\(NSHomeDirectory())/Applications/Cursor Usage Menubar.app/Contents/MacOS/CursorUsageMenubar"
    guard FileManager.default.fileExists(atPath: appPath) else { return false }

    let plist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>\(AppSettings.launchAgentLabel)</string>
      <key>ProgramArguments</key>
      <array>
        <string>\(appPath)</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
    </dict>
    </plist>
    """

    do {
      try FileManager.default.createDirectory(
        at: plistURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try plist.write(to: plistURL, atomically: true, encoding: .utf8)
      let uid = getuid()
      _ = shell("launchctl bootout gui/\(uid)/\(AppSettings.launchAgentLabel)")
      let code = shell("launchctl bootstrap gui/\(uid) '\(plistURL.path)'")
      return code == 0
    } catch {
      return false
    }
  }

  @discardableResult
  static func uninstall() -> Bool {
    let uid = getuid()
    _ = shell("launchctl bootout gui/\(uid)/\(AppSettings.launchAgentLabel)")
    try? FileManager.default.removeItem(at: plistURL)
    return true
  }

  @discardableResult
  private static func shell(_ command: String) -> Int32 {
    let process = Process()
    process.launchPath = "/bin/zsh"
    process.arguments = ["-lc", command]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus
    } catch {
      return -1
    }
  }
}
