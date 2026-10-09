import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var model: UsageModel?
  private var statusBar: StatusBarController?
  private var isPrimaryInstance = false

  func applicationWillFinishLaunching(_ notification: Notification) {
    isPrimaryInstance = SingleInstanceGuard.acquire()
    if !isPrimaryInstance {
      NSApp.terminate(nil)
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    guard isPrimaryInstance else { return }

    LaunchAtLoginManager.removeLegacyLaunchAgents()
    LaunchAtLoginManager.applyDefaultOnFirstLaunch()

    let model = UsageModel()
    self.model = model
    self.statusBar = StatusBarController(model: model)
    model.start()
  }

  func applicationWillTerminate(_ notification: Notification) {
    SingleInstanceGuard.release()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
}
