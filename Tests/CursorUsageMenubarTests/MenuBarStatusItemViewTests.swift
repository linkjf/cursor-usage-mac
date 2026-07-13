import XCTest
@testable import CursorUsageMenubar

@MainActor
final class MenuBarStatusItemViewTests: XCTestCase {
  func testCompactPreferredSizeUsesMenuBarThickness() {
    let view = MenuBarStatusItemView(frame: .zero)
    view.apply(MenuBarPresentation(
      hero: "49%",
      context: "8/17",
      stacked: false,
      tier: .caution,
      colorsEnabled: false
    ))

    let size = view.preferredSize()
    XCTAssertEqual(size.height, MenuBarMetrics.thickness)
    XCTAssertGreaterThan(size.width, 20)
  }

  func testStackedPreferredSizeIsWiderWhenContextIsLonger() {
    let compact = MenuBarStatusItemView(frame: .zero)
    compact.apply(MenuBarPresentation(
      hero: "9%",
      context: "",
      stacked: false,
      tier: .critical,
      colorsEnabled: false
    ))

    let stacked = MenuBarStatusItemView(frame: .zero)
    stacked.apply(MenuBarPresentation(
      hero: "9%",
      context: "88/99",
      stacked: true,
      tier: .critical,
      colorsEnabled: false
    ))

    XCTAssertGreaterThan(stacked.preferredSize().width, compact.preferredSize().width)
  }
}
