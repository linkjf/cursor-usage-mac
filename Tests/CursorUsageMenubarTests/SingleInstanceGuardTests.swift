import XCTest
@testable import CursorUsageMenubar

final class SingleInstanceGuardTests: XCTestCase {
  func testLockURLIsStable() {
    let first = SingleInstanceGuard.lockURLForTesting
    let second = SingleInstanceGuard.lockURLForTesting
    XCTAssertEqual(first, second)
    XCTAssertTrue(first.path.contains("Cursor Usage Menubar"))
  }
}

#if DEBUG
extension SingleInstanceGuard {
  static var lockURLForTesting: URL {
    let support = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Application Support/Cursor Usage Menubar", isDirectory: true)
    return support.appendingPathComponent("single-instance.lock")
  }
}
#endif
