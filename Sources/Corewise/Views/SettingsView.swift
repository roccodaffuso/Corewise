// SPDX-License-Identifier: MPL-2.0

import SwiftUI

struct SettingsView: View {
  @ObservedObject var store: HealthDashboardStore

  var body: some View {
    TabView {
      GeneralSettingsPane()
        .tabItem {
          Label("General", systemImage: "gearshape")
        }

      PrivacySettingsPane()
        .tabItem {
          Label("Privacy", systemImage: "lock.shield")
        }

      PerformanceSettingsPane()
        .tabItem {
          Label("Performance", systemImage: "cpu")
        }

      ReportSettingsPane()
        .tabItem {
          Label("Report", systemImage: "doc.text")
        }

      MenuBarSettingsPane(store: store)
        .tabItem {
          Label("Menu Bar", systemImage: "menubar.rectangle")
        }
    }
    .frame(width: 660, height: 520)
    .background(CorewiseVisual.windowBackground)
  }
}

private struct GeneralSettingsPane: View {
  var body: some View {
    SettingsPane(
      title: "General",
      subtitle: "Corewise follows the Mac and keeps diagnosis under your control.",
      systemImage: "gearshape"
    ) {
      Form {
        Section("Corewise on this Mac") {
          SettingsInfoRow(
            title: "Local by design",
            detail: "No account, backend, analytics, tracking, or telemetry.",
            systemImage: "internaldrive"
          )
          SettingsInfoRow(
            title: "System appearance",
            detail: "Corewise automatically follows Light, Dark, contrast, transparency, and motion preferences.",
            systemImage: "circle.lefthalf.filled"
          )
          SettingsInfoRow(
            title: "Manual control",
            detail: "Corewise explains supported signals and leaves changes to macOS, Finder, or the owning app.",
            systemImage: "hand.raised"
          )
        }

        Section("Project & Support") {
          SettingsExternalLinkRow(
            title: "Source code on GitHub",
            detail: "Corewise source is available under the Mozilla Public License 2.0.",
            systemImage: "chevron.left.forwardslash.chevron.right",
            destination: URL(string: "https://github.com/roccodaffuso/Corewise")!
          )
          SettingsExternalLinkRow(
            title: "View MPL-2.0 license",
            detail: "Read the complete license that governs Corewise source files.",
            systemImage: "doc.text",
            destination: URL(string: "https://github.com/roccodaffuso/Corewise/blob/main/LICENSE")!
          )
          SettingsExternalLinkRow(
            title: "Report an Issue",
            detail: "Open a new GitHub issue for a bug, regression, or reproducible problem.",
            systemImage: "exclamationmark.bubble",
            destination: URL(string: "https://github.com/roccodaffuso/Corewise/issues/new/choose")!
          )
        }

        Section("Build") {
          LabeledContent("Version", value: versionLabel)
          LabeledContent("Minimum system", value: "macOS 14")
        }
      }
    }
  }

  private var versionLabel: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    return switch (version, build) {
    case let (.some(version), .some(build)): "\(version) (\(build))"
    case let (.some(version), nil): version
    default: "Development build"
    }
  }
}

private struct PrivacySettingsPane: View {
  var body: some View {
    SettingsPane(
      title: "Privacy & Data",
      subtitle: "A clear map of what Corewise reads, when it reads it, and what stays out of scope.",
      systemImage: "lock.shield"
    ) {
      Form {
        Section("Automatic local reads") {
          SettingsInfoRow(
            title: "System signals",
            detail: "CPU, memory, process rows, startup-volume capacity, battery basics, thermal state, and readable launch metadata.",
            systemImage: "waveform.path.ecg"
          )
        }

        Section("Reads you explicitly start") {
          SettingsInfoRow(
            title: "Full Storage Analysis",
            detail: "Uses optional macOS Full Disk Access only when you start a read-only analysis. Folder Scope remains a limited fallback.",
            systemImage: "internaldrive"
          )
          SettingsInfoRow(
            title: "App issue reports",
            detail: "Reads report metadata only after you choose a reports folder. Stack traces and raw report bodies are not exposed.",
            systemImage: "doc.text.magnifyingglass"
          )
        }

        Section("Always avoided") {
          SettingsInfoRow(
            title: "No destructive automation",
            detail: "Corewise does not delete files, empty Trash, kill processes, use elevated tools, or upload diagnostics.",
            systemImage: "checkmark.shield"
          )
        }
      }
    }
  }
}

private struct PerformanceSettingsPane: View {
  @AppStorage(CorewiseSettingsKeys.performanceDefaultFocus) private var defaultFocus = PerformanceDefaultFocus.cpu.rawValue

  var body: some View {
    SettingsPane(
      title: "Performance",
      subtitle: "Choose the lens Corewise opens first without changing what the sampler observes.",
      systemImage: "cpu"
    ) {
      Form {
        Section("Default lens") {
          Picker("Open Performance with", selection: $defaultFocus) {
            ForEach(PerformanceDefaultFocus.allCases) { focus in
              Text(focus.title).tag(focus.rawValue)
            }
          }
          .pickerStyle(.segmented)

          Text("CPU, Memory, and AI Workloads remain separate views of the same live process sample.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        Section("Collection") {
          SettingsInfoRow(
            title: "One shared refresh",
            detail: "Changing the default lens does not start another collector or increase the sampling rate.",
            systemImage: "arrow.triangle.2.circlepath"
          )
          SettingsInfoRow(
            title: "AI stays local",
            detail: "AI Workloads reports supported local process attribution. Logical agents and cloud activity remain outside coverage.",
            systemImage: "sparkles.rectangle.stack"
          )
        }
      }
    }
  }
}

private struct ReportSettingsPane: View {
  @AppStorage(CorewiseSettingsKeys.reportDefaultFormat) private var defaultFormat = ReportFormatPreference.summary.rawValue
  @AppStorage(CorewiseSettingsKeys.reportIncludeStorageScan) private var includeStorageScan = true
  @AppStorage(CorewiseSettingsKeys.reportIncludeCrashSummary) private var includeCrashSummary = true

  var body: some View {
    SettingsPane(
      title: "Report",
      subtitle: "Control the local report format and which approved summaries are included.",
      systemImage: "doc.text"
    ) {
      Form {
        Section("Default format") {
          Picker("Report view", selection: $defaultFormat) {
            ForEach(ReportFormatPreference.allCases) { format in
              Text(format.title).tag(format.rawValue)
            }
          }
          .pickerStyle(.segmented)
        }

        Section("Included summaries") {
          Toggle("Include selected storage scan", isOn: $includeStorageScan)
          Toggle("Include app issue summary", isOn: $includeCrashSummary)
        }

        Section("Privacy boundary") {
          SettingsInfoRow(
            title: "Safe copied output",
            detail: "Reports exclude raw crash bodies, stack traces, prompts, process arguments, uploads, and file contents.",
            systemImage: "doc.on.clipboard"
          )
        }
      }
    }
  }
}

private struct MenuBarSettingsPane: View {
  @ObservedObject var store: HealthDashboardStore
  @AppStorage(CorewiseSettingsKeys.menuBarShowCPU) private var showCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowMemory) private var showMemory = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowSwap) private var showSwap = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowAIWorkloads) private var showAIWorkloads = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopCPU) private var showTopCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopMemory) private var showTopMemory = true
  @AppStorage(CorewiseSettingsKeys.menuBarProcessRowCount) private var processRowCount = MenuBarPreferences.defaultProcessRowCount

  var body: some View {
    SettingsPane(
      title: "Menu Bar",
      subtitle: "Keep the monitor focused on the signals and workloads you actually check.",
      systemImage: "menubar.rectangle"
    ) {
      Form {
        Section("Current layout") {
          MenuBarLayoutPreview(
            snapshot: store.snapshot,
            showCPU: showCPU,
            showMemory: showMemory,
            showSwap: showSwap,
            showAIWorkloads: showAIWorkloads,
            showTopCPU: showTopCPU,
            showTopMemory: showTopMemory
          )
        }

        Section("Live metrics") {
          Toggle("CPU", isOn: $showCPU)
          Toggle("Memory", isOn: $showMemory)
          Toggle("Swap", isOn: $showSwap)
        }

        Section("Workload context") {
          Toggle("AI Workloads", isOn: $showAIWorkloads)
          Toggle("Top CPU processes", isOn: $showTopCPU)
          Toggle("Top Memory processes", isOn: $showTopMemory)
        }

        Section("Density") {
          Stepper(value: processRowCountBinding, in: MenuBarPreferences.allowedProcessRowCount) {
            LabeledContent("Rows per list", value: "\(normalizedProcessRowCount)")
          }

          HStack {
            Text("Status, freshness, Focused Check, and Open Corewise always remain available.")
              .font(.callout)
              .foregroundStyle(.secondary)
            Spacer(minLength: CorewiseLayout.space16)
            Button("Restore Defaults", action: restoreDefaults)
          }
        }
      }
    }
  }

  private var normalizedProcessRowCount: Int {
    MenuBarPreferences.normalizedProcessRowCount(processRowCount)
  }

  private var processRowCountBinding: Binding<Int> {
    Binding(
      get: { normalizedProcessRowCount },
      set: { processRowCount = MenuBarPreferences.normalizedProcessRowCount($0) }
    )
  }

  private func restoreDefaults() {
    showCPU = true
    showMemory = true
    showSwap = true
    showAIWorkloads = true
    showTopCPU = true
    showTopMemory = true
    processRowCount = MenuBarPreferences.defaultProcessRowCount
  }
}

private struct SettingsPane<Content: View>: View {
  var title: String
  var subtitle: String
  var systemImage: String
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: CorewiseLayout.space16) {
        Image(systemName: systemImage)
          .font(.title2.weight(.medium))
          .foregroundStyle(CorewiseVisual.accent)
          .frame(width: 44, height: 44)
          .background(CorewiseVisual.accent.opacity(0.10), in: .rect(cornerRadius: 11))
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text(title)
            .font(.title2.weight(.semibold))
          Text(subtitle)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, CorewiseLayout.space24)
      .padding(.vertical, CorewiseLayout.space20)

      Divider()

      content()
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
    .background(CorewiseVisual.windowBackground)
  }
}

private struct MenuBarLayoutPreview: View {
  var snapshot: HealthSnapshot?
  var showCPU: Bool
  var showMemory: Bool
  var showSwap: Bool
  var showAIWorkloads: Bool
  var showTopCPU: Bool
  var showTopMemory: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
      HStack(spacing: CorewiseLayout.space12) {
        CorewiseBrandGlyph(size: 34, stateColor: previewStateColor)
        VStack(alignment: .leading, spacing: 2) {
          Text("Corewise monitor")
            .font(.headline)
          Text(previewDetail)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text("Live")
          .font(.caption.weight(.semibold))
          .foregroundStyle(CorewiseVisual.accent)
      }

      if visibleLabels.isEmpty {
        Text("Only the status summary and actions are visible.")
          .font(.callout)
          .foregroundStyle(.secondary)
      } else {
        HStack(spacing: CorewiseLayout.space8) {
          ForEach(visibleLabels, id: \.self) { label in
            Text(label)
              .font(.caption.weight(.medium))
              .padding(.horizontal, CorewiseLayout.space8)
              .padding(.vertical, CorewiseLayout.space4)
              .background(CorewiseVisual.elevatedSurface, in: .capsule)
          }
          Spacer(minLength: 0)
        }
      }
    }
    .padding(.vertical, CorewiseLayout.space4)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Menu bar preview, \(previewDetail), visible sections: \(visibleLabels.joined(separator: ", "))")
  }

  private var visibleLabels: [String] {
    var labels: [String] = []
    if showCPU { labels.append("CPU") }
    if showMemory { labels.append("Memory") }
    if showSwap { labels.append("Swap") }
    if showAIWorkloads { labels.append("AI") }
    if showTopCPU { labels.append("Top CPU") }
    if showTopMemory { labels.append("Top Memory") }
    return labels
  }

  private var previewDetail: String {
    guard let snapshot else { return "Waiting for the first local snapshot" }
    let aiCount = snapshot.performance.aiWorkloads.count
    return aiCount == 1 ? "1 supported local AI tool observed" : "\(aiCount) supported local AI tools observed"
  }

  private var previewStateColor: Color {
    guard let snapshot else { return CorewiseVisual.info }
    return CorewiseVisual.color(for: snapshot.attentionSummary.state)
  }
}

private struct SettingsInfoRow: View {
  var title: String
  var detail: String
  var systemImage: String

  var body: some View {
    HStack(alignment: .top, spacing: CorewiseLayout.space12) {
      Image(systemName: systemImage)
        .font(.callout)
        .foregroundStyle(CorewiseVisual.accent)
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.callout.weight(.semibold))
        Text(detail)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
  }
}

private struct SettingsExternalLinkRow: View {
  var title: String
  var detail: String
  var systemImage: String
  var destination: URL

  var body: some View {
    Link(destination: destination) {
      HStack(alignment: .top, spacing: CorewiseLayout.space12) {
        Image(systemName: systemImage)
          .font(.callout)
          .foregroundStyle(CorewiseVisual.accent)
          .frame(width: 18, height: 18)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 3) {
          Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.primary)
          Text(detail)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: CorewiseLayout.space12)

        Image(systemName: "arrow.up.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
      }
      .contentShape(.rect)
      .padding(.vertical, 2)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityHint("Opens in your default browser")
  }
}
