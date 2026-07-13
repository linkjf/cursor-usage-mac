import CryptoKit
import Foundation
import SQLite3

protocol UsageFetching {
  func fetch() async throws -> UsageSnapshot
  func clearTokenCache()
  func currentAccountFingerprint() throws -> String?
}

enum UsageFetcherError: LocalizedError {
  case missingDatabase
  case missingToken
  case badToken
  case badResponse(Int)
  case invalidPayload

  var errorDescription: String? {
    switch self {
    case .missingDatabase: return L10n.text(.errorMissingDatabase)
    case .missingToken: return L10n.text(.errorMissingToken)
    case .badToken: return L10n.text(.errorBadToken)
    case .badResponse(let code): return String(format: L10n.text(.errorBadResponse), code)
    case .invalidPayload: return L10n.text(.errorInvalidPayload)
    }
  }
}

final class LiveUsageFetcher: UsageFetching {
  private let summaryURL = URL(string: "https://cursor.com/api/usage-summary")!
  private let connectURL = URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage")!

  private let session: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 12
    config.timeoutIntervalForResource = 15
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil
    return URLSession(configuration: config)
  }()

  private var cachedToken: String?
  private var cachedTokenReadAt: Date?
  private let tokenTTL: TimeInterval = 300

  func clearTokenCache() {
    cachedToken = nil
    cachedTokenReadAt = nil
  }

  static func dbPath() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Application Support/Cursor/User/globalStorage/state.vscdb")
  }

  func currentAccountFingerprint() throws -> String? {
    let token = try readAccessToken(useCache: false)
    let email = try readCachedEmail()
    let digest = SHA256Hasher.hash(token + (email ?? ""))
    return String(digest.prefix(16))
  }

  func fetch() async throws -> UsageSnapshot {
    do {
      return try await fetchSummary()
    } catch UsageFetcherError.badResponse(401), UsageFetcherError.badResponse(403) {
      clearTokenCache()
      return try await fetchSummary()
    } catch {
      if let snapshot = try? await fetchConnectRPC() {
        return snapshot
      }
      throw error
    }
  }

  private func fetchSummary() async throws -> UsageSnapshot {
    let token = try readAccessToken(useCache: true)
    let cookie = try sessionCookie(for: token)

    var request = URLRequest(url: summaryURL)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(cookie, forHTTPHeaderField: "Cookie")
    request.setValue("https://cursor.com", forHTTPHeaderField: "Origin")
    request.setValue("https://cursor.com/dashboard/spending", forHTTPHeaderField: "Referer")
    request.setValue("CursorUsageMenubar/2.0", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw UsageFetcherError.badResponse(-1)
    }
    guard (200...299).contains(http.statusCode) else {
      throw UsageFetcherError.badResponse(http.statusCode)
    }

    let payload = try JSONDecoder().decode(UsageSummaryResponse.self, from: data)
    guard let plan = payload.individualUsage?.plan, plan.enabled != false else {
      throw UsageFetcherError.invalidPayload
    }

    return try makeSnapshot(
      membership: payload.membershipType,
      email: try readCachedEmail(),
      plan: plan,
      autoMessage: payload.autoModelSelectedDisplayMessage,
      apiMessage: payload.namedModelSelectedDisplayMessage,
      cycleEnd: payload.billingCycleEnd
    )
  }

  private func fetchConnectRPC() async throws -> UsageSnapshot {
    let token = try readAccessToken(useCache: true)

    var request = URLRequest(url: connectURL)
    request.httpMethod = "POST"
    request.httpBody = Data("{}".utf8)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
    request.setValue("CursorUsageMenubar/2.0", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
      throw UsageFetcherError.invalidPayload
    }

    let payload = try JSONDecoder().decode(ConnectUsageResponse.self, from: data)
    guard let plan = payload.planUsage else { throw UsageFetcherError.invalidPayload }

    let planDTO = PlanDTO(
      enabled: payload.enabled,
      used: plan.includedSpend,
      limit: plan.limit,
      remaining: plan.remaining,
      autoPercentUsed: plan.autoPercentUsed,
      apiPercentUsed: plan.apiPercentUsed,
      totalPercentUsed: plan.totalPercentUsed
    )

    return try makeSnapshot(
      membership: "pro_plus",
      email: try readCachedEmail(),
      plan: planDTO,
      autoMessage: payload.autoModelSelectedDisplayMessage,
      apiMessage: payload.namedModelSelectedDisplayMessage,
      cycleEnd: payload.billingCycleEndISO
    )
  }

  private func makeSnapshot(
    membership: String?,
    email: String?,
    plan: PlanDTO,
    autoMessage: String?,
    apiMessage: String?,
    cycleEnd: String?
  ) throws -> UsageSnapshot {
    guard let total = plan.totalPercentUsed,
          let auto = plan.autoPercentUsed,
          let api = plan.apiPercentUsed else {
      throw UsageFetcherError.invalidPayload
    }

    return UsageSnapshot(
      membership: membership ?? "unknown",
      accountEmail: email,
      totalPercentUsed: clampPercent(total),
      autoPercentUsed: clampPercent(auto),
      apiPercentUsed: clampPercent(api),
      limitCents: plan.limit,
      remainingCents: plan.remaining,
      autoMessage: autoMessage,
      apiMessage: apiMessage,
      cycleEnd: cycleEnd ?? "—"
    )
  }

  private func readAccessToken(useCache: Bool) throws -> String {
    if useCache, let cachedToken, let cachedTokenReadAt,
       Date().timeIntervalSince(cachedTokenReadAt) < tokenTTL {
      return cachedToken
    }

    guard let value = try readItemTableValue(key: "cursorAuth/accessToken"),
          !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw UsageFetcherError.missingToken
    }

    let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
    cachedToken = token
    cachedTokenReadAt = Date()
    return token
  }

  private func readCachedEmail() throws -> String? {
    try readItemTableValue(key: "cursorAuth/cachedEmail")
  }

  private func readItemTableValue(key: String) throws -> String? {
    let path = Self.dbPath().path
    guard FileManager.default.fileExists(atPath: path) else {
      throw UsageFetcherError.missingDatabase
    }

    var db: OpaquePointer?
    guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else {
      throw UsageFetcherError.missingDatabase
    }
    defer { sqlite3_close(db) }

    let sql = "SELECT value FROM ItemTable WHERE key = ? LIMIT 1"
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
      throw UsageFetcherError.missingToken
    }
    defer { sqlite3_finalize(stmt) }

    let bindCode = key.withCString { cString in
      sqlite3_bind_text(stmt, 1, cString, -1, nil)
    }
    guard bindCode == SQLITE_OK else {
      throw UsageFetcherError.missingToken
    }

    guard sqlite3_step(stmt) == SQLITE_ROW, let cString = sqlite3_column_text(stmt, 0) else {
      return nil
    }
    return String(cString: cString)
  }

  private func sessionCookie(for token: String) throws -> String {
    let parts = token.split(separator: ".")
    guard parts.count >= 2 else { throw UsageFetcherError.badToken }

    guard let data = JWTDecoder.payloadData(from: String(parts[1])),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let sub = json["sub"] as? String else {
      throw UsageFetcherError.badToken
    }

    let userID: String
    if let pipe = sub.firstIndex(of: "|") {
      userID = String(sub[sub.index(after: pipe)...])
    } else {
      userID = sub
    }

    guard !userID.isEmpty else { throw UsageFetcherError.badToken }
    return "WorkosCursorSessionToken=\(userID)%3A%3A\(token)"
  }

  private func clampPercent(_ value: Double) -> Int {
    Int(max(0, min(100, value.rounded())))
  }
}

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

struct PlanDTO: Decodable {
  let enabled: Bool?
  let used: Int?
  let limit: Int?
  let remaining: Int?
  let autoPercentUsed: Double?
  let apiPercentUsed: Double?
  let totalPercentUsed: Double?
}

private struct ConnectUsageResponse: Decodable {
  let billingCycleEnd: String?
  let planUsage: ConnectPlanUsage?
  let enabled: Bool?
  let autoModelSelectedDisplayMessage: String?
  let namedModelSelectedDisplayMessage: String?

  var billingCycleEndISO: String? {
    guard let billingCycleEnd, let ms = Double(billingCycleEnd) else { return billingCycleEnd }
    let date = Date(timeIntervalSince1970: ms / 1000)
    return ISO8601DateFormatter().string(from: date)
  }
}

private struct ConnectPlanUsage: Decodable {
  let includedSpend: Int?
  let limit: Int?
  let remaining: Int?
  let autoPercentUsed: Double?
  let apiPercentUsed: Double?
  let totalPercentUsed: Double?
}

enum JWTDecoder {
  static func payloadData(from segment: String) -> Data? {
    var base64 = segment
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    while base64.count % 4 != 0 { base64.append("=") }
    return Data(base64Encoded: base64)
  }
}

enum SHA256Hasher {
  static func hash(_ input: String) -> String {
    let data = Data(input.utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}
