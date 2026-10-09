import XCTest
@testable import CursorUsageMenubar

final class UsageSnapshotTests: XCTestCase {
  func testApiPercentRemaining() {
    let snapshot = makeSnapshot(apiPercentUsed: 48)
    XCTAssertEqual(snapshot.apiPercentRemaining, 52)
  }

  func testMenuBarCompactLabel() {
    let snapshot = makeSnapshot(apiPercentUsed: 48, auto: 7, total: 16)
    XCTAssertEqual(snapshot.menuBarCompactLabel(), "48% | 7/16")
  }

  func testMenuBarStackedLabel() {
    let snapshot = makeSnapshot(apiPercentUsed: 48, auto: 7, total: 16)
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

final class ConnectUsageParsingTests: XCTestCase {
  func testDecodesConnectUsageAndConvertsCycleEndToISO() throws {
    // Fixture written from the DTO shape in UsageFetcher.swift, not captured from the live API.
    let json = """
    {
      "billingCycleEnd": "1785542400000",
      "enabled": true,
      "planUsage": {
        "includedSpend": 500,
        "limit": 2000,
        "remaining": 1500,
        "autoPercentUsed": 7,
        "apiPercentUsed": 48,
        "totalPercentUsed": 16
      }
    }
    """
    let payload = try JSONDecoder().decode(ConnectUsageResponse.self, from: Data(json.utf8))
    XCTAssertEqual(payload.planUsage?.apiPercentUsed, 48)
    XCTAssertEqual(payload.planUsage?.remaining, 1500)
    XCTAssertEqual(payload.enabled, true)
    XCTAssertNotNil(payload.billingCycleEndISO)
  }
}

final class UsageLabelAndErrorTests: XCTestCase {
  func testUnknownMembershipUsesCursorPlanLabel() {
    let snapshot = UsageSnapshot(
      membership: "unknown",
      accountEmail: nil,
      totalPercentUsed: 0,
      autoPercentUsed: 0,
      apiPercentUsed: 0,
      limitCents: nil,
      remainingCents: nil,
      autoMessage: nil,
      apiMessage: nil,
      cycleEnd: "—"
    )
    XCTAssertEqual(snapshot.membershipLabel, L10n.text(.membershipUnknown))
  }

  func testFallbackFailureMentionsBothEndpoints() {
    let error = UsageFetcherError.fallbackFailed(
      summary: UsageFetcherError.badResponse(401),
      fallback: UsageFetcherError.invalidPayload
    )
    let message = error.errorDescription ?? ""
    XCTAssertTrue(message.contains("401"))
    XCTAssertTrue(message.contains(L10n.text(.errorInvalidPayload)))
  }

  func testKnownMembershipIsTitleCased() {
    let snapshot = UsageSnapshot(
      membership: "pro_plus",
      accountEmail: nil,
      totalPercentUsed: 0,
      autoPercentUsed: 0,
      apiPercentUsed: 0,
      limitCents: nil,
      remainingCents: nil,
      autoMessage: nil,
      apiMessage: nil,
      cycleEnd: "—"
    )
    XCTAssertEqual(snapshot.membershipLabel, "Pro Plus")
  }
}
