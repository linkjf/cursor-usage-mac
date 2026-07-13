import XCTest
@testable import CursorUsageMenubar

final class UsageSnapshotTests: XCTestCase {
  func testApiPercentRemaining() {
    let snapshot = makeSnapshot(apiPercentUsed: 48)
    XCTAssertEqual(snapshot.apiPercentRemaining, 52)
  }

  func testMenuBarCompactLabel() {
    let snapshot = makeSnapshot(apiPercentUsed: 48, auto: 7, total: 16)
    XCTAssertEqual(snapshot.menuBarCompactLabel(), "52% | 7/16")
  }

  func testMenuBarStackedLabel() {
    let snapshot = makeSnapshot(apiPercentUsed: 52, auto: 7, total: 16)
    let stacked = snapshot.menuBarStackedLabel()
    XCTAssertEqual(stacked.top, "48%")
    XCTAssertEqual(stacked.bottom, "7/16")
  }

  func testPoolRemainingDollars() {
    let snapshot = makeSnapshot(remainingCents: 12345)
    XCTAssertEqual(snapshot.poolRemainingDollars, 123.45)
  }

  func testEquatableIgnoresFetchedAt() {
    let a = makeSnapshot(apiPercentUsed: 10)
    let b = makeSnapshot(apiPercentUsed: 10)
    XCTAssertEqual(a, b)
  }

  private func makeSnapshot(
    apiPercentUsed: Int = 0,
    auto: Int = 0,
    total: Int = 0,
    remainingCents: Int? = nil
  ) -> UsageSnapshot {
    UsageSnapshot(
      membership: "pro_plus",
      accountEmail: "user@example.com",
      totalPercentUsed: total,
      autoPercentUsed: auto,
      apiPercentUsed: apiPercentUsed,
      limitCents: 2000,
      remainingCents: remainingCents,
      autoMessage: nil,
      apiMessage: nil,
      cycleEnd: "2026-08-01T00:00:00.000Z"
    )
  }
}

final class UsageTierTests: XCTestCase {
  func testTierThresholdsOnRemaining() {
    XCTAssertEqual(UsageTier.forRemaining(75), .safe)
    XCTAssertEqual(UsageTier.forRemaining(60), .safe)
    XCTAssertEqual(UsageTier.forRemaining(59), .caution)
    XCTAssertEqual(UsageTier.forRemaining(40), .caution)
    XCTAssertEqual(UsageTier.forRemaining(39), .warning)
    XCTAssertEqual(UsageTier.forRemaining(20), .warning)
    XCTAssertEqual(UsageTier.forRemaining(19), .critical)
    XCTAssertEqual(UsageTier.forRemaining(0), .critical)
  }

  func testSnapshotTierUsesRemaining() {
    let snapshot = UsageSnapshot(
      membership: "pro_plus",
      accountEmail: nil,
      totalPercentUsed: 16,
      autoPercentUsed: 7,
      apiPercentUsed: 48,
      limitCents: nil,
      remainingCents: nil,
      autoMessage: nil,
      apiMessage: nil,
      cycleEnd: "2026-08-01T00:00:00.000Z"
    )
    XCTAssertEqual(snapshot.apiTier, .caution)
  }
}

final class JWTDecoderTests: XCTestCase {
  func testDecodesBase64URLPayload() {
    let json = #"{"sub":"user_01|abc123"}"#
    let data = json.data(using: .utf8)!
    let base64url = data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")

    let decoded = JWTDecoder.payloadData(from: base64url)
    XCTAssertNotNil(decoded)
    let object = try? JSONSerialization.jsonObject(with: decoded!) as? [String: Any]
    XCTAssertEqual(object?["sub"] as? String, "user_01|abc123")
  }
}

final class UsageSummaryParsingTests: XCTestCase {
  func testDecodesUsageSummaryResponse() throws {
    let json = """
    {
      "membershipType": "pro_plus",
      "billingCycleEnd": "2026-08-01T00:00:00.000Z",
      "individualUsage": {
        "plan": {
          "enabled": true,
          "limit": 2000,
          "remaining": 1500,
          "autoPercentUsed": 7,
          "apiPercentUsed": 48,
          "totalPercentUsed": 16
        }
      }
    }
    """
    let payload = try JSONDecoder().decode(UsageSummaryResponse.self, from: Data(json.utf8))
    XCTAssertEqual(payload.membershipType, "pro_plus")
    XCTAssertEqual(payload.individualUsage?.plan?.apiPercentUsed, 48)
  }
}

// Test-only visibility for private DTO
private struct UsageSummaryResponse: Decodable {
  let membershipType: String?
  let billingCycleEnd: String?
  let autoModelSelectedDisplayMessage: String?
  let namedModelSelectedDisplayMessage: String?
  let individualUsage: IndividualUsageDTO?
}

private struct IndividualUsageDTO: Decodable {
  let plan: PlanDTO?
}
