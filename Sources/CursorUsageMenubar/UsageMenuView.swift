import AppKit
import SwiftUI

struct UsageMenuView: View {
  @EnvironmentObject private var model: UsageModel
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage(AppSettings.launchAtLoginKey) private var launchAtLogin = LaunchAtLoginManager.isEnabled

  private var menuBarLayoutBinding: Binding<String> {
    Binding(
      get: { model.menuBarLayoutRaw },
      set: { model.setMenuBarLayout($0) }
    )
  }

  private var menuBarColorsBinding: Binding<Bool> {
    Binding(
      get: { model.menuBarColorsEnabled },
      set: { model.setMenuBarColorsEnabled($0) }
    )
  }

  private var appLanguageBinding: Binding<String> {
    Binding(
      get: { model.appLanguageRaw },
      set: { model.setAppLanguage($0) }
    )
  }

  var body: some View {
  Group {
    if model.showSettings {
      settingsView
    } else {
      mainView
    }
  }
  .frame(width: UsageTheme.panelWidth)
  .background(UsageTheme.surfaceBase(colorScheme))
  .onAppear { model.setMenuVisible(true) }
  .onDisappear { model.setMenuVisible(false) }
  }

  private var mainView: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      content
      footer
    }
  }

  @ViewBuilder
  private var header: some View {
    HStack(alignment: .center, spacing: 12) {
      if let usage = model.snapshot {
        RingGauge(percent: usage.apiPercentUsed, tier: usage.apiTier)
          .accessibilityLabel(L10n.text(.api))
          .accessibilityValue("\(usage.apiPercentUsed)%")
      } else {
        RingGauge(percent: 0, tier: .safe, loading: true)
      }

      VStack(alignment: .leading, spacing: 4) {
        if let usage = model.snapshot {
          Text(String(format: L10n.text(.includedIn), usage.membershipLabel))
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(UsageTheme.accentAPI)

          Text("\(usage.apiPercentUsed)%")
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundStyle(UsageTheme.textPrimary(colorScheme))
            .monospacedDigit()

          Text(L10n.text(.apiUsed))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(UsageTheme.textSecondary(colorScheme))

          Text(String(format: L10n.text(.apiRemainingShort), usage.apiPercentRemaining))
            .font(.system(size: 10))
            .foregroundStyle(UsageTheme.textTertiary(colorScheme))
          Text(usage.apiTier.label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(usage.apiTier.color)

          if let dollars = usage.poolRemainingDollars {
            Text(String(format: L10n.text(.poolRemaining), dollars))
              .font(.system(size: 10))
              .foregroundStyle(UsageTheme.textTertiary(colorScheme))
          }
        } else if model.switchingAccount {
          Text(L10n.text(.switchingAccount))
            .foregroundStyle(UsageTheme.textSecondary(colorScheme))
        } else {
          Text(model.isRefreshing ? L10n.text(.updating) : L10n.text(.loading))
            .foregroundStyle(UsageTheme.textSecondary(colorScheme))
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(UsageTheme.surfaceRaised(colorScheme))
  }

  @ViewBuilder
  private var content: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let error = model.errorText, model.snapshot != nil {
        Text("\(L10n.text(.updateFailed)): \(error)")
          .font(.system(size: 11))
          .foregroundStyle(UsageTier.critical.color)
          .padding(10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(UsageTier.critical.color.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      }

      if let usage = model.snapshot {
        AdviceCard(title: usage.adviceTitle(), message: usage.adviceBody(), tier: usage.apiTier)

        MetricCard(
          label: L10n.text(.api),
          value: usage.apiPercentUsed,
          usedValue: usage.apiPercentUsed,
          tint: usage.apiTier.color,
          caption: String(format: L10n.text(.captionAPIUsed), usage.apiPercentRemaining),
          emphasized: true,
          showRemaining: false
        )

        MetricCard(
          label: L10n.text(.autoComposer),
          value: usage.autoPercentUsed,
          usedValue: usage.autoPercentUsed,
          tint: UsageTheme.accentAuto,
          caption: L10n.text(.captionAuto),
          emphasized: false,
          showRemaining: false
        )

        MetricCard(
          label: L10n.text(.total),
          value: usage.totalPercentUsed,
          usedValue: usage.totalPercentUsed,
          tint: UsageTheme.textSecondary(colorScheme),
          caption: String(format: L10n.text(.captionTotal), usage.autoPercentUsed, usage.apiPercentUsed),
          emphasized: false,
          showRemaining: false
        )

        if let updated = model.relativeLastUpdated() {
          Text(updated)
            .font(.system(size: 10))
            .foregroundStyle(UsageTheme.textTertiary(colorScheme))
        }

        Text(String(format: L10n.text(.cycleEnds), usage.formattedCycleEnd()))
          .font(.system(size: 10))
          .foregroundStyle(UsageTheme.textTertiary(colorScheme))
      } else if let error = model.errorText {
        Text(error)
          .font(.system(size: 12))
          .foregroundStyle(UsageTier.critical.color)
      }
    }
    .padding(16)
  }

  private var footer: some View {
    VStack(spacing: 8) {
      Divider().overlay(UsageTheme.borderSubtle(colorScheme))

      HStack(spacing: 8) {
        ActionButton(title: L10n.text(.refresh), icon: "arrow.clockwise", colorScheme: colorScheme) {
          Task { await model.refresh(force: true) }
        }
        ActionButton(title: L10n.text(.dashboard), icon: "safari", colorScheme: colorScheme) {
          if let url = URL(string: "https://cursor.com/dashboard/usage") {
            NSWorkspace.shared.open(url)
          }
        }
      }

      HStack(spacing: 8) {
        ActionButton(title: L10n.text(.settings), icon: "gearshape", colorScheme: colorScheme) {
          model.showSettings = true
        }
        ActionButton(title: L10n.text(.quit), icon: "power", colorScheme: colorScheme) {
          NSApplication.shared.terminate(nil)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 14)
  }

  private var settingsView: some View {
    VStack(alignment: .leading, spacing: 0) {
      settingsHeader

      VStack(alignment: .leading, spacing: 10) {
        SettingsSection(title: L10n.text(.settingsGeneral), colorScheme: colorScheme, compact: true) {
          SettingsToggleRow(
            title: L10n.text(.launchAtLogin),
            subtitle: L10n.text(.settingsLaunchHint),
            isOn: $launchAtLogin,
            colorScheme: colorScheme,
            compact: true
          )
          .onChange(of: launchAtLogin) { enabled in
            _ = LaunchAtLoginManager.setEnabled(enabled)
          }
        }

        SettingsSection(title: L10n.text(.settingsAppearance), colorScheme: colorScheme, compact: true) {
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(.menuBarLayout))
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(UsageTheme.textPrimary(colorScheme))

            Picker("", selection: menuBarLayoutBinding) {
              Text(L10n.text(.compactLayout)).tag(MenuBarLayout.compact.rawValue)
              Text(L10n.text(.stackedLayout)).tag(MenuBarLayout.stacked.rawValue)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            SettingsToggleRow(
              title: L10n.text(.menuBarColors),
              subtitle: L10n.text(.settingsMenuBarHint),
              isOn: menuBarColorsBinding,
              colorScheme: colorScheme,
              compact: true
            )

            MenuBarPreview(
              hero: model.menuBarHero,
              context: model.menuBarStacked ? model.menuBarContext : "",
              stacked: model.menuBarStacked,
              tier: model.statusTier,
              colorsEnabled: model.menuBarColorsEnabled,
              colorScheme: colorScheme,
              compact: true
            )
          }
        }

        SettingsSection(title: L10n.text(.language), colorScheme: colorScheme, compact: true) {
          VStack(alignment: .leading, spacing: 6) {
            Picker("", selection: appLanguageBinding) {
              ForEach(AppLanguage.allCases) { lang in
                Text(lang.label).tag(lang.rawValue)
              }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(L10n.text(.settingsLanguageHint))
              .font(.system(size: 10))
              .foregroundStyle(UsageTheme.textTertiary(colorScheme))
          }
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
    }
  }

  private var settingsHeader: some View {
    HStack(spacing: 10) {
      Button {
        model.showSettings = false
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(UsageTheme.textPrimary(colorScheme))
          .frame(width: 28, height: 28)
          .background(UsageTheme.surfaceRaised(colorScheme))
          .clipShape(Circle())
          .overlay(Circle().stroke(UsageTheme.borderSubtle(colorScheme), lineWidth: 1))
      }
      .buttonStyle(.plain)

      VStack(alignment: .leading, spacing: 2) {
        Text(L10n.text(.settings))
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(UsageTheme.textPrimary(colorScheme))
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(UsageTheme.surfaceRaised(colorScheme))
    .overlay(alignment: .bottom) {
      Divider().overlay(UsageTheme.borderSubtle(colorScheme))
    }
  }
}

struct RingGauge: View {
  let percent: Int
  let tier: UsageTier
  var loading: Bool = false

  var body: some View {
    ZStack {
      Circle().stroke(Color.primary.opacity(0.08), lineWidth: 5)
      Circle()
        .trim(from: 0, to: loading ? 0.15 : CGFloat(min(max(percent, 0), 100)) / 100)
        .stroke(tier.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text(loading ? "…" : "\(percent)%")
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .monospacedDigit()
    }
    .frame(width: 52, height: 52)
  }
}

struct AdviceCard: View {
  let title: String
  let message: String
  let tier: UsageTier

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        Image(systemName: "lightbulb.fill").font(.system(size: 10, weight: .bold))
        Text(title).font(.system(size: 12, weight: .semibold))
      }
      .foregroundStyle(tier.color)
      Text(message)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(tier.color.opacity(0.08))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(tier.color.opacity(0.18), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

struct MetricCard: View {
  let label: String
  let value: Int
  let usedValue: Int
  let tint: Color
  let caption: String
  let emphasized: Bool
  let showRemaining: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(label).font(.system(size: 12, weight: emphasized ? .semibold : .medium))
        Spacer()
        Text(showRemaining ? "\(value)%" : "\(usedValue)%")
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(tint)
          .monospacedDigit()
      }

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(Color.primary.opacity(0.08))
          Capsule()
            .fill(tint)
            .frame(width: geo.size.width * CGFloat(min(max(showRemaining ? value : usedValue, 0), 100)) / 100)
        }
      }
      .frame(height: 7)
      .accessibilityHidden(true)

      Text(caption)
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .background(Color.primary.opacity(0.04))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(emphasized ? tint.opacity(0.28) : Color.primary.opacity(0.08), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

struct ActionButton: View {
  let title: String
  let icon: String
  let colorScheme: ColorScheme
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: icon)
        Text(title)
      }
      .font(.system(size: 11, weight: .semibold))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(UsageTheme.surfaceRaised(colorScheme))
      .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .stroke(UsageTheme.borderSubtle(colorScheme), lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct SettingsSection<Content: View>: View {
  let title: String
  let colorScheme: ColorScheme
  var compact: Bool = false
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 6 : 10) {
      Text(title.uppercased())
        .font(.system(size: 10, weight: .bold))
        .kerning(0.6)
        .foregroundStyle(UsageTheme.textTertiary(colorScheme))

      VStack(alignment: .leading, spacing: compact ? 8 : 12) {
        content
      }
      .padding(compact ? 10 : 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(UsageTheme.surfaceRaised(colorScheme))
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(UsageTheme.borderSubtle(colorScheme), lineWidth: 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
  }
}

struct SettingsToggleRow: View {
  let title: String
  let subtitle: String
  @Binding var isOn: Bool
  let colorScheme: ColorScheme
  var compact: Bool = false

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: compact ? 1 : 3) {
        Text(title)
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(UsageTheme.textPrimary(colorScheme))
        if !compact {
          Text(subtitle)
            .font(.system(size: 10))
            .foregroundStyle(UsageTheme.textTertiary(colorScheme))
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      Spacer(minLength: 8)
      Toggle("", isOn: $isOn)
        .labelsHidden()
        .toggleStyle(.switch)
    }
  }
}

struct MenuBarPreview: View {
  let hero: String
  let context: String
  let stacked: Bool
  let tier: UsageTier
  let colorsEnabled: Bool
  let colorScheme: ColorScheme
  var compact: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 4 : 8) {
      Text(L10n.text(.settingsMenuBarPreview))
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(UsageTheme.textTertiary(colorScheme))

      HStack {
        Spacer()
        Group {
          if stacked {
            VStack(alignment: .trailing, spacing: 1) {
              previewHero(size: compact ? 12 : 13)
              if !context.isEmpty {
                previewContext(size: compact ? 10 : 11)
              }
            }
          } else {
            HStack(spacing: 0) {
              previewHero(size: compact ? 12 : 13)
              if !context.isEmpty {
                Text(" | ")
                  .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .monospaced))
                  .foregroundStyle(UsageTheme.textSecondary(colorScheme))
                previewContext(size: compact ? 12 : 13)
              }
            }
          }
        }
        Spacer()
      }
      .padding(.vertical, compact ? 8 : 12)
      .background(colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.06))
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
  }

  @ViewBuilder
  private func previewHero(size: CGFloat) -> some View {
    Text(hero)
      .font(.system(size: size, weight: .semibold, design: .monospaced))
      .monospacedDigit()
      .foregroundStyle(colorsEnabled ? tier.color : UsageTheme.textPrimary(colorScheme))
  }

  @ViewBuilder
  private func previewContext(size: CGFloat) -> some View {
    Text(context)
      .font(.system(size: size, weight: .regular, design: .monospaced))
      .monospacedDigit()
      .foregroundStyle(UsageTheme.textSecondary(colorScheme))
  }
}
