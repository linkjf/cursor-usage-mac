import AppKit
import Darwin
import Foundation

enum SingleInstanceGuard {
  private static var lockDescriptor: Int32 = -1

  private static var lockURL: URL {
    let support = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Application Support/Cursor Usage Menubar", isDirectory: true)
    try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
    return support.appendingPathComponent("single-instance.lock")
  }

  /// Returns `true` if this process should continue. Otherwise quit immediately.
  @discardableResult
  static func acquire() -> Bool {
    let path = lockURL.path
    let fd = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard fd >= 0 else {
      return fallbackAcquire()
    }

    if flock(fd, LOCK_EX | LOCK_NB) == 0 {
      lockDescriptor = fd
      terminateOtherInstances()
      return true
    }

    close(fd)
    activateExistingInstance()
    return false
  }

  static func release() {
    guard lockDescriptor >= 0 else { return }
    flock(lockDescriptor, LOCK_UN)
    close(lockDescriptor)
    lockDescriptor = -1
  }

  /// Fallback when lock file cannot be created (e.g. sandbox).
  private static func fallbackAcquire() -> Bool {
    let bundleID = Bundle.main.bundleIdentifier ?? AppSettings.launchAgentLabel
    let currentPID = ProcessInfo.processInfo.processIdentifier
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
      .filter { $0.processIdentifier != currentPID }

    if others.isEmpty { return true }

    activateExistingInstance()
    return false
  }

  private static func terminateOtherInstances() {
    let bundleID = Bundle.main.bundleIdentifier ?? AppSettings.launchAgentLabel
    let currentPID = ProcessInfo.processInfo.processIdentifier

    for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
      if app.processIdentifier != currentPID {
        app.terminate()
      }
    }
  }

  private static func activateExistingInstance() {
    let bundleID = Bundle.main.bundleIdentifier ?? AppSettings.launchAgentLabel
    let currentPID = ProcessInfo.processInfo.processIdentifier

    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
      .first { $0.processIdentifier != currentPID }?
      .activate(options: [.activateIgnoringOtherApps])
  }
}
