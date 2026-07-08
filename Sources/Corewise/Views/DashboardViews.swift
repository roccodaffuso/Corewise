import Charts
import SwiftUI

struct OverviewView: View {
  var snapshot: HealthSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      CommandCenterHeader(snapshot: snapshot)

      LiveLoadPanel(performance: snapshot.performance)

      HStack(alignment: .top, spacing: 14) {
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
      SourceNote(text: "Overview combines live signals with planned and unavailable coverage. Corewise shows missing data honestly and keeps every action manual.")
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
  var isScanning: Bool
  var scanFolder: () -> Void
  var scanDownloads: () -> Void
  var scanDeveloperData: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "Storage",
        subtitle: "\(gb(storage.availableGB)) free of \(gb(storage.totalGB)). Personal folders are not scanned automatically.",
        systemImage: "internaldrive",
        metric: storage.summary
      )

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 14)], spacing: 14) {
        PremiumPanel(title: "Breakdown", subtitle: "GB by category", systemImage: "chart.pie") {
          StorageBreakdownChart(data: storage.breakdown)
        }

        PremiumPanel(title: "Largest offenders", subtitle: "Review targets, not cleanup commands", systemImage: "chart.bar.xaxis") {
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

      MetricBoard(metrics: storage.metrics)
      if hasStorageScanRows {
        StorageItemGroup(title: "Large Folders", items: storage.largeFolders)
        StorageItemGroup(title: "Large Files", items: storage.largeFiles)
        StorageItemGroup(title: "Developer Caches", items: storage.developerCaches)
        StorageItemGroup(title: "Browser Caches", items: storage.browserCaches)
      } else {
        StorageScanEmptySummary()
      }
      PriorityPanel(title: "Findings", subtitle: "What the storage picture means.", findings: storage.findings)
      SafeActionPanel(title: "Safe actions", actions: storage.actions)
      SourceNote(text: storage.sourceNote, dataMode: storage.summary.dataMode)
    }
  }

  private var hasStorageScanRows: Bool {
    !storage.largeFolders.isEmpty
      || !storage.largeFiles.isEmpty
      || !storage.developerCaches.isEmpty
      || !storage.browserCaches.isEmpty
  }
}

struct PerformanceView: View {
  var performance: PerformanceHealth
  @State private var selectedMode: PerformanceMode = .cpu

  private var sortedProcesses: [ProcessObservation] {
    selectedMode == .cpu
      ? performance.processes.sorted { $0.cpuPercent > $1.cpuPercent }
      : performance.processes.sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "Performance",
        subtitle: "Live CPU and memory pressure from local process samples.",
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

      PerformancePressurePanel(mode: selectedMode, processes: Array(sortedProcesses.prefix(8)))

      ProcessObservationTable(
        mode: selectedMode,
        processes: sortedProcesses
      )

      MetricBoard(metrics: performance.metrics)

      PriorityPanel(title: "Findings", subtitle: "Signals that deserve interpretation.", findings: performance.findings)
      SafeActionPanel(title: "Safe actions", actions: performance.actions)
      SourceNote(text: performance.sourceNote, dataMode: performance.summary.dataMode)
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
}

struct StartupView: View {
  var startup: StartupHealth

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "Startup",
        subtitle: "Login items, agents, daemons, background services, and privileged helpers.",
        systemImage: "power",
        metric: startup.summary
      )

      MetricBoard(metrics: startup.metrics)
      StartupItemGroup(title: "Login Items", items: startup.loginItems)
      StartupItemGroup(title: "Launch Agents", items: startup.launchAgents)
      StartupItemGroup(title: "Launch Daemons", items: startup.launchDaemons)
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
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "App Issues",
        subtitle: "Repeated crashes, bundle IDs, versions, and diagnostic access.",
        systemImage: "app.badge",
        metric: appIssues.summary
      )

      MetricBoard(metrics: appIssues.metrics)

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

struct SettingsView: View {
  var body: some View {
    Form {
      Text("Corewise is local-first. This MVP does not use accounts, backend services, tracking, or automatic cleanup.")
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(width: 460)
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
    VStack(alignment: .leading, spacing: 20) {
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
    HStack(alignment: .top, spacing: 14) {
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

private struct DataAccessPanel: View {
  var capabilities: [DataAccessCapability]

  var body: some View {
    PremiumPanel(title: "Data access", subtitle: "What Corewise reads, asks for, or avoids.", systemImage: "lock.shield") {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 10)], spacing: 10) {
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
          .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
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
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
      ForEach(metrics) { metric in
        MetricTile(metric: metric)
      }
    }
  }
}

private struct MetricTile: View {
  var metric: DiagnosticMetric

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
    .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct PremiumPanel<Content: View>: View {
  private var title: String?
  private var subtitle: String?
  private var systemImage: String?
  private var content: Content

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
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.quaternary, lineWidth: 1)
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
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
      CompactStat(title: "CPU", value: percent(performance.cpu.totalPercent), detail: "total")
      CompactStat(title: "Memory", value: bytes(performance.memory.usedBytes), detail: "used")
      CompactStat(title: "Swap", value: performance.memory.swapUsedBytes.map(bytes) ?? "N/A", detail: "used")
      CompactStat(title: "Processes", value: "\(performance.processes.count)", detail: "sampled")
    }
  }
}

private struct CompactStat: View {
  var title: String
  var value: String
  var detail: String

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
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
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

        DataModeBadge(dataMode: group.dataMode)
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

        DataModeBadge(dataMode: process.dataMode)
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
    PremiumPanel(title: "Process Details", subtitle: "Top 24 individual rows from the current live sample.", systemImage: "list.bullet.rectangle") {
      if processes.isEmpty {
        EmptyDiagnosticState(
          title: "No process crossed the current display threshold",
          message: "Corewise is receiving the system sample, but no readable process row passed the current CPU or memory threshold.",
          dataMode: .unavailable
        )
      } else {
        VStack(spacing: 0) {
          ProcessTableHeader(mode: mode)
          ForEach(processes.prefix(24)) { process in
            ProcessTableRow(process: process, mode: mode)
            Divider()
          }
        }
        .font(.caption)
      }
    }
  }
}

private struct ProcessTableHeader: View {
  var mode: PerformanceMode

  var body: some View {
    Grid(horizontalSpacing: 12, verticalSpacing: 0) {
      GridRow {
        header("Process").gridColumnAlignment(.leading)
        header(mode == .cpu ? "% CPU" : "Memory").gridColumnAlignment(.trailing)
        header(mode == .cpu ? "Memory" : "RSS").gridColumnAlignment(.trailing)
        header("PID").gridColumnAlignment(.trailing)
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 6)
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

  var body: some View {
    Grid(horizontalSpacing: 14, verticalSpacing: 0) {
      GridRow {
        VStack(alignment: .leading, spacing: 2) {
          HStack(spacing: 6) {
            Text(process.displayName)
              .font(.caption.weight(.semibold))
              .lineLimit(1)
            if process.processName == "Corewise" {
              Text("This app")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.blue)
            }
          }
          Text(processContext)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .truncationMode(.tail)
        }
        .gridColumnAlignment(.leading)

        Text(primaryValue)
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(color(for: process.status))
          .gridColumnAlignment(.trailing)

        Text(secondaryValue)
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .gridColumnAlignment(.trailing)

        Text("\(process.pid)")
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .gridColumnAlignment(.trailing)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 8)
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
          DetailRow(
            title: item.title,
            subtitle: item.path,
            value: gb(item.sizeGB),
            status: item.status,
            severityScore: item.severityScore,
            explanation: item.explanation,
            action: item.recommendedAction,
            source: "\(item.source) · \(item.confidence)",
            dataMode: item.dataMode
          )
        }
      }
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
      .background(color(for: status).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
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
      .background(color(for: status).opacity(0.12), in: Capsule())
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
      .background(color(for: status).opacity(0.12), in: Capsule())
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
      .background(color(for: dataMode).opacity(0.12), in: Capsule())
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
    .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
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

private func color(for status: OverallStatus) -> Color {
  switch status {
  case .notScored:
    Color(nsColor: .systemBlue)
  case .good:
    Color(nsColor: .systemGreen)
  case .needsAttention:
    Color(nsColor: .systemOrange)
  case .critical:
    Color(nsColor: .systemRed)
  }
}

private func color(for severity: FindingSeverity) -> Color {
  switch severity {
  case .good:
    Color(nsColor: .systemGreen)
  case .info:
    Color(nsColor: .systemBlue)
  case .warning:
    Color(nsColor: .systemOrange)
  case .critical:
    Color(nsColor: .systemRed)
  }
}

private func color(for dataMode: DataMode) -> Color {
  switch dataMode {
  case .live:
    Color(nsColor: .systemGreen)
  case .planned:
    Color(nsColor: .systemBlue)
  case .unavailable:
    Color(nsColor: .tertiaryLabelColor)
  case .avoided:
    Color(nsColor: .systemRed)
  }
}

private func storageBreakdownColor(for item: ChartDatum) -> Color {
  switch item.title {
  case "Available":
    Color(nsColor: .systemGreen)
  case "Used":
    Color(nsColor: .systemRed)
  default:
    color(for: item.status)
  }
}
