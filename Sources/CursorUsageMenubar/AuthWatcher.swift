import CoreServices
import Foundation

final class AuthWatcher {
  private var stream: FSEventStreamRef?
  private var retryTimer: Timer?
  private let callback: () -> Void
  private var debounce: DispatchWorkItem?
  private let queue = DispatchQueue(label: "cursor-usage.auth", qos: .utility)

  init(callback: @escaping () -> Void) {
    self.callback = callback
  }

  func start() {
    attemptStart()
    retryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      self?.attemptStart()
    }
  }

  func stop() {
    retryTimer?.invalidate()
    retryTimer = nil
    if let stream {
      FSEventStreamStop(stream)
      FSEventStreamInvalidate(stream)
      FSEventStreamRelease(stream)
      self.stream = nil
    }
  }

  private func attemptStart() {
    guard stream == nil else { return }

    let path = LiveUsageFetcher.dbPath().path
    guard FileManager.default.fileExists(atPath: path) else { return }

    let paths = [path] as CFArray
    var context = FSEventStreamContext(
      version: 0,
      info: Unmanaged.passUnretained(self).toOpaque(),
      retain: { info in
        UnsafeRawPointer(Unmanaged<AuthWatcher>.fromOpaque(info!).retain().toOpaque())
      },
      release: { info in _ = Unmanaged<AuthWatcher>.fromOpaque(info!).autorelease() },
      copyDescription: nil
    )

    let flags = FSEventStreamCreateFlags(
      kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents
    )

    stream = FSEventStreamCreate(
      nil,
      { _, info, _, _, _, _ in
        guard let info else { return }
        Unmanaged<AuthWatcher>.fromOpaque(info).takeUnretainedValue().scheduleRefresh()
      },
      &context,
      paths,
      FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
      1.0,
      flags
    )

    if let stream {
      FSEventStreamSetDispatchQueue(stream, queue)
      FSEventStreamStart(stream)
    }
  }

  private func scheduleRefresh() {
    debounce?.cancel()
    let work = DispatchWorkItem { [weak self] in self?.callback() }
    debounce = work
    queue.asyncAfter(deadline: .now() + 1.0, execute: work)
  }

  deinit { stop() }
}
