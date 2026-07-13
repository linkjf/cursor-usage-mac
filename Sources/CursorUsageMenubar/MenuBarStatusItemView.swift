import AppKit

/// Standard menu bar item metrics (NSStatusBar.system.thickness, monospaced digits).
enum MenuBarMetrics {
  static var thickness: CGFloat { NSStatusBar.system.thickness }
  static let horizontalPadding: CGFloat = 6
  static let heroFontSize: CGFloat = 11
  static let contextFontSize: CGFloat = 9
  static let stackSpacing: CGFloat = -1
}

struct MenuBarPresentation {
  let hero: String
  let context: String
  let stacked: Bool
  let tier: UsageTier
  let colorsEnabled: Bool
}

@MainActor
final class MenuBarStatusItemView: NSView {
  private let stackView = NSStackView()
  private let heroLabel = MenuBarLabelField()
  private let contextLabel = MenuBarLabelField()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    configure()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  private func configure() {
    wantsLayer = false

    stackView.orientation = .vertical
    stackView.alignment = .centerX
    stackView.spacing = MenuBarMetrics.stackSpacing
    stackView.distribution = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false

    heroLabel.font = NSFont.monospacedDigitSystemFont(ofSize: MenuBarMetrics.heroFontSize, weight: .semibold)
    contextLabel.font = NSFont.monospacedDigitSystemFont(ofSize: MenuBarMetrics.contextFontSize, weight: .medium)

    stackView.addArrangedSubview(heroLabel)
    stackView.addArrangedSubview(contextLabel)
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
    ])
  }

  func apply(_ presentation: MenuBarPresentation) {
    let appearance = effectiveAppearance
    let heroColor = presentation.colorsEnabled
      ? presentation.tier.menuBarNSColor(for: appearance)
      : NSColor.labelColor

    heroLabel.stringValue = presentation.hero
    heroLabel.textColor = heroColor

    if presentation.stacked, !presentation.context.isEmpty {
      contextLabel.stringValue = presentation.context
      contextLabel.textColor = NSColor.labelColor
      contextLabel.isHidden = false
    } else {
      contextLabel.isHidden = true
    }

    frame.size = preferredSize()
    needsLayout = true
    layoutSubtreeIfNeeded()
  }

  func preferredSize() -> NSSize {
    let heroWidth = measuredWidth(for: heroLabel)
    let contextWidth = contextLabel.isHidden ? 0 : measuredWidth(for: contextLabel)
    let contentWidth = max(heroWidth, contextWidth) + MenuBarMetrics.horizontalPadding * 2
    return NSSize(width: ceil(contentWidth), height: MenuBarMetrics.thickness)
  }

  private func measuredWidth(for label: NSTextField) -> CGFloat {
    guard let font = label.font else { return 0 }
    return ceil((label.stringValue as NSString).size(withAttributes: [.font: font]).width)
  }
}

private final class MenuBarLabelField: NSTextField {
  init() {
    super.init(frame: .zero)
    isBezeled = false
    isEditable = false
    isSelectable = false
    drawsBackground = false
    alignment = .center
    lineBreakMode = .byTruncatingTail
    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension UsageTier {
  func menuBarNSColor(for appearance: NSAppearance) -> NSColor {
    let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    switch self {
    case .safe:
      return isDark
        ? NSColor(srgbRed: 0.34, green: 0.92, blue: 0.58, alpha: 1)
        : NSColor(srgbRed: 0.08, green: 0.58, blue: 0.28, alpha: 1)
    case .caution:
      return isDark
        ? NSColor(srgbRed: 1.00, green: 0.84, blue: 0.28, alpha: 1)
        : NSColor(srgbRed: 0.72, green: 0.48, blue: 0.00, alpha: 1)
    case .warning:
      return isDark
        ? NSColor(srgbRed: 1.00, green: 0.62, blue: 0.24, alpha: 1)
        : NSColor(srgbRed: 0.82, green: 0.34, blue: 0.00, alpha: 1)
    case .critical:
      return isDark
        ? NSColor(srgbRed: 1.00, green: 0.40, blue: 0.42, alpha: 1)
        : NSColor(srgbRed: 0.82, green: 0.12, blue: 0.16, alpha: 1)
    }
  }
}
