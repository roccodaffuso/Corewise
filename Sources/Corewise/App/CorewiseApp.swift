import SwiftUI

@main
struct CorewiseApp: App {
  @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appDelegate
  @StateObject private var store = HealthDashboardStore(collector: SystemHealthCollector())
  @State private var routeStore = AppRouteStore()

  var body: some Scene {
    Window("Corewise", id: "main") {
      ContentView(store: store)
        .environment(routeStore)
        .frame(minWidth: 980, minHeight: 680)
        .onAppear {
          store.startLiveRefreshIfNeeded()
        }
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 1180, height: 800)
    .windowResizability(.contentMinSize)
    .commands {
      CommandGroup(replacing: .newItem) {}
      CorewiseCommands()
    }

    Settings {
      SettingsView(store: store)
    }

    MenuBarExtra("Corewise", systemImage: "waveform.path.ecg") {
      MenuBarMonitorView(store: store)
        .environment(routeStore)
    }
    .menuBarExtraStyle(.window)
  }
}

private struct MenuBarMonitorView: View {
  @ObservedObject var store: HealthDashboardStore
  @Environment(AppRouteStore.self) private var routeStore
  @Environment(\.openWindow) private var openWindow
  @AppStorage(CorewiseSettingsKeys.menuBarShowCPU) private var showCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowMemory) private var showMemory = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowSwap) private var showSwap = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowAIWorkloads) private var showAIWorkloads = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopCPU) private var showTopCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopMemory) private var showTopMemory = true
  @AppStorage(CorewiseSettingsKeys.menuBarProcessRowCount) private var processRowCount = MenuBarPreferences.defaultProcessRowCount

  private var snapshot: HealthSnapshot? { store.snapshot }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let snapshot {
        if let session = store.focusedCheckSession, session.phase != .completed {
          MenuBarFocusedCheckHeader(session: session)
        } else if let result = store.lastFocusedCheckResult {
          MenuBarFocusedCheckResultHeader(result: result)
        } else {
          MenuBarStatusHeader(snapshot: snapshot)
        }

        if showCPU || showMemory || showSwap {
          MenuMetricStrip(snapshot: snapshot, showCPU: showCPU, showMemory: showMemory, showSwap: showSwap)
        }

        if showAIWorkloads {
          MenuAIWorkloadSection(
            workloads: visibleAIWorkloads(snapshot.performance.aiWorkloads),
            totalCount: snapshot.performance.aiWorkloads.count,
            open: { openPerformance(.aiWorkloads) }
          )
        }

        if showTopCPU {
          MenuProcessSection(title: "Top CPU", processes: Array(snapshot.performance.processes.prefix(visibleRowCount)), mode: .cpu, open: openPerformance)
        }
        if showTopMemory {
          MenuProcessSection(
            title: "Top Memory",
            processes: Array(snapshot.performance.processes.sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }.prefix(visibleRowCount)),
            mode: .memory,
            open: openPerformance
          )
        }

        Divider()
          .padding(.top, 2)
        HStack(spacing: CorewiseLayout.space8) {
          if store.focusedCheckSession != nil || store.lastFocusedCheckResult != nil {
            Button("Open Focused Check", systemImage: "scope", action: openOverview)
          } else {
            Menu("Start Focused Check", systemImage: "scope") {
              ForEach(FocusedCheckIntent.allCases) { intent in
                Button(intent.title) {
                  startFocusedCheck(intent)
                }
              }
            }
          }

          Spacer(minLength: 0)

          SettingsLink {
            Label("Customize", systemImage: "slider.horizontal.3")
          }
        }
        Button("Open Corewise", systemImage: "arrow.up.forward.app", action: openOverview)
          .buttonStyle(.borderedProminent)
          .controlSize(.regular)
          .frame(maxWidth: .infinity)
      } else {
        HStack {
          ProgressView()
          Text("Checking this Mac…")
        }
        .frame(maxWidth: .infinity, minHeight: 90)
      }
    }
    .padding(14)
    .frame(width: 344)
    .background(CorewiseVisual.windowBackground)
  }

  private func openOverview() {
    routeStore.show(.overview)
    openMainWindow()
  }

  private func openPerformance(_ mode: PerformanceMode) {
    routeStore.show(.performance, performanceMode: mode)
    openMainWindow()
  }

  private func startFocusedCheck(_ intent: FocusedCheckIntent) {
    store.startFocusedCheck(intent)
    routeStore.show(intent.launchRoute)
    openMainWindow()
  }

  private func openMainWindow() {
    openWindow(id: "main")
    NSApp.activate(ignoringOtherApps: true)
  }

  private var visibleRowCount: Int {
    MenuBarPreferences.normalizedProcessRowCount(processRowCount)
  }

  private func visibleAIWorkloads(_ workloads: [AIWorkloadObservation]) -> [AIWorkloadObservation] {
    Array(
      workloads
        .sorted {
          if $0.directObservedMemoryBytes != $1.directObservedMemoryBytes {
            return $0.directObservedMemoryBytes > $1.directObservedMemoryBytes
          }
          return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        .prefix(visibleRowCount)
    )
  }
}

private struct MenuBarFocusedCheckHeader: View {
  var session: FocusedCheckSession

  var body: some View {
    HStack(alignment: .center, spacing: CorewiseLayout.space12) {
      CorewiseBrandGlyph(size: 36, stateColor: CorewiseVisual.accent)
      VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
        Text("FOCUSED CHECK")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(session.intent.title)
          .font(.headline.weight(.semibold))
        Text(status)
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      Spacer()
      ProgressView()
        .controlSize(.small)
        .accessibilityLabel("Focused Check in progress")
    }
    .padding(12)
    .corewisePanel(instrument: true)
    .accessibilityElement(children: .combine)
  }

  private var status: String {
    switch session.intent {
    case .batteryDrain: "\(session.distinctBatterySampleCount) battery readings"
    case .storageFull:
      switch session.phase {
      case .awaitingAccess: "Storage access required"
      case .readyForStorageScan: "Limited folder confirmation required"
      default: "Storage scan in progress"
      }
    default: "\(session.systemSampleCount) live samples"
    }
  }
}

private struct MenuBarFocusedCheckResultHeader: View {
  var result: FocusedCheckResult

  var body: some View {
    HStack(alignment: .center, spacing: CorewiseLayout.space12) {
      CorewiseBrandGlyph(size: 36, stateColor: stateColor)
      VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
        Text("FOCUSED CHECK")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(result.headline)
          .font(.headline.weight(.semibold))
          .lineLimit(2)
        Text(result.intent.title)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: result.state == .clear ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        .foregroundStyle(stateColor)
        .accessibilityHidden(true)
    }
    .padding(12)
    .corewisePanel(instrument: true)
    .accessibilityElement(children: .combine)
  }

  private var stateColor: Color {
    switch result.state {
    case .clear: CorewiseVisual.good
    case .review: CorewiseVisual.warning
    case .critical: CorewiseVisual.critical
    case .unavailable, .insufficientEvidence: CorewiseVisual.info
    }
  }
}

private struct MenuBarStatusHeader: View {
  var snapshot: HealthSnapshot

  var body: some View {
    HStack(alignment: .center, spacing: CorewiseLayout.space12) {
      CorewiseBrandGlyph(size: 36, stateColor: CorewiseVisual.color(for: snapshot.attentionSummary.state))
      VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
        Text("COREWISE")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(snapshot.attentionSummary.headline)
          .font(.headline.weight(.semibold))
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
        Text(snapshot.attentionSummary.lastUpdated?.formatted(date: .omitted, time: .shortened) ?? "Live signals unavailable")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      Spacer()
      StatusBadge(state: snapshot.attentionSummary.state)
    }
    .padding(12)
    .corewisePanel(instrument: true)
    .accessibilityElement(children: .combine)
  }
}

private struct MenuMetricStrip: View {
  var snapshot: HealthSnapshot
  var showCPU: Bool
  var showMemory: Bool
  var showSwap: Bool

  var body: some View {
    HStack(spacing: CorewiseLayout.space8) {
      if showCPU {
        MenuMetricCard(
          title: "CPU",
          value: corewisePercent(snapshot.performance.cpu.totalPercent),
          detail: "load",
          fraction: (snapshot.performance.cpu.totalPercent ?? 0) / 100,
          tint: CorewiseVisual.accent
        )
      }
      if showMemory {
        MenuMetricCard(
          title: "Memory",
          value: "\(corewiseNumber(snapshot.performance.memory.usedPercent))%",
          detail: corewiseBytes(snapshot.performance.memory.usedBytes),
          fraction: snapshot.performance.memory.usedPercent / 100,
          tint: CorewiseVisual.good
        )
      }
      if showSwap {
        MenuMetricCard(
          title: "Swap",
          value: snapshot.performance.memory.swapUsedBytes.map(corewiseBytes) ?? "N/A",
          detail: snapshot.performance.memory.swapTotalGB.map { "of \(corewiseNumber($0)) GB" } ?? "unavailable",
          fraction: swapFraction,
          tint: CorewiseVisual.warning
        )
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var swapFraction: Double {
    guard
      let used = snapshot.performance.memory.swapUsedBytes,
      let totalGB = snapshot.performance.memory.swapTotalGB,
      totalGB > 0
    else {
      return 0
    }
    return min(max(Double(used) / (totalGB * 1_000_000_000), 0), 1)
  }
}

private struct MenuMetricCard: View {
  var title: String
  var value: String
  var detail: String
  var fraction: Double
  var tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title3.monospacedDigit().weight(.semibold))
      MenuProgressBar(value: fraction, tint: tint)
      Text(detail)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      ZStack {
        CorewiseVisual.quietSurface
        tint.opacity(0.07)
      }
    }
    .clipShape(.rect(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(tint.opacity(0.18), lineWidth: 0.8)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct MenuAIWorkloadSection: View {
  var workloads: [AIWorkloadObservation]
  var totalCount: Int
  var open: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
      HStack {
        Text("AI Workloads")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Label("\(totalCount) observed", systemImage: "sparkles.rectangle.stack")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }

      if workloads.isEmpty {
        Button(action: open) {
          HStack(spacing: CorewiseLayout.space8) {
            Image(systemName: "sparkles")
              .foregroundStyle(CorewiseVisual.accent)
            Text("No supported local AI workload observed")
              .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundStyle(.tertiary)
          }
          .contentShape(.rect)
        }
        .buttonStyle(.plain)
      } else {
        ForEach(workloads) { workload in
          MenuAIWorkloadRow(workload: workload, maxMemory: maxMemory, action: open)
        }
      }

      Text("Local process attribution only · cloud activity is not included")
        .font(.caption)
        .foregroundStyle(.tertiary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: 13))
    .overlay {
      RoundedRectangle(cornerRadius: 13)
        .stroke(CorewiseVisual.accent.opacity(0.22), lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("AI Workloads")
  }

  private var maxMemory: Double {
    max(Double(workloads.map(\.directObservedMemoryBytes).max() ?? 1), 1)
  }
}

private struct MenuAIWorkloadRow: View {
  var workload: AIWorkloadObservation
  var maxMemory: Double
  var action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: CorewiseLayout.space8) {
          Text(workload.name)
            .lineLimit(1)
          Text(workload.activity.title)
            .font(.caption)
            .foregroundStyle(activityColor)
          Spacer()
          Text(corewiseBytes(workload.directObservedMemoryBytes))
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        HStack(spacing: CorewiseLayout.space8) {
          MenuProgressBar(value: Double(workload.directObservedMemoryBytes) / maxMemory, tint: CorewiseVisual.accent)
          Text("\(corewisePercent(workload.totalCPUPercent)) CPU")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        if workload.relatedObservedMemoryBytes > 0 {
          Text("\(corewiseBytes(workload.relatedObservedMemoryBytes)) related local work")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
      .padding(.horizontal, CorewiseLayout.space8)
      .padding(.vertical, 6)
      .background(isHovered ? CorewiseVisual.elevatedSurface : .clear, in: .rect(cornerRadius: 7))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(workload.name), \(workload.activity.title), \(corewiseBytes(workload.directObservedMemoryBytes)) app footprint, \(corewisePercent(workload.totalCPUPercent)) CPU, \(corewiseBytes(workload.relatedObservedMemoryBytes)) related local work")
    .accessibilityHint("Opens AI Workloads in Performance")
  }

  private var activityColor: Color {
    switch workload.activity {
    case .active, .sustained: CorewiseVisual.accent
    case .quiet, .notObserved: .secondary
    }
  }
}

private struct MenuProcessSection: View {
  var title: String
  var processes: [ProcessObservation]
  var mode: PerformanceMode
  var open: (PerformanceMode) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
      HStack {
        Text(title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Image(systemName: mode == .cpu ? "cpu" : "memorychip")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      if processes.isEmpty {
        Text("No readable process rows")
          .font(.callout)
          .foregroundStyle(.secondary)
      } else {
        ForEach(Array(processes.enumerated()), id: \.element.id) { index, process in
          MenuProcessRow(index: index + 1, process: process, mode: mode, maxValue: maxValue) {
            open(mode)
          }
        }
      }
    }
    .padding(10)
    .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: 13))
    .overlay {
      RoundedRectangle(cornerRadius: 13)
        .stroke(CorewiseVisual.separator, lineWidth: 1)
    }
  }

  private var maxValue: Double {
    let values = processes.map {
      mode == .cpu ? $0.cpuPercent : Double($0.observedMemoryBytes)
    }
    return max(values.max() ?? 1, 1)
  }
}

private struct MenuProcessRow: View {
  var index: Int
  var process: ProcessObservation
  var mode: PerformanceMode
  var maxValue: Double
  var action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: CorewiseLayout.space8) {
          Text(String(index))
            .font(.caption.monospacedDigit())
            .foregroundStyle(.tertiary)
            .frame(width: 12)
          Text(process.displayName)
            .lineLimit(1)
          Spacer()
          Text(mode == .cpu ? corewisePercent(process.cpuPercent) : corewiseBytes(process.observedMemoryBytes))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        MenuProgressBar(value: currentValue / maxValue, tint: mode == .cpu ? CorewiseVisual.accent : CorewiseVisual.good)
      }
      .padding(.horizontal, CorewiseLayout.space8)
      .padding(.vertical, 6)
      .background(isHovered ? CorewiseVisual.elevatedSurface : .clear, in: .rect(cornerRadius: 7))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .accessibilityLabel("Open Performance for \(process.displayName)")
  }

  private var currentValue: Double {
    mode == .cpu ? process.cpuPercent : Double(process.observedMemoryBytes)
  }
}

private struct MenuProgressBar: View {
  var value: Double
  var tint: Color

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(CorewiseVisual.elevatedSurface.opacity(0.65))
        Capsule()
          .fill(tint.opacity(0.78))
          .frame(width: max(4, proxy.size.width * min(max(value, 0), 1)))
      }
    }
    .frame(height: 4)
    .accessibilityHidden(true)
  }
}
