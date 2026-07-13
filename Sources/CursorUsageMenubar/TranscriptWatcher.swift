import CoreServices
import Foundation

final class TranscriptWatcher {
  private var stream: FSEventStreamRef?
  private var retryTimer: Timer?
  private let callback: () -> Void
  private var debounce: DispatchWorkItem?
  private let queue = DispatchQueue(label: "cursor-usage.transcripts", qos: .utility)

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

    let watchPath = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".cursor/projects").path
    guard FileManager.default.fileExists(atPath: watchPath) else { return }

    let paths = [watchPath] as CFArray
    var context = FSEventStreamContext(
      version: 0,
      info: Unmanaged.passUnretained(self).toOpaque(),
      retain: { info in
        UnsafeRawPointer(Unmanaged<TranscriptWatcher>.fromOpaque(info!).retain().toOpaque())
      },
      release: { info in _ = Unmanaged<TranscriptWatcher>.fromOpaque(info!).autorelease() },
      copyDescription: nil
    )

    let flags = FSEventStreamCreateFlags(
      kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents
    )

    stream = FSEventStreamCreate(
      nil,
      { _, info, numEvents, eventPaths, _, _ in
        guard let info, let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else {
          return
        }
        let watcher = Unmanaged<TranscriptWatcher>.fromOpaque(info).takeUnretainedValue()
        for index in 0..<numEvents where watcher.shouldHandle(path: paths[index]) {
          watcher.scheduleRefresh()
          return
        }
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

  private func shouldHandle(path: String) -> Bool {
    path.contains("/agent-transcripts/") && path.hasSuffix(".jsonl")
  }

  private func scheduleRefresh() {
    debounce?.cancel()
    let work = DispatchWorkItem { [weak self] in self?.callback() }
    debounce = work
    queue.asyncAfter(deadline: .now() + 2.0, execute: work)
  }

  deinit { stop() }
}
