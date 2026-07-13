import XCTest
@testable import CursorUsageMenubar

final class LiveFetcherIntegrationTests: XCTestCase {
  func testLiveFetchWhenCursorInstalled() async throws {
    let db = LiveUsageFetcher.dbPath()
    guard FileManager.default.fileExists(atPath: db.path) else {
      throw XCTSkip("Cursor database not present")
    }

    let fetcher = LiveUsageFetcher()
    let snapshot = try await fetcher.fetch()
    XCTAssertGreaterThanOrEqual(snapshot.apiPercentRemaining, 0)
    XCTAssertLessThanOrEqual(snapshot.apiPercentRemaining, 100)
    XCTAssertFalse(snapshot.menuBarCompactLabel().isEmpty)
    print("menuBar:", snapshot.menuBarCompactLabel())
  }
}
