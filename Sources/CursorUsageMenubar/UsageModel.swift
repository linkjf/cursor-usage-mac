import Foundation

@MainActor
final class UsageModel: ObservableObject {
  @Published var snapshot: UsageSnapshot?
  @Published var statusText = "…"
  @Published var menuBarHero = "…"
  @Published var menuBarContext = ""
  @Published var menuBarStacked = false
  @Published var menuBarColorsEnabled = UserDefaults.standard.bool(forKey: AppSettings.menuBarColorsKey)
  @Published var menuBarLayoutRaw = UserDefaults.standard.string(forKey: AppSettings.menuBarLayoutKey) ?? MenuBarLayout.compact.rawValue
  @Published var appLanguageRaw = UserDefaults.standard.string(forKey: AppSettings.appLanguageKey) ?? AppLanguage.system.rawValue
  @Published var statusTier: UsageTier = .safe
  @Published var appearanceRevision = 0
  @Published var errorText: String?
  @Published var isRefreshing = false
  @Published var switchingAccount = false
  @Published var showSettings = false

  @Published var lastSuccessAt: Date?

  var menuBarTooltip: String? {
    guard let usage = snapshot else { return nil }
    var lines = [
      String(format: L10n.text(.tooltipAPI), usage.apiPercentUsed, usage.apiPercentRemaining),
      String(format: L10n.text(.tooltipAuto), usage.autoPercentUsed),
      String(format: L10n.text(.tooltipTotal), usage.totalPercentUsed),
    ]
    if let updated = relativeLastUpdated() {
      lines.append(updated)
    }
    return lines.joined(separator: "\n")
  }

  private var openTimer: Timer?
  private var safetyTimer: Timer?
  private var transcriptWatcher: TranscriptWatcher?
  private var authWatcher: AuthWatcher?
  private var started = false
  private var lastSuccessfulFetchAt: Date?
  private var inFlight = false
  private var lastAccountFingerprint: String?

  private let fetcher: UsageFetching
  private let minRefreshGap: TimeInterval = 45
  private let openRefreshInterval: TimeInterval = 90
  private let safetyRefreshInterval: TimeInterval = 300

  init(fetcher: UsageFetching = LiveUsageFetcher()) {
    self.fetcher = fetcher
  }

  func start() {
    guard !started else { return }
    started = true

    transcriptWatcher = TranscriptWatcher { [weak self] in
      Task { @MainActor in
        await self?.refresh(force: false)
      }
    }
    transcriptWatcher?.start()

    authWatcher = AuthWatcher { [weak self] in
      Task { @MainActor in
        await self?.handleAccountChange()
      }
    }
    authWatcher?.start()

    safetyTimer = Timer.scheduledTimer(withTimeInterval: safetyRefreshInterval, repeats: true) { [weak self] _ in
      Task { @MainActor in
        await self?.refresh(force: false)
      }
    }

    Task { await refresh(force: true) }
  }

  func setMenuVisible(_ visible: Bool) {
    openTimer?.invalidate()
    openTimer = nil

    if visible {
      Task { await refresh(force: true) }
      openTimer = Timer.scheduledTimer(withTimeInterval: openRefreshInterval, repeats: true) { [weak self] _ in
        Task { @MainActor in
          await self?.refresh(force: false)
        }
      }
    }
  }

  func handleAccountChange() async {
    guard let fingerprint = try? fetcher.currentAccountFingerprint() else { return }
    guard fingerprint != lastAccountFingerprint else { return }

    lastAccountFingerprint = fingerprint
    switchingAccount = true
    snapshot = nil
    statusText = "…"
    menuBarHero = "…"
    menuBarContext = ""
    fetcher.clearTokenCache()
    await refresh(force: true)
    switchingAccount = false
  }

  func refresh(force: Bool = true) async {
    if inFlight { return }
    if !force, let lastSuccessfulFetchAt, Date().timeIntervalSince(lastSuccessfulFetchAt) < minRefreshGap {
      return
    }

    inFlight = true
    isRefreshing = true
    defer {
      inFlight = false
      isRefreshing = false
    }

    if lastAccountFingerprint == nil {
      lastAccountFingerprint = try? fetcher.currentAccountFingerprint()
    }

    do {
      let usage = try await fetcher.fetch()
      snapshot = usage
      errorText = nil
      lastSuccessAt = Date()
      lastSuccessfulFetchAt = Date()
      applyMenuBar(from: usage)
    } catch {
      errorText = error.localizedDescription
      if snapshot == nil {
        statusText = "?"
        menuBarHero = "?"
        menuBarContext = ""
        statusTier = .warning
      }
    }
  }

  func refreshMenuBarLabel() {
    guard let usage = snapshot else { return }
    applyMenuBar(from: usage)
    bumpAppearance()
  }

  func setMenuBarColorsEnabled(_ enabled: Bool) {
    menuBarColorsEnabled = enabled
    UserDefaults.standard.set(enabled, forKey: AppSettings.menuBarColorsKey)
    bumpAppearance()
  }

  func setMenuBarLayout(_ layout: String) {
    menuBarLayoutRaw = layout
    UserDefaults.standard.set(layout, forKey: AppSettings.menuBarLayoutKey)
    refreshMenuBarLabel()
  }

  func setAppLanguage(_ language: String) {
    appLanguageRaw = language
    UserDefaults.standard.set(language, forKey: AppSettings.appLanguageKey)
    bumpAppearance()
  }

  func bumpAppearance() {
    appearanceRevision &+= 1
  }

  private func applyMenuBar(from usage: UsageSnapshot) {
    menuBarStacked = menuBarLayoutRaw == MenuBarLayout.stacked.rawValue

    if menuBarStacked {
      let stacked = usage.menuBarStackedLabel()
      menuBarHero = stacked.top
      menuBarContext = stacked.bottom
      statusText = "\(stacked.top)\n\(stacked.bottom)"
    } else {
      menuBarHero = "\(usage.apiPercentUsed)%"
      menuBarContext = ""
      statusText = menuBarHero
    }
    statusTier = usage.apiTier
  }

  func relativeLastUpdated() -> String? {
    guard let lastSuccessAt else { return nil }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return String(format: L10n.text(.lastUpdated), formatter.localizedString(for: lastSuccessAt, relativeTo: Date()))
  }
}
