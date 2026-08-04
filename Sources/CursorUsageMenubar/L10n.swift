import Foundation

enum L10n {
  static var language: AppLanguage {
    let raw = UserDefaults.standard.string(forKey: AppSettings.appLanguageKey) ?? AppLanguage.system.rawValue
    return AppLanguage(rawValue: raw) ?? .system
  }

  static func text(_ key: Key) -> String {
    let code = resolvedLanguageCode()
    return table[code]?[key] ?? table["en"]![key]!
  }

  private static func resolvedLanguageCode() -> String {
    switch language {
    case .en: return "en"
    case .es: return "es"
    case .system:
      let preferred = Locale.preferredLanguages.first ?? "en"
      return preferred.hasPrefix("es") ? "es" : "en"
    }
  }

  enum Key: String {
    case loading
    case updating
    case switchingAccount
    case updateFailed
    case lastUpdated
    case refresh
    case dashboard
    case settings
    case back
    case quit
    case launchAtLogin
    case menuBarLayout
    case menuBarColors
    case language
    case compactLayout
    case stackedLayout
    case includedIn
    case total
    case autoComposer
    case api
    case apiRemaining
    case apiUsed
    case cycleEnds
    case adviceUseAuto
    case adviceCarefulAPI
    case adviceAPIMargin
    case adviceAutoHigh
    case adviceBodyAuto
    case adviceBodyCareful
    case adviceBodyMargin
    case adviceBodyAutoHigh
    case errorMissingDatabase
    case errorMissingToken
    case errorBadToken
    case errorBadResponse
    case errorInvalidPayload
    case tooltipAPI
    case tooltipAuto
    case tooltipTotal
    case captionAuto
    case captionAPI
    case apiRemainingShort
    case captionAPIUsed
    case captionTotal
    case poolRemaining
    case apiDollarsLeft
    case tierSafe
    case tierCaution
    case tierWarning
    case tierCritical
    case settingsLaunchHint
    case settingsMenuBarHint
    case settingsLanguageHint
    case settingsMenuBarPreview
    case settingsAppearance
    case settingsGeneral
  }

  private static let table: [String: [Key: String]] = [
    "en": [
      .loading: "Loading…",
      .updating: "Updating…",
      .switchingAccount: "Switching account…",
      .updateFailed: "Update failed",
      .lastUpdated: "Updated %@ ago",
      .refresh: "Refresh",
      .dashboard: "Dashboard",
      .settings: "Settings",
      .back: "Back",
      .quit: "Quit",
      .launchAtLogin: "Launch at login",
      .menuBarLayout: "Menu bar layout",
      .menuBarColors: "Menu bar colors",
      .language: "Language",
      .compactLayout: "Compact (API %)",
      .stackedLayout: "Stacked (API + detail)",
      .includedIn: "Included in %@",
      .total: "Total",
      .autoComposer: "Cursor tier",
      .api: "API",
      .apiRemaining: "API: %d%% remaining (%d%% used)",
      .apiUsed: "API used",
      .apiRemainingShort: "%d%% remaining",
      .cycleEnds: "Cycle ends %@",
      .adviceUseAuto: "Use Cursor tier models",
      .adviceCarefulAPI: "Careful with API models",
      .adviceAPIMargin: "Good time for Composer or Grok",
      .adviceAutoHigh: "Cursor tier usage is high",
      .adviceBodyAuto: "API quota is almost full. Prefer Agent, Composer, Grok, and Auto.",
      .adviceBodyCareful: "~%d%% API left. Save Opus/GPT for hard tasks. Grok is still free in Cursor tier.",
      .adviceBodyMargin: "API has margin. Named models are fine; Composer, Grok, and Agent OK.",
      .adviceBodyAutoHigh: "Cursor tier is high. You can still use named models, but alternate lighter ones.",
      .errorMissingDatabase: "Cursor database not found.",
      .errorMissingToken: "Not signed in to Cursor.",
      .errorBadToken: "Could not parse Cursor session.",
      .errorBadResponse: "API responded with status %d.",
      .errorInvalidPayload: "Unexpected usage response from Cursor.",
      .tooltipAPI: "API: %d%% used (%d%% remaining)",
      .tooltipAuto: "Cursor tier: %d%% used",
      .tooltipTotal: "Total: %d%% used",
      .captionAuto: "Agent, Composer, Grok, Auto — included in Cursor tier",
      .captionAPI: "Opus, GPT, Claude named, etc. — not Grok",
      .captionAPIUsed: "Opus, GPT, Claude named, etc. — not Grok · %d%% left",
      .captionTotal: "%d%% Auto · %d%% API used",
      .poolRemaining: "Pool: $%.2f left",
      .apiDollarsLeft: "API est.: $%.2f left",
      .tierSafe: "OK",
      .tierCaution: "Moderate",
      .tierWarning: "High",
      .tierCritical: "Critical",
      .settingsLaunchHint: "Start automatically when you log in.",
      .settingsMenuBarHint: "Compact shows API used % only. Stacked adds auto/total below.",
      .settingsLanguageHint: "Follows system by default.",
      .settingsMenuBarPreview: "Preview",
      .settingsAppearance: "Menu Bar",
      .settingsGeneral: "General",
    ],
    "es": [
      .loading: "Cargando…",
      .updating: "Actualizando…",
      .switchingAccount: "Cambiando cuenta…",
      .updateFailed: "Error al actualizar",
      .lastUpdated: "Actualizado hace %@",
      .refresh: "Actualizar",
      .dashboard: "Dashboard",
      .settings: "Ajustes",
      .back: "Volver",
      .quit: "Salir",
      .launchAtLogin: "Iniciar con el sistema",
      .menuBarLayout: "Formato menu bar",
      .menuBarColors: "Colores en menu bar",
      .language: "Idioma",
      .compactLayout: "Compacto (API %)",
      .stackedLayout: "Apilado (API + detalle)",
      .includedIn: "Incluido en %@",
      .total: "Total",
      .autoComposer: "Tier Cursor",
      .api: "API",
      .apiRemaining: "API: %d%% restante (%d%% usado)",
      .apiUsed: "API usado",
      .apiRemainingShort: "%d%% restante",
      .cycleEnds: "Ciclo termina %@",
      .adviceUseAuto: "Usa modelos del tier Cursor",
      .adviceCarefulAPI: "Cuidado con modelos API",
      .adviceAPIMargin: "Buen momento para Composer o Grok",
      .adviceAutoHigh: "Uso alto en tier Cursor",
      .adviceBodyAuto: "El cupo API está casi lleno. Prioriza Agent, Composer, Grok y modelos Auto.",
      .adviceBodyCareful: "Queda ~%d%% de API. Reserva Opus/GPT para tareas difíciles. Grok sigue libre en tier Cursor.",
      .adviceBodyMargin: "API con margen. Modelos named OK; Composer, Grok y Agent sin problema.",
      .adviceBodyAutoHigh: "Tier Cursor alto. Puedes usar named, pero alterna modelos ligeros.",
      .errorMissingDatabase: "No encontré la base de datos de Cursor.",
      .errorMissingToken: "Sin sesión en Cursor.",
      .errorBadToken: "No se pudo leer la sesión de Cursor.",
      .errorBadResponse: "La API respondió con estado %d.",
      .errorInvalidPayload: "Respuesta de uso inesperada de Cursor.",
      .tooltipAPI: "API: %d%% usado (%d%% restante)",
      .tooltipAuto: "Tier Cursor: %d%% usado",
      .tooltipTotal: "Total: %d%% usado",
      .captionAuto: "Agent, Composer, Grok, Auto — incluidos en tier Cursor",
      .captionAPI: "Opus, GPT, Claude named, etc. — no Grok",
      .captionAPIUsed: "Opus, GPT, Claude named, etc. — no Grok · %d%% libre",
      .captionTotal: "%d%% Auto · %d%% API usados",
      .poolRemaining: "Pool: $%.2f restante",
      .apiDollarsLeft: "API est.: $%.2f restante",
      .tierSafe: "OK",
      .tierCaution: "Moderado",
      .tierWarning: "Alto",
      .tierCritical: "Crítico",
      .settingsLaunchHint: "Inicia al iniciar sesión.",
      .settingsMenuBarHint: "Compacto = solo API usado %. Apilado añade auto/total abajo.",
      .settingsLanguageHint: "Por defecto sigue el sistema.",
      .settingsMenuBarPreview: "Vista previa",
      .settingsAppearance: "Menu Bar",
      .settingsGeneral: "General",
    ],
  ]
}
