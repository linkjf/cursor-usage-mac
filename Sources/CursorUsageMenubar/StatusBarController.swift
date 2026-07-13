import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
  private let model: UsageModel
  private let statusItem: NSStatusItem
  private let menuBarView: MenuBarStatusItemView
  private var popover: NSPopover?
  private var cancellables = Set<AnyCancellable>()

  init(model: UsageModel) {
    self.model = model
    self.menuBarView = MenuBarStatusItemView(
      frame: NSRect(x: 0, y: 0, width: 48, height: MenuBarMetrics.thickness)
    )
    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()
    installStatusView()
    observeModel()
    updatePresentation()
  }

  private func installStatusView() {
    guard let button = statusItem.button else { return }

    button.subviews.forEach { $0.removeFromSuperview() }
    button.attributedTitle = NSAttributedString(string: "")
    button.title = ""
    button.image = nil
    button.imagePosition = .noImage

    menuBarView.translatesAutoresizingMaskIntoConstraints = false
    button.addSubview(menuBarView)

    NSLayoutConstraint.activate([
      menuBarView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
      menuBarView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      menuBarView.heightAnchor.constraint(equalToConstant: MenuBarMetrics.thickness),
      menuBarView.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 2),
      menuBarView.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -2),
    ])

    button.target = self
    button.action = #selector(togglePopover(_:))
    button.sendAction(on: [.leftMouseUp])
  }

  private func observeModel() {
    let appearance = Publishers.CombineLatest4(
      model.$menuBarHero,
      model.$menuBarContext,
      model.$menuBarStacked,
      model.$menuBarColorsEnabled
    )
    let state = Publishers.CombineLatest4(
      model.$statusTier,
      model.$isRefreshing,
      model.$switchingAccount,
      model.$lastSuccessAt
    )

    appearance
      .combineLatest(state)
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.updatePresentation()
      }
      .store(in: &cancellables)
  }

  private func updatePresentation() {
    let loading = model.isRefreshing || model.switchingAccount
    menuBarView.apply(
      MenuBarPresentation(
        hero: model.menuBarHero,
        context: model.menuBarContext,
        stacked: model.menuBarStacked,
        tier: model.statusTier,
        colorsEnabled: model.menuBarColorsEnabled && !loading
      )
    )
    menuBarView.toolTip = model.menuBarTooltip
    statusItem.length = menuBarView.preferredSize().width + 4
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    let popover = ensurePopover()

    if popover.isShown {
      closePopover()
      return
    }

    model.setMenuVisible(true)
    showPopover(anchoredTo: button)
    popover.contentViewController?.view.window?.makeKey()
  }

  private func showPopover(anchoredTo button: NSStatusBarButton) {
    let popover = ensurePopover()
    let anchor = NSRect(
      x: button.bounds.midX - 0.5,
      y: button.bounds.minY,
      width: 1,
      height: button.bounds.height
    )
    popover.show(relativeTo: anchor, of: button, preferredEdge: .minY)
  }

  private func ensurePopover() -> NSPopover {
    if let popover { return popover }

    let popover = NSPopover()
    popover.behavior = .transient
    popover.delegate = self
    popover.animates = true
    popover.contentSize = NSSize(width: UsageTheme.panelWidth, height: 360)

    let root = UsageMenuView()
      .environmentObject(model)
      .id(model.appLanguageRaw)

    let host = NSHostingController(rootView: root)
    if #available(macOS 13.0, *) {
      host.sizingOptions = [.intrinsicContentSize]
    }
    popover.contentViewController = host
    self.popover = popover
    return popover
  }

  private func closePopover() {
    popover?.performClose(nil)
    model.setMenuVisible(false)
  }

  func popoverDidClose(_ notification: Notification) {
    model.setMenuVisible(false)
  }
}
