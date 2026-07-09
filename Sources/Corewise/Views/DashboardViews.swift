import Charts
import AppKit
import SwiftUI

struct OverviewView: View {
  var snapshot: HealthSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      CommandCenterHeader(snapshot: snapshot)

      OverviewSignalGrid(snapshot: snapshot)
      LiveLoadPanel(performance: snapshot.performance)

      LazyVGrid(columns: CorewiseLayout.panelGrid, alignment: .leading, spacing: CorewiseLayout.panelSpacing) {
        PriorityPanel(
          title: "What Corewise can see",
          subtitle: "Live signals first. Missing data is explicit.",
          findings: overviewFindings
        )

        SafeActionPanel(
          title: "Next safe moves",
          actions: overviewActions
        )
      }

      MetricBoard(metrics: snapshot.overviewMetrics)
      DataAccessPanel(capabilities: snapshot.dataAccess)
      SourceNote(text: "Overview leads with real local signals. Data Access below explains planned, unavailable, avoided, and user-selected paths without turning them into device health claims.")
    }
  }

  private var overviewFindings: [DiagnosticFinding] {
    [
      DiagnosticFinding(title: "Live signals are active", detail: "CPU, RAM, process rows, storage volume, battery basics, thermal state, and startup plist rows are read live where macOS exposes them.", status: .good, severityScore: 6),
      DiagnosticFinding(title: "Global score is planned", detail: "Corewise has live section data, but no real cross-section scoring model yet.", status: .info, severityScore: 0),
      DiagnosticFinding(title: "Manual scans unlock detail", detail: "Storage folder details and crash reports are read only after you choose a folder.", status: .info, severityScore: 12),
      DiagnosticFinding(title: "No destructive action is required", detail: "Corewise explains signals and leaves every change to you.", status: .good, severityScore: 0)
    ]
  }

  private var overviewActions: [SafeAction] {
    [
      SafeAction(title: "Review live sections first", body: "Use CPU, RAM, storage capacity, battery basics, thermal state, and startup plist rows as the trustworthy set.", systemImage: "checkmark.shield", status: .good),
      SafeAction(title: "Watch CPU/RAM for repeats", body: "A single spike matters less than the same process staying high across refreshes.", systemImage: "chart.bar.xaxis", status: .info),
      SafeAction(title: "Keep control manual", body: "Use macOS or vendor tools for any change.", systemImage: "hand.raised", status: .good)
    ]
  }
}

struct BatteryView: View {
  var battery: BatteryHealth

  var body: some View {
    DiagnosticPage(
      title: "Battery",
      subtitle: "Capacity, cycles, charge state, and energy risk.",
      systemImage: "battery.75percent",
      summary: battery.summary,
      metrics: battery.metrics,
      findings: battery.findings,
      actions: battery.actions,
      sourceNote: battery.sourceNote
    )
  }
}

struct StorageView: View {
  var storage: StorageHealth
  var scanSession: StorageScanSession?
  var isScanning: Bool
  var scanFolder: () -> Void
  var scanDownloads: () -> Void
  var scanDeveloperData: () -> Void
  var scanFolderAt: (URL) -> Void
  var scanParent: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      SectionHero(
        title: "Storage",
        subtitle: "\(gb(storage.availableGB)) free of \(gb(storage.totalGB)). Personal folders are not scanned automatically.",
        systemImage: "internaldrive",
        metric: storage.summary
      )

      LazyVGrid(columns: CorewiseLayout.panelGrid, alignment: .leading, spacing: CorewiseLayout.panelSpacing) {
        PremiumPanel(title: "Breakdown", subtitle: "GB by category", systemImage: "chart.pie") {
          StorageBreakdownChart(data: storage.breakdown)
        }

        PremiumPanel(title: "Largest items from selected scan", subtitle: "Manual scan results, not cleanup commands", systemImage: "chart.bar.xaxis") {
          HorizontalBarChart(data: storage.spaceOffenders, unit: "GB")
        }
      }

      ManualScanPanel(
        title: "Targeted scan",
        subtitle: "Choose one folder. Corewise reads file sizes only.",
        isRunning: isScanning,
        primaryTitle: "Choose Folder",
        primaryAction: scanFolder,
        secondaryActions: [
          ("Review Downloads", scanDownloads),
          ("Review Developer Data", scanDeveloperData)
        ]
      )

      StorageExplorerPanel(
        session: scanSession,
        isScanning: isScanning,
        scanFolderAt: scanFolderAt,
        scanParent: scanParent
      )
      MetricBoard(metrics: storage.metrics)
      PriorityPanel(title: "Findings", subtitle: "What the storage picture means.", findings: storage.findings)
      SafeActionPanel(title: "Safe actions", actions: storage.actions)
      SourceNote(text: storage.sourceNote, dataMode: storage.summary.dataMode)
    }
  }
}

struct PerformanceView: View {
  var performance: PerformanceHealth
  @AppStorage(CorewiseSettingsKeys.performanceDefaultFocus) private var defaultFocus = PerformanceDefaultFocus.cpu.rawValue
  @State private var selectedMode: PerformanceMode = .cpu

  private var sortedProcesses: [ProcessObservation] {
    selectedMode == .cpu
      ? performance.processes.sorted { $0.cpuPercent > $1.cpuPercent }
      : performance.processes.sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      SectionHero(
        title: "Performance",
        subtitle: "What is slowing your Mac right now, using live local process samples.",
        systemImage: "cpu",
        metric: performance.summary
      )

      PerformanceSystemStrip(performance: performance)

      HStack(spacing: 10) {
        Text("Focus")
          .font(.callout.weight(.semibold))
          .foregroundStyle(.secondary)
        Picker("Focus", selection: $selectedMode) {
          ForEach(PerformanceMode.allCases) { mode in
            Text(mode.title).tag(mode)
          }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(width: 190)
      }

      if selectedMode == .memory {
        SwapInsightPanel(insight: performance.swapInsight)
      }

      PerformancePressurePanel(mode: selectedMode, processes: Array(sortedProcesses.prefix(8)))

      ProcessObservationTable(
        mode: selectedMode,
        processes: sortedProcesses
      )

      SourceNote(text: "Process rows are live. Corewise shows observed memory, RSS, CPU, PID, and process ownership from public macOS APIs; row-level badges are intentionally omitted to keep the table readable.", dataMode: .live)
      MetricBoard(metrics: performance.metrics)

      ProcessInsightsPanel(insights: performance.insights)
      PriorityPanel(title: "Findings", subtitle: "Signals that deserve interpretation.", findings: performance.findings)
      SafeActionPanel(title: "Safe actions", actions: performance.actions)
      SourceNote(text: performance.sourceNote, dataMode: performance.summary.dataMode)
    }
    .onAppear {
      selectedMode = PerformanceMode(defaultFocus: defaultFocus)
    }
    .onChange(of: defaultFocus) { _, newValue in
      selectedMode = PerformanceMode(defaultFocus: newValue)
    }
  }
}

private enum PerformanceMode: String, CaseIterable, Identifiable {
  case cpu
  case memory

  var id: String { rawValue }

  var title: String {
    switch self {
    case .cpu: "CPU"
    case .memory: "Memory"
    }
  }

  init(defaultFocus rawValue: String) {
    self = PerformanceMode(rawValue: PerformanceDefaultFocus.normalized(rawValue).rawValue) ?? .cpu
  }
}

struct StartupView: View {
  var startup: StartupHealth

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      SectionHero(
        title: "Startup",
        subtitle: "Login items, agents, daemons, background services, and privileged helpers.",
        systemImage: "power",
        metric: startup.summary
      )

      MetricBoard(metrics: startup.metrics)
      StartupInventoryTable(items: startup.launchAgents + startup.launchDaemons)
      StartupItemGroup(title: "Login Items", items: startup.loginItems)
      StartupItemGroup(title: "Background Items", items: startup.backgroundItems)
      StartupItemGroup(title: "Privileged Helpers", items: startup.privilegedHelpers)
      PriorityPanel(title: "Findings", subtitle: "Startup load without scare tactics.", findings: startup.findings)
      SafeActionPanel(title: "Safe actions", actions: startup.actions)
      SourceNote(text: startup.sourceNote, dataMode: startup.summary.dataMode)
    }
  }
}

struct ThermalView: View {
  var thermal: ThermalHealth

  var body: some View {
    DiagnosticPage(
      title: "Thermal",
      subtitle: "Safe macOS thermal pressure signals and likely contributors.",
      systemImage: "thermometer.medium",
      summary: thermal.summary,
      metrics: thermal.metrics,
      findings: thermal.contributors,
      actions: thermal.actions,
      sourceNote: thermal.sourceNote
    )
  }
}

struct IssuesView: View {
  var appIssues: AppIssuesHealth
  var isScanningReports: Bool
  var scanReports: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      SectionHero(
        title: "App Issues",
        subtitle: "Repeated crashes, bundle IDs, versions, and diagnostic access.",
        systemImage: "app.badge",
        metric: appIssues.summary
      )

      MetricBoard(metrics: appIssues.metrics)
      CrashAccessPanel(appIssues: appIssues)

      ManualScanPanel(
        title: "Crash report scan",
        subtitle: "Choose a reports folder. Corewise reads metadata only.",
        isRunning: isScanningReports,
        primaryTitle: "Choose Reports",
        primaryAction: scanReports,
        secondaryActions: []
      )

      PremiumPanel(title: "Crashes by app", subtitle: "Last 30 days. Repetition matters more than one-offs.", systemImage: "chart.bar.xaxis") {
        HorizontalBarChart(data: appIssues.crashesByApp, unit: "crashes")
      }

      CrashList(issues: appIssues.crashes)
      PriorityPanel(title: "Findings", subtitle: "Crash patterns Corewise can explain safely.", findings: appIssues.findings)
      SafeActionPanel(title: "Safe actions", actions: appIssues.actions)
      SourceNote(text: appIssues.sourceNote, dataMode: appIssues.summary.dataMode)
    }
  }
}

struct ReportView: View {
  var snapshot: HealthSnapshot
  @AppStorage(CorewiseSettingsKeys.reportDefaultFormat) private var defaultReportFormat = ReportFormatPreference.summary.rawValue
  @AppStorage(CorewiseSettingsKeys.reportIncludeStorageScan) private var includeStorageScan = true
  @AppStorage(CorewiseSettingsKeys.reportIncludeCrashSummary) private var includeCrashSummary = true
  @State private var reportMode: ReportFormatPreference = .summary
  @State private var copiedLabel: String?

  private var reportOptions: DiagnosticReportOptions {
    DiagnosticReportOptions(
      includeStorageScan: includeStorageScan,
      includeCrashSummary: includeCrashSummary
    )
  }

  private var summaryText: String {
    DiagnosticReportBuilder().summary(for: snapshot, options: reportOptions)
  }

  private var markdownText: String {
    DiagnosticReportBuilder().markdown(for: snapshot, options: reportOptions)
  }

  private var previewText: String {
    switch reportMode {
    case .summary:
      summaryText
    case .markdown:
      markdownText
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      SectionHero(
        title: "Report",
        subtitle: "A local read-only diagnostic summary you can copy and review.",
        systemImage: "doc.text.magnifyingglass",
        metric: DiagnosticMetric(
          title: "Diagnostic Report",
          value: "Ready",
          unit: "",
          dataMode: .live,
          status: .good,
          severityScore: 0,
          explanation: "Generated from the current local snapshot without stack traces, uploads, cleanup, or file contents.",
          source: "Current Corewise snapshot",
          confidence: "Live / high",
          recommendedAction: "Copy the report when you want a plain-text summary.",
          lastUpdated: snapshot.generatedAt
        )
      )

      PremiumPanel(title: "Copy report", subtitle: "Summary or Markdown. Local clipboard only.", systemImage: "doc.on.clipboard") {
        VStack(alignment: .leading, spacing: 14) {
          Picker("Report format", selection: $reportMode) {
            ForEach(ReportFormatPreference.allCases) { mode in
              Text(mode.title).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .frame(maxWidth: 280)

          HStack(spacing: 10) {
            Button {
              copy(summaryText, label: "Summary copied")
            } label: {
              Label("Copy Summary", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)

            Button {
              copy(markdownText, label: "Markdown copied")
            } label: {
              Label("Copy Markdown", systemImage: "text.page")
            }
            .buttonStyle(.bordered)

            if let copiedLabel {
              Text(copiedLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color(for: FindingSeverity.good))
            }

            Spacer(minLength: 0)
          }
        }
      }

      PremiumPanel(title: reportMode.title, subtitle: "Safe summary only. No stack traces or file contents.", systemImage: "text.page") {
        ScrollView {
          Text(previewText)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 360)
      }

      SourceNote(text: "Report export is local clipboard text. Corewise does not upload reports, include crash stack traces, or modify files.", dataMode: .live)
    }
    .onAppear {
      reportMode = ReportFormatPreference.normalized(defaultReportFormat)
    }
    .onChange(of: defaultReportFormat) { _, newValue in
      reportMode = ReportFormatPreference.normalized(newValue)
    }
  }

  private func copy(_ text: String, label: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    copiedLabel = label
  }
}

private struct DiagnosticPage: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
      SectionHero(title: title, subtitle: subtitle, systemImage: systemImage, metric: summary)
      MetricBoard(metrics: metrics)
      PriorityPanel(title: "Findings", subtitle: "Plain-language interpretation.", findings: findings)
      SafeActionPanel(title: "Safe actions", actions: actions)
      SourceNote(text: sourceNote, dataMode: summary.dataMode)
    }
  }
}

private struct CommandCenterHeader: View {
  var snapshot: HealthSnapshot

  var body: some View {
    PremiumPanel {
      HStack(alignment: .center, spacing: 24) {
        CoverageRing(summary: snapshot.coverageSummary)
          .frame(width: 132, height: 132)

        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
              .foregroundStyle(color(for: FindingSeverity.good))
            Text("Live Signals")
              .font(.system(size: 30, weight: .semibold))
          }

          Text("Corewise is reading real local system signals.")
            .font(.title3.weight(.medium))

          Text("Performance, storage volume, battery basics, thermal state, and startup plist data are live where macOS exposes them. Global scoring remains planned.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)

          HStack(spacing: 8) {
            DataModeBadge(dataMode: .live)
            Text("Score Planned")
              .font(.caption.weight(.semibold))
              .foregroundStyle(color(for: .planned))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(color(for: .planned).opacity(0.16), in: Capsule())
            Text("Updated \(snapshot.generatedAt.formatted(date: .omitted, time: .shortened))")
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
        }

        Spacer(minLength: 0)
      }
    }
  }
}

private struct SectionHero: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var metric: DiagnosticMetric

  var body: some View {
    PremiumPanel {
      HStack(alignment: .center, spacing: 18) {
        IconPlate(systemImage: systemImage, status: metric.status)

        VStack(alignment: .leading, spacing: 7) {
          Text(title)
            .font(.system(size: 28, weight: .semibold))
          Text(subtitle)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 16)

        VStack(alignment: .trailing, spacing: 6) {
          Text(displayValue(metric))
            .font(.system(size: 30, weight: .semibold, design: .rounded))
          HStack(spacing: 6) {
            DataModeBadge(dataMode: metric.dataMode)
            StatusBadge(status: metric.status, score: metric.severityScore)
          }
        }
      }
    }
  }
}

private struct LiveLoadPanel: View {
  var performance: PerformanceHealth

  var body: some View {
    LazyVGrid(columns: CorewiseLayout.panelGrid, alignment: .leading, spacing: CorewiseLayout.panelSpacing) {
      ProcessChartPanel(
        title: "CPU now",
        subtitle: "Top individual processes from a live 1 second sample.",
        systemImage: "cpu",
        processes: performance.processes.sorted { $0.cpuPercent > $1.cpuPercent },
        mode: .cpu
      )

      ProcessChartPanel(
        title: "Memory now",
        subtitle: "Top individual processes by observed memory.",
        systemImage: "memorychip",
        processes: performance.processes.sorted { $0.observedMemoryBytes > $1.observedMemoryBytes },
        mode: .memory
      )
    }
  }
}

private struct OverviewSignalGrid: View {
  var snapshot: HealthSnapshot

  private var topCPU: ProcessObservation? {
    snapshot.performance.processes.max { $0.cpuPercent < $1.cpuPercent }
  }

  private var topMemory: ProcessObservation? {
    snapshot.performance.processes.max { $0.observedMemoryBytes < $1.observedMemoryBytes }
  }

  var body: some View {
    LazyVGrid(columns: CorewiseLayout.metricGrid, alignment: .leading, spacing: CorewiseLayout.tileSpacing) {
      CompactStat(title: "CPU", value: percent(snapshot.performance.cpu.totalPercent), detail: cpuDetail)
      CompactStat(title: "Memory", value: bytes(snapshot.performance.memory.usedBytes), detail: memoryDetail)
      CompactStat(title: "Top CPU", value: topCPU.map { "\(number($0.cpuPercent))%" } ?? "N/A", detail: topCPU?.displayName ?? "No readable process")
      CompactStat(title: "Top Memory", value: topMemory.map { bytes($0.observedMemoryBytes) } ?? "N/A", detail: topMemory?.displayName ?? "No readable process")
      CompactStat(title: "Storage Free", value: gb(snapshot.storage.availableGB), detail: "\(number(snapshot.storage.availablePercent))% available")
      CompactStat(title: "Battery", value: displayValue(snapshot.battery.summary), detail: snapshot.battery.summary.dataMode.rawValue)
      CompactStat(title: "Thermal", value: displayValue(snapshot.thermal.summary), detail: snapshot.thermal.summary.dataMode.rawValue)
    }
  }

  private var cpuDetail: String {
    "user \(percent(snapshot.performance.cpu.userPercent)) · system \(percent(snapshot.performance.cpu.systemPercent))"
  }

  private var memoryDetail: String {
    let swap = snapshot.performance.memory.swapUsedBytes.map(bytes) ?? "N/A"
    let trend = snapshot.performance.swapInsight.trend == .unavailable
      ? "trend N/A"
      : snapshot.performance.swapInsight.trend.title.lowercased()
    return "swap \(swap) · \(trend)"
  }
}

private struct DataAccessPanel: View {
  var capabilities: [DataAccessCapability]
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    PremiumPanel(title: "Data access", subtitle: "What Corewise reads, asks for, or avoids.", systemImage: "lock.shield") {
      LazyVGrid(columns: CorewiseLayout.accessGrid, alignment: .leading, spacing: CorewiseLayout.tileSpacing) {
        ForEach(capabilities) { capability in
          VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text(capability.title)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
              Spacer(minLength: 8)
              DataModeBadge(dataMode: capability.dataMode)
            }

            Text(capability.reason)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(3)
              .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
              Text(capability.source)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
              if let actionLabel = capability.actionLabel {
                Spacer(minLength: 8)
                Text(actionLabel)
                  .font(.caption2.weight(.semibold))
                  .foregroundStyle(color(for: capability.dataMode))
              }
            }
          }
          .padding(10)
          .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
          .background(CorewiseVisual.tileFill(colorScheme: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(CorewiseVisual.hairline(colorScheme: colorScheme), lineWidth: 1)
          }
        }
      }
    }
  }
}

private struct ManualScanPanel: View {
  var title: String
  var subtitle: String
  var isRunning: Bool
  var primaryTitle: String
  var primaryAction: () -> Void
  var secondaryActions: [(String, () -> Void)]

  var body: some View {
    PremiumPanel(title: title, subtitle: subtitle, systemImage: "folder.badge.questionmark") {
      HStack(alignment: .center, spacing: 10) {
        Button {
          primaryAction()
        } label: {
          Label(primaryTitle, systemImage: "folder")
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRunning)

        ForEach(Array(secondaryActions.enumerated()), id: \.offset) { _, action in
          Button {
            action.1()
          } label: {
            Text(action.0)
          }
          .buttonStyle(.bordered)
          .disabled(isRunning)
        }

        if isRunning {
          ProgressView()
            .controlSize(.small)
            .padding(.leading, 4)
        }

        Spacer(minLength: 0)
      }
    }
  }
}

private struct AppGroupChartPanel: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var groups: [AppProcessGroup]
  var mode: PerformanceMode

  var body: some View {
    PremiumPanel(title: title, subtitle: subtitle, systemImage: systemImage) {
      AppGroupBarChart(groups: Array(groups.prefix(8)), mode: mode)
    }
  }
}

private struct ProcessChartPanel: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var processes: [ProcessObservation]
  var mode: PerformanceMode

  var body: some View {
    PremiumPanel(title: title, subtitle: subtitle, systemImage: systemImage) {
      ProcessBarChart(processes: Array(processes.prefix(8)), mode: mode)
    }
  }
}

private struct CoverageRing: View {
  var summary: DataCoverageSummary

  private var progress: Double {
    min(max(summary.livePercent / 100, 0), 1)
  }

  private var centerValue: String {
    "\(Int(summary.livePercent.rounded()))%"
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(.quaternary, lineWidth: 12)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(color(for: FindingSeverity.good), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text(centerValue)
          .font(.system(size: 38, weight: .semibold, design: .rounded))
        Text("Coverage")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        Text("\(summary.live)/\(summary.total) live")
          .font(.caption2.weight(.medium))
          .foregroundStyle(.tertiary)
      }
    }
    .accessibilityLabel("Data coverage \(summary.live) live signal families out of \(summary.total)")
  }
}

private struct MetricBoard: View {
  var metrics: [DiagnosticMetric]

  var body: some View {
    LazyVGrid(columns: CorewiseLayout.metricGrid, alignment: .leading, spacing: CorewiseLayout.tileSpacing) {
      ForEach(metrics) { metric in
        MetricTile(metric: metric)
      }
    }
  }
}

private struct MetricTile: View {
  var metric: DiagnosticMetric
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack(alignment: .firstTextBaseline) {
        Text(metric.title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Spacer(minLength: 8)
        DataModeBadge(dataMode: metric.dataMode)
      }

      Text(displayValue(metric))
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.82)

      Text(metric.explanation)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)

      Spacer(minLength: 0)

      HStack(spacing: 6) {
        StatusDot(status: metric.status)
        Text(metric.source)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
    .background(CorewiseVisual.tileFill(colorScheme: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(CorewiseVisual.hairline(colorScheme: colorScheme), lineWidth: 1)
    }
  }
}

private struct PremiumPanel<Content: View>: View {
  private var title: String?
  private var subtitle: String?
  private var systemImage: String?
  private var content: Content
  @Environment(\.colorScheme) private var colorScheme

  init(@ViewBuilder content: () -> Content) {
    self.title = nil
    self.subtitle = nil
    self.systemImage = nil
    self.content = content()
  }

  init(title: String, subtitle: String, systemImage: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let title, let subtitle, let systemImage {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
          Image(systemName: systemImage)
            .foregroundStyle(.secondary)
            .frame(width: 16)
          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.headline)
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
          Spacer(minLength: 0)
        }
      }

      content
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.regularMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(CorewiseVisual.panelFill(colorScheme: colorScheme))
        }
    }
    .overlay {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(CorewiseVisual.hairline(colorScheme: colorScheme), lineWidth: 1)
    }
  }
}

private struct PriorityPanel: View {
  var title: String
  var subtitle: String
  var findings: [DiagnosticFinding]

  var body: some View {
    PremiumPanel(title: title, subtitle: subtitle, systemImage: "magnifyingglass") {
      VStack(alignment: .leading, spacing: 10) {
        ForEach(findings) { finding in
          FindingLine(finding: finding)
        }
      }
    }
  }
}

private struct SafeActionPanel: View {
  var title: String
  var actions: [SafeAction]

  var body: some View {
    PremiumPanel(title: title, subtitle: "No automatic cleanup. Manual review only.", systemImage: "checkmark.shield") {
      VStack(alignment: .leading, spacing: 10) {
        ForEach(actions) { action in
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: action.systemImage)
              .foregroundStyle(color(for: action.status))
              .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
              Text(action.title)
                .font(.callout.weight(.semibold))
              Text(action.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .padding(.vertical, 2)
        }
      }
    }
  }
}

private struct FindingLine: View {
  var finding: DiagnosticFinding

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      StatusDot(status: finding.status)
        .padding(.top, 5)
      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline) {
          Text(finding.title)
            .font(.callout.weight(.semibold))
          Spacer(minLength: 8)
          Text("score \(finding.severityScore)")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        Text(finding.detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

private struct StorageBreakdownChart: View {
  var data: [ChartDatum]

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: .center, spacing: 18) {
        chart
        legend
      }

      VStack(alignment: .leading, spacing: 12) {
        chart
          .frame(maxWidth: .infinity, alignment: .center)
        legend
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var chart: some View {
    Chart(data) { item in
      SectorMark(
        angle: .value("Size", item.value),
        innerRadius: .ratio(0.64),
        angularInset: 1.2
      )
      .foregroundStyle(storageBreakdownColor(for: item))
    }
    .chartLegend(.hidden)
    .frame(width: 142, height: 142)
  }

  private var legend: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(data) { item in
        LegendRow(title: item.title, value: "\(number(item.value)) \(item.unit)", dataMode: item.dataMode, status: item.status)
      }
    }
    .frame(minWidth: 174, alignment: .leading)
  }
}

private struct HorizontalBarChart: View {
  var data: [ChartDatum]
  var unit: String

  var body: some View {
    if data.isEmpty {
      EmptyDiagnosticState(
        title: "Not scanned automatically",
        message: "Corewise does not inspect personal folders during automatic refresh.",
        dataMode: .unavailable
      )
      .frame(minHeight: 120)
    } else {
      Chart(data) { item in
        BarMark(
          x: .value(unit, item.value),
          y: .value("Item", item.title)
        )
        .foregroundStyle(color(for: item.status))
        .annotation(position: .trailing) {
          HStack(spacing: 5) {
            DataModeBadge(dataMode: item.dataMode)
            Text("\(number(item.value)) \(item.unit)")
              .font(.caption2.weight(.medium))
              .foregroundStyle(.secondary)
          }
        }
      }
      .chartXAxisLabel(unit)
      .chartLegend(.hidden)
      .frame(minHeight: CGFloat(max(data.count, 3)) * 32)
    }
  }
}

private struct PerformanceSystemStrip: View {
  var performance: PerformanceHealth

  var body: some View {
    LazyVGrid(columns: CorewiseLayout.metricGrid, alignment: .leading, spacing: CorewiseLayout.tileSpacing) {
      CompactStat(title: "CPU Total", value: percent(performance.cpu.totalPercent), detail: "user \(percent(performance.cpu.userPercent))")
      CompactStat(title: "CPU System", value: percent(performance.cpu.systemPercent), detail: "idle \(percent(performance.cpu.idlePercent))")
      CompactStat(title: "Memory", value: bytes(performance.memory.usedBytes), detail: "used")
      CompactStat(title: "Swap", value: performance.memory.swapUsedBytes.map(bytes) ?? "N/A", detail: performance.swapInsight.trend.title.lowercased())
      CompactStat(title: "Processes", value: "\(performance.processes.count)", detail: "sampled")
    }
  }
}

private struct CompactStat: View {
  var title: String
  var value: String
  var detail: String
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Text(detail)
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .padding(11)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(CorewiseVisual.tileFill(colorScheme: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(CorewiseVisual.hairline(colorScheme: colorScheme), lineWidth: 1)
    }
  }
}

private struct PerformancePressurePanel: View {
  var mode: PerformanceMode
  var processes: [ProcessObservation]

  var body: some View {
    PremiumPanel(
      title: mode == .cpu ? "Top CPU Pressure" : "Top Memory Pressure",
      subtitle: mode == .cpu ? "Highest live CPU samples right now" : "Highest observed memory right now",
      systemImage: mode == .cpu ? "cpu" : "memorychip"
    ) {
      ProcessBarChart(processes: processes, mode: mode)
    }
  }
}

private struct SwapInsightPanel: View {
  var insight: SwapInsight

  private var contributors: [SwapContributor] {
    Array(insight.contributors.prefix(6))
  }

  var body: some View {
    PremiumPanel(
      title: "Swap Insight",
      subtitle: "Real swap context, not per-process swap ownership.",
      systemImage: "arrow.triangle.2.circlepath"
    ) {
      VStack(alignment: .leading, spacing: 14) {
        LazyVGrid(columns: CorewiseLayout.metricGrid, alignment: .leading, spacing: CorewiseLayout.tileSpacing) {
          CompactStat(title: "Used", value: insight.reading.map { bytes($0.usedBytes) } ?? "Unavailable", detail: "system swap")
          CompactStat(title: "Total", value: insight.reading.map { bytes($0.totalBytes) } ?? "Unavailable", detail: "configured")
          CompactStat(title: "Available", value: insight.reading.map { bytes($0.availableBytes) } ?? "Unavailable", detail: "remaining")
          CompactStat(title: "Trend", value: insight.trend.title, detail: "120s window")
          CompactStat(title: "Swap Out", value: ratePerMinute(insight.swapOutRateBytesPerSecond), detail: "per minute")
          CompactStat(title: "Swapped", value: insight.reading.map { bytes($0.swappedBytes) } ?? "Unavailable", detail: "VM pages")
          CompactStat(title: "Encrypted", value: encryptedValue, detail: "macOS swap")
        }

        SourceNote(
          text: "macOS does not expose exact per-process swap ownership through public APIs. These rows show likely contributors based on live memory signals.",
          dataMode: insight.dataMode
        )

        VStack(alignment: .leading, spacing: 8) {
          Text("Likely memory pressure contributors")
            .font(.callout.weight(.semibold))
          if contributors.isEmpty {
            EmptyDiagnosticState(
              title: "No likely contributors yet",
              message: "Corewise needs live memory rows and at least one swap sample before it can rank likely pressure contributors.",
              dataMode: insight.dataMode
            )
          } else {
            VStack(spacing: 0) {
              SwapContributorHeader()
              ForEach(Array(contributors.enumerated()), id: \.element.id) { index, contributor in
                SwapContributorRow(contributor: contributor)
                if index < contributors.count - 1 {
                  Divider()
                }
              }
            }
          }
        }
      }
    }
  }

  private var encryptedValue: String {
    guard let reading = insight.reading else {
      return "Unavailable"
    }
    return reading.isEncrypted ? "Yes" : "No"
  }

  private func ratePerMinute(_ bytesPerSecond: Double?) -> String {
    guard let bytesPerSecond else {
      return "N/A"
    }
    return "\(bytes(UInt64(max(0, bytesPerSecond * 60))))/min"
  }
}

private struct SwapContributorHeader: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(spacing: 12) {
      header("Process")
        .frame(maxWidth: .infinity, alignment: .leading)
      header("Observed")
        .frame(width: 88, alignment: .trailing)
      header("RSS")
        .frame(width: 78, alignment: .trailing)
      header("Page-ins")
        .frame(width: 72, alignment: .trailing)
      header("Growth")
        .frame(width: 78, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(CorewiseVisual.tileFill(colorScheme: colorScheme), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
  }

  private func header(_ title: String) -> some View {
    Text(title)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(.secondary)
      .lineLimit(1)
  }
}

private struct SwapContributorRow: View {
  var contributor: SwapContributor
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(contributor.processName)
          .font(.caption.weight(.semibold))
          .lineLimit(1)
        Text(contributor.confidence)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(bytes(contributor.observedMemoryBytes))
        .font(.caption.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(CorewiseVisual.moss)
        .frame(width: 88, alignment: .trailing)

      Text(bytes(contributor.residentMemoryBytes))
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .frame(width: 78, alignment: .trailing)

      Text("\(contributor.pageIns)")
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .frame(width: 72, alignment: .trailing)

      Text(growthValue)
        .font(.caption)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .frame(width: 78, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(CorewiseVisual.tileFill(colorScheme: colorScheme).opacity(0.45), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
  }

  private var growthValue: String {
    if contributor.memoryGrowthBytes == 0 {
      return "0 MB"
    }
    return bytes(UInt64(max(0, contributor.memoryGrowthBytes)))
  }
}

private struct ProcessInsightsPanel: View {
  var insights: [ProcessInsight]

  var body: some View {
    PremiumPanel(title: "What this means", subtitle: "Plain-language context from live process names only.", systemImage: "text.magnifyingglass") {
      if insights.isEmpty {
        EmptyDiagnosticState(
          title: "No named process patterns detected",
          message: "Corewise still shows the live process table; there are no extra explanations for this sample yet.",
          dataMode: .unavailable
        )
      } else {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(insights) { insight in
            HStack(alignment: .top, spacing: 10) {
              StatusDot(status: insight.status)
                .padding(.top, 5)
              VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                  Text(insight.title)
                    .font(.callout.weight(.semibold))
                  Spacer(minLength: 8)
                  DataModeBadge(dataMode: insight.dataMode)
                }
                Text(insight.detail)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .fixedSize(horizontal: false, vertical: true)
                Text(insight.matchedProcessNames.joined(separator: ", "))
                  .font(.caption2)
                  .foregroundStyle(.tertiary)
                  .lineLimit(1)
                  .truncationMode(.tail)
              }
            }
          }
        }
      }
    }
  }
}

private struct AppGroupBarChart: View {
  var groups: [AppProcessGroup]
  var mode: PerformanceMode

  private var maxValue: Double {
    max(groups.map(value).max() ?? 1, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if groups.isEmpty {
        Text("No process crossed the current display threshold")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
      } else {
        ForEach(groups) { group in
          AppGroupUsageRow(group: group, mode: mode, maxValue: maxValue)
        }
      }
    }
    .frame(minHeight: groups.isEmpty ? 72 : CGFloat(max(groups.count, 3)) * 42)
  }

  private func value(_ group: AppProcessGroup) -> Double {
    switch mode {
    case .cpu:
      group.cpuPercent
    case .memory:
      Double(group.observedMemoryBytes) / SystemMetricsSampler.bytesPerGB
    }
  }
}

private struct AppGroupUsageRow: View {
  var group: AppProcessGroup
  var mode: PerformanceMode
  var maxValue: Double

  private var currentValue: Double {
    switch mode {
    case .cpu:
      group.cpuPercent
    case .memory:
      Double(group.observedMemoryBytes) / SystemMetricsSampler.bytesPerGB
    }
  }

  private var fraction: Double {
    min(max(currentValue / maxValue, 0), 1)
  }

  private var valueText: String {
    switch mode {
    case .cpu:
      "\(number(group.cpuPercent)) %"
    case .memory:
      bytes(group.observedMemoryBytes)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(group.name)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .truncationMode(.tail)

        Spacer(minLength: 10)

        Text(valueText)
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(color(for: group.status))
          .layoutPriority(1)

      }

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
          RoundedRectangle(cornerRadius: 4)
            .fill(color(for: group.status))
            .frame(width: max(proxy.size.width * fraction, currentValue > 0 ? 4 : 0))
        }
      }
      .frame(height: 9)
    }
  }
}

private struct ProcessBarChart: View {
  var processes: [ProcessObservation]
  var mode: PerformanceMode

  private var maxValue: Double {
    max(processes.map(value).max() ?? 1, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if processes.isEmpty {
        Text("No process crossed the current display threshold")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
      } else {
        ForEach(processes) { process in
          ProcessUsageRow(process: process, mode: mode, maxValue: maxValue)
        }
      }
    }
    .frame(minHeight: processes.isEmpty ? 72 : CGFloat(max(processes.count, 3)) * 42)
  }

  private func value(_ process: ProcessObservation) -> Double {
    switch mode {
    case .cpu:
      process.cpuPercent
    case .memory:
      Double(process.observedMemoryBytes) / SystemMetricsSampler.bytesPerGB
    }
  }
}

private struct ProcessUsageRow: View {
  var process: ProcessObservation
  var mode: PerformanceMode
  var maxValue: Double

  private var currentValue: Double {
    switch mode {
    case .cpu:
      process.cpuPercent
    case .memory:
      Double(process.observedMemoryBytes) / SystemMetricsSampler.bytesPerGB
    }
  }

  private var fraction: Double {
    min(max(currentValue / maxValue, 0), 1)
  }

  private var valueText: String {
    switch mode {
    case .cpu:
      "\(number(process.cpuPercent)) %"
    case .memory:
      bytes(process.observedMemoryBytes)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(process.displayName)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .truncationMode(.tail)

        Spacer(minLength: 10)

        Text(valueText)
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(color(for: process.status))
          .layoutPriority(1)

      }

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
          RoundedRectangle(cornerRadius: 4)
            .fill(color(for: process.status))
            .frame(width: max(proxy.size.width * fraction, currentValue > 0 ? 4 : 0))
        }
      }
      .frame(height: 9)
    }
  }
}

private struct ProcessObservationTable: View {
  var mode: PerformanceMode
  var processes: [ProcessObservation]

  var body: some View {
    PremiumPanel(title: "Processes", subtitle: "Top 24 individual rows from the current live sample.", systemImage: "list.bullet.rectangle") {
      if processes.isEmpty {
        EmptyDiagnosticState(
          title: "No process crossed the current display threshold",
          message: "Corewise is receiving the system sample, but no readable process row passed the current CPU or memory threshold.",
          dataMode: .unavailable
        )
      } else {
        VStack(alignment: .leading, spacing: 8) {
          SourceNote(
            text: "Live process data from public macOS process APIs. Memory is observed footprint when available, otherwise resident memory.",
            dataMode: .live
          )

          VStack(spacing: 0) {
          ProcessTableHeader(mode: mode)
            ForEach(Array(processes.prefix(24).enumerated()), id: \.element.id) { index, process in
              ProcessTableRow(process: process, mode: mode, index: index)
              if index < min(processes.count, 24) - 1 {
                Divider()
              }
            }
          }
        }
        .font(.caption)
      }
    }
  }
}

private struct ProcessTableHeader: View {
  var mode: PerformanceMode
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(spacing: 12) {
      header("Process")
        .frame(maxWidth: .infinity, alignment: .leading)
      header(mode == .cpu ? "% CPU" : "Memory")
        .frame(width: 92, alignment: .trailing)
      header(mode == .cpu ? "Memory" : "RSS")
        .frame(width: 86, alignment: .trailing)
      header("PID")
        .frame(width: 58, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 7)
    .background(CorewiseVisual.tileFill(colorScheme: colorScheme), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
  }

  private func header(_ title: String) -> some View {
    Text(title)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(.secondary)
      .lineLimit(1)
  }
}

private struct ProcessTableRow: View {
  var process: ProcessObservation
  var mode: PerformanceMode
  var index: Int
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(process.displayName)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
          if process.processName == "Corewise" {
            Text("This app")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(CorewiseVisual.accent)
          }
        }
        Text(processContext)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(primaryValue)
        .font(.caption.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(color(for: process.status))
        .frame(width: 92, alignment: .trailing)

      Text(secondaryValue)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .frame(width: 86, alignment: .trailing)

      Text("\(process.pid)")
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .frame(width: 58, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(rowFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
  }

  private var primaryValue: String {
    switch mode {
    case .cpu:
      "\(number(process.cpuPercent)) %"
    case .memory:
      bytes(process.observedMemoryBytes)
    }
  }

  private var secondaryValue: String {
    switch mode {
    case .cpu:
      bytes(process.observedMemoryBytes)
    case .memory:
      bytes(process.residentMemoryBytes)
    }
  }

  private var processContext: String {
    let owner = process.appName ?? processCategory
    return "\(owner) · \(process.user) · \(process.threadCount) threads"
  }

  private var processCategory: String {
    guard let path = process.path, !path.isEmpty else {
      return "Background process"
    }
    if path.hasPrefix("/System/") || path.hasPrefix("/usr/") {
      return "System process"
    }
    if path.contains(".app/") {
      return "App process"
    }
    return "Background process"
  }

  private var rowFill: Color {
    index.isMultiple(of: 2) ? CorewiseVisual.tileFill(colorScheme: colorScheme) : .clear
  }
}

private struct StorageExplorerPanel: View {
  var session: StorageScanSession?
  var isScanning: Bool
  var scanFolderAt: (URL) -> Void
  var scanParent: () -> Void

  var body: some View {
    PremiumPanel(title: "Selected Folder Explorer", subtitle: "Read-only drilldown inside the folder you chose.", systemImage: "folder.badge.gearshape") {
      if let session {
        VStack(alignment: .leading, spacing: 14) {
          HStack(alignment: .center, spacing: 8) {
            ForEach(Array(session.breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
              if index > 0 {
                Image(systemName: "chevron.right")
                  .font(.caption2)
                  .foregroundStyle(.tertiary)
              }
              Button {
                scanFolderAt(crumb.url)
              } label: {
                Text(crumb.title)
                  .lineLimit(1)
              }
              .buttonStyle(.link)
              .disabled(isScanning)
            }

            Spacer(minLength: 8)

            Button {
              revealInFinder(path: session.result.rootPath)
            } label: {
              Label("Open in Finder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
              scanParent()
            } label: {
              Label("Scan Parent", systemImage: "arrow.up")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isScanning || session.breadcrumbs.count <= 1)
          }

          LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
            CompactStat(title: "Current Folder", value: session.result.rootTitle, detail: "selected scope")
            CompactStat(title: "Scanned Size", value: gb(session.result.totalSizeGB), detail: "read-only")
            CompactStat(title: "Files", value: "\(session.result.scannedItemCount)", detail: "readable")
            CompactStat(title: "Unreadable", value: "\(session.result.inaccessibleItemCount)", detail: "omitted")
            CompactStat(title: "Duration", value: "\(number(session.result.scanDuration))s", detail: "last scan")
          }

          if session.result.largestFolders.isEmpty && session.result.largestFiles.isEmpty {
            EmptyDiagnosticState(
              title: "No large items found",
              message: "Corewise scanned the selected folder but did not find readable files to rank.",
              dataMode: .live
            )
          } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 12)], alignment: .leading, spacing: 12) {
              StorageExplorerList(
                title: "Largest Folders",
                items: session.result.largestFolders,
                actionTitle: "Scan This Folder",
                actionImage: "arrow.down.forward.circle",
                action: { item in scanFolderAt(fileURL(for: item.path)) }
              )

              StorageExplorerList(
                title: "Largest Files",
                items: session.result.largestFiles,
                actionTitle: "Reveal in Finder",
                actionImage: "arrow.up.forward.app",
                action: { item in revealInFinder(path: item.path) }
              )
            }
          }
        }
      } else {
        EmptyDiagnosticState(
          title: "Choose a folder to scan",
          message: "Corewise will show breadcrumbs, largest folders, largest files, unreadable count, and scan duration after a manual folder choice.",
          dataMode: .unavailable
        )
      }
    }
  }
}

private struct StorageExplorerList: View {
  var title: String
  var items: [StorageItem]
  var actionTitle: String
  var actionImage: String
  var action: (StorageItem) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.callout.weight(.semibold))

      if items.isEmpty {
        Text("No readable rows")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        ForEach(items.prefix(8)) { item in
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
              Text(item.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
              Text(item.path)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Text(gb(item.sizeGB))
              .font(.caption.weight(.semibold))
              .monospacedDigit()
              .foregroundStyle(color(for: item.status))

            Button {
              action(item)
            } label: {
              Image(systemName: actionImage)
            }
            .buttonStyle(.borderless)
            .help(actionTitle)
          }
          Divider()
        }
      }
    }
    .padding(12)
    .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct StorageItemGroup: View {
  var title: String
  var items: [StorageItem]

  var body: some View {
    DataGroup(title: title, subtitle: "Size and safe interpretation", systemImage: "folder") {
      if items.isEmpty {
        EmptyDiagnosticState(
          title: "Not scanned automatically",
          message: "This category needs an explicit targeted scan before Corewise can show real values.",
          dataMode: .unavailable
        )
      } else {
        ForEach(items) { item in
          StorageItemRow(item: item)
        }
      }
    }
  }
}

private struct StorageItemRow: View {
  var item: StorageItem

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
      GridRow {
        HStack(spacing: 8) {
          StatusDot(status: item.status)
          VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
              .font(.callout.weight(.semibold))
            Text(item.path)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }

        Text(gb(item.sizeGB))
          .font(.callout.weight(.semibold))
          .frame(maxWidth: .infinity, alignment: .trailing)
      }

      GridRow {
        Text(item.explanation)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        Button {
          revealInFinder(path: item.path)
        } label: {
          Label("Reveal in Finder", systemImage: "arrow.up.forward.app")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .trailing)
      }

      GridRow {
        Text(item.recommendedAction)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("\(item.source) · \(item.confidence)")
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
    .padding(.vertical, 7)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.quaternary.opacity(0.55))
        .frame(height: 1)
    }
  }
}

private struct StorageScanEmptySummary: View {
  private let categories = ["Large folders", "Large files", "Developer caches", "Browser caches"]

  var body: some View {
    PremiumPanel(title: "Folder details", subtitle: "Available after a targeted scan", systemImage: "folder.badge.questionmark") {
      VStack(alignment: .leading, spacing: 12) {
        EmptyDiagnosticState(
          title: "Choose a folder to scan",
          message: "Corewise shows largest folders, files, and cache-like areas only after you select a folder.",
          dataMode: .unavailable
        )

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
          ForEach(categories, id: \.self) { category in
            Text(category)
              .font(.caption.weight(.medium))
              .foregroundStyle(.secondary)
              .lineLimit(1)
              .padding(.horizontal, 9)
              .padding(.vertical, 5)
              .background(.quaternary.opacity(0.55), in: Capsule())
          }
        }
      }
    }
  }
}

private struct StartupItemGroup: View {
  var title: String
  var items: [StartupItem]

  var body: some View {
    DataGroup(title: title, subtitle: "Startup impact and trust context", systemImage: "power") {
      if items.isEmpty {
        EmptyDiagnosticState(
          title: "No live rows available",
          message: "This category is empty, permission-limited, or planned for a later collector.",
          dataMode: .unavailable
        )
      } else {
        ForEach(items) { item in
          DetailRow(
            title: item.title,
            subtitle: "\(item.kind) · \(item.signedState) · \(item.recentlyAdded ? "recent" : "existing")",
            value: item.startupImpact,
            status: item.status,
            severityScore: item.severityScore,
            explanation: item.path,
            action: item.recommendedAction,
            source: "\(item.source) · \(item.confidence)",
            dataMode: item.dataMode
          )
        }
      }
    }
  }
}

private struct StartupInventoryTable: View {
  var items: [StartupItem]

  var body: some View {
    DataGroup(title: "Launch plist inventory", subtitle: "Readable LaunchAgents and LaunchDaemons. Presence alone is not a problem.", systemImage: "list.bullet.rectangle") {
      if items.isEmpty {
        EmptyDiagnosticState(
          title: "No readable launch plist rows",
          message: "Corewise did not find accessible LaunchAgents or LaunchDaemons plist metadata.",
          dataMode: .unavailable
        )
      } else {
        VStack(alignment: .leading, spacing: 0) {
          Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
              Text("Label")
              Text("Kind")
              Text("Executable")
              Text("Run")
              Text("Trust")
              Text("")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)

            ForEach(items) { item in
              StartupInventoryRow(item: item)
            }
          }
        }
      }
    }
  }
}

private struct StartupInventoryRow: View {
  var item: StartupItem

  var body: some View {
    GridRow {
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text(item.title)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
          if item.recentlyAdded {
            Text("Recent")
              .font(.caption2.weight(.bold))
              .foregroundStyle(color(for: FindingSeverity.info))
          }
        }
        Text(item.path)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Text(item.kind)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      Text(startupProgram(from: item.explanation))
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      Text(item.startupImpact)
        .font(.caption.weight(.semibold))
        .foregroundStyle(color(for: item.status))

      Text(item.signedState)
        .font(.caption.weight(.semibold))
        .foregroundStyle(color(for: signedSeverity(item.signedState)))
        .lineLimit(1)

      Button {
        revealInFinder(path: item.path)
      } label: {
        Label("Reveal", systemImage: "magnifyingglass")
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
      .help("Reveal plist in Finder")
    }
    .font(.caption)
  }
}

private struct CrashAccessPanel: View {
  var appIssues: AppIssuesHealth

  private var repeatedCount: Int {
    appIssues.crashes.filter(\.repeatedCrash).count
  }

  var body: some View {
    DataGroup(title: "Crash report access", subtitle: "Sensitive metadata is read only after folder selection.", systemImage: "lock.doc") {
      if appIssues.crashes.isEmpty {
        EmptyDiagnosticState(
          title: "Choose reports to unlock crash patterns",
          message: "Corewise does not scan DiagnosticReports automatically. After selection, it reads app name, date, bundle ID, version, and counts only.",
          dataMode: .unavailable
        )
      } else {
        LazyVGrid(columns: CorewiseLayout.metricGrid, alignment: .leading, spacing: CorewiseLayout.tileSpacing) {
          CompactStat(title: "Apps", value: "\(appIssues.crashes.count)", detail: "with readable reports")
          CompactStat(title: "Repeated", value: "\(repeatedCount)", detail: "apps with 2+ reports")
          CompactStat(title: "Last Crash", value: appIssues.crashes.map(\.lastCrashDate).max()?.formatted(date: .abbreviated, time: .omitted) ?? "Unavailable", detail: "selected reports")
        }
      }
    }
  }
}

private struct EmptyDiagnosticState: View {
  var title: String
  var message: String
  var dataMode: DataMode

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        DataModeBadge(dataMode: dataMode)
        Text(title)
          .font(.callout.weight(.semibold))
      }
      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct CrashList: View {
  var issues: [CrashIssue]

  var body: some View {
    DataGroup(title: "Crash Details", subtitle: "Repeated failures and diagnostic limits", systemImage: "exclamationmark.bubble") {
      if issues.isEmpty {
        EmptyDiagnosticState(
          title: "Diagnostic reports not read yet",
          message: "Choose a reports folder before Corewise can show app names or crash counts.",
          dataMode: .unavailable
        )
      } else {
        ForEach(issues) { issue in
          DetailRow(
            title: issue.appName,
            subtitle: "\(issue.bundleID) · v\(issue.appVersion) · \(issue.repeatedCrash ? "repeated" : "not repeated")",
            value: "\(issue.crashesLast7Days)/\(issue.crashesLast30Days)",
            status: issue.status,
            severityScore: issue.severityScore,
            explanation: "Last crash \(issue.lastCrashDate.formatted(date: .abbreviated, time: .omitted)). \(issue.explanation)",
            action: issue.recommendedAction,
            source: "\(issue.source) · \(issue.confidence) · \(issue.diagnosticPermissionState)",
            dataMode: issue.dataMode
          )
        }
      }
    }
  }
}

private struct DataGroup<Content: View>: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var content: Content

  init(title: String, subtitle: String, systemImage: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.subtitle = subtitle
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    PremiumPanel(title: title, subtitle: subtitle, systemImage: systemImage) {
      VStack(alignment: .leading, spacing: 8) {
        content
      }
    }
  }
}

private struct DetailRow: View {
  var title: String
  var subtitle: String
  var value: String
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var action: String
  var source: String
  var dataMode: DataMode

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
      GridRow {
        HStack(spacing: 8) {
          StatusDot(status: status)
          VStack(alignment: .leading, spacing: 2) {
            Text(title)
              .font(.callout.weight(.semibold))
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }

        Text(value)
          .font(.callout.weight(.semibold))
          .frame(maxWidth: .infinity, alignment: .trailing)
      }

      GridRow {
        Text(explanation)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 6) {
          DataModeBadge(dataMode: dataMode)
          Text("score \(severityScore)")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }

      GridRow {
        Text(action)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(source)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
    .padding(.vertical, 7)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(.quaternary.opacity(0.55))
        .frame(height: 1)
    }
  }
}

private struct IconPlate: View {
  var systemImage: String
  var status: FindingSeverity

  var body: some View {
    Image(systemName: systemImage)
      .font(.title2.weight(.semibold))
      .foregroundStyle(color(for: status))
      .frame(width: 46, height: 46)
      .background(
        LinearGradient(
          colors: [color(for: status).opacity(0.18), CorewiseVisual.accentSoft.opacity(0.08)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
      )
  }
}

private struct LegendRow: View {
  var title: String
  var value: String
  var dataMode: DataMode
  var status: FindingSeverity

  var body: some View {
    HStack(spacing: 8) {
      StatusDot(status: status)
      Text(title)
        .lineLimit(1)
        .truncationMode(.tail)
      Spacer(minLength: 8)
      DataModeBadge(dataMode: dataMode)
      Text(value)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .fixedSize(horizontal: true, vertical: false)
    }
    .font(.callout)
  }
}

private struct StatusPill: View {
  var status: OverallStatus

  var body: some View {
    Text(status.rawValue)
      .font(.caption.weight(.semibold))
      .foregroundStyle(color(for: status))
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background(color(for: status).opacity(0.14), in: Capsule())
  }
}

private struct StatusBadge: View {
  var status: FindingSeverity
  var score: Int

  var body: some View {
    Text("\(status.rawValue) · \(score)")
      .font(.caption.weight(.semibold))
      .foregroundStyle(color(for: status))
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background(color(for: status).opacity(0.14), in: Capsule())
  }
}

private struct DataModeBadge: View {
  var dataMode: DataMode

  var body: some View {
    Text(dataMode.rawValue)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(color(for: dataMode))
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(color(for: dataMode).opacity(0.14), in: Capsule())
      .accessibilityLabel("Data mode \(dataMode.rawValue)")
  }
}

private struct StatusDot: View {
  var status: FindingSeverity

  var body: some View {
    Circle()
      .fill(color(for: status))
      .frame(width: 8, height: 8)
  }
}

private struct SourceNote: View {
  var text: String
  var dataMode: DataMode? = nil
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      if let dataMode {
        DataModeBadge(dataMode: dataMode)
      }
      Text(text)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(CorewiseVisual.tileFill(colorScheme: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(CorewiseVisual.hairline(colorScheme: colorScheme), lineWidth: 1)
    }
  }
}

private func displayValue(_ metric: DiagnosticMetric) -> String {
  metric.unit.isEmpty ? metric.value : "\(metric.value) \(metric.unit)"
}

private func gb(_ value: Double) -> String {
  "\(number(value)) GB"
}

private func bytes(_ value: UInt64) -> String {
  let gb = Double(value) / SystemMetricsSampler.bytesPerGB
  if gb >= 1 {
    return "\(number(gb)) GB"
  }

  let mb = Double(value) / (1024.0 * 1024.0)
  return "\(number(mb)) MB"
}

private func percent(_ value: Double?) -> String {
  guard let value else {
    return "N/A"
  }
  return "\(number(value))%"
}

private func number(_ value: Double) -> String {
  if value.rounded() == value {
    return String(Int(value))
  }
  return String(format: "%.1f", value)
}

private func revealInFinder(path: String) {
  NSWorkspace.shared.activateFileViewerSelecting([fileURL(for: path)])
}

private func fileURL(for path: String) -> URL {
  if path.hasPrefix("~/") {
    return FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(String(path.dropFirst(2)))
  }
  return URL(fileURLWithPath: path)
}

private func startupProgram(from explanation: String) -> String {
  guard let programRange = explanation.range(of: "Program: ") else {
    return "Not specified"
  }

  let afterProgram = explanation[programRange.upperBound...]
  guard let runRange = afterProgram.range(of: ". RunAtLoad:") else {
    return String(afterProgram)
  }

  return String(afterProgram[..<runRange.lowerBound])
}

private func signedSeverity(_ value: String) -> FindingSeverity {
  let lowercased = value.lowercased()
  if lowercased.contains("signed") && !lowercased.contains("unsigned") {
    return .good
  }

  if lowercased.contains("unsigned") {
    return .warning
  }

  return .info
}

private func color(for status: OverallStatus) -> Color {
  switch status {
  case .notScored:
    CorewiseVisual.accent
  case .good:
    CorewiseVisual.moss
  case .needsAttention:
    CorewiseVisual.amber
  case .critical:
    Color(nsColor: .systemRed)
  }
}

private func color(for severity: FindingSeverity) -> Color {
  switch severity {
  case .good:
    CorewiseVisual.moss
  case .info:
    CorewiseVisual.accent
  case .warning:
    CorewiseVisual.amber
  case .critical:
    Color(nsColor: .systemRed)
  }
}

private func color(for dataMode: DataMode) -> Color {
  switch dataMode {
  case .live:
    CorewiseVisual.moss
  case .planned:
    CorewiseVisual.accent
  case .unavailable:
    Color(nsColor: .tertiaryLabelColor)
  case .avoided:
    Color(nsColor: .systemRed)
  }
}

private func storageBreakdownColor(for item: ChartDatum) -> Color {
  switch item.title {
  case "Available":
    CorewiseVisual.moss
  case "Used":
    Color(nsColor: .systemRed)
  default:
    color(for: item.status)
  }
}
