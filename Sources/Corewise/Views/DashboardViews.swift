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
          title: "Needs attention",
          subtitle: "The shortest path to understanding what matters.",
          findings: overviewFindings
        )

        SafeActionPanel(
          title: "Next safe moves",
          actions: overviewActions
        )
      }

      MetricBoard(metrics: snapshot.overviewMetrics)
      SourceNote(text: "Overview combines live signals with planned and unavailable coverage. Corewise shows missing data honestly and keeps every action manual.")
    }
  }

  private var overviewFindings: [DiagnosticFinding] {
    [
      DiagnosticFinding(title: "Global score is not calculated yet", detail: "Corewise has live section data, but no real cross-section scoring model yet.", status: .info, severityScore: 0),
      DiagnosticFinding(title: "Live resource load is visible", detail: "CPU and memory rankings show which processes are currently consuming resources.", status: .info, severityScore: 24),
      DiagnosticFinding(title: "No destructive action is required", detail: "The safest first step is review: use live rows and ignore areas marked planned or unavailable.", status: .good, severityScore: 0)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "Storage",
        subtitle: "\(gb(storage.availableGB)) free of \(gb(storage.totalGB)). Personal folders are not scanned automatically.",
        systemImage: "internaldrive",
        metric: storage.summary
      )

      HStack(alignment: .top, spacing: 14) {
        PremiumPanel(title: "Breakdown", subtitle: "GB by category", systemImage: "chart.pie") {
          StorageBreakdownChart(data: storage.breakdown)
        }

        PremiumPanel(title: "Largest offenders", subtitle: "Review targets, not cleanup commands", systemImage: "chart.bar.xaxis") {
          HorizontalBarChart(data: storage.spaceOffenders, unit: "GB")
        }
      }

      MetricBoard(metrics: storage.metrics)
      StorageItemGroup(title: "Large Folders", items: storage.largeFolders)
      StorageItemGroup(title: "Large Files", items: storage.largeFiles)
      StorageItemGroup(title: "Developer Caches", items: storage.developerCaches)
      StorageItemGroup(title: "Browser Caches", items: storage.browserCaches)
      PriorityPanel(title: "Findings", subtitle: "What the storage picture means.", findings: storage.findings)
      SafeActionPanel(title: "Safe actions", actions: storage.actions)
      SourceNote(text: storage.sourceNote, dataMode: storage.summary.dataMode)
    }
  }
}

struct PerformanceView: View {
  var performance: PerformanceHealth

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "Performance",
        subtitle: "Live CPU and RAM by process, with context for pressure and sustained load.",
        systemImage: "cpu",
        metric: performance.summary
      )

      LiveLoadPanel(performance: performance)
      MetricBoard(metrics: performance.metrics)

      HStack(alignment: .top, spacing: 14) {
        ProcessList(title: "CPU Details", subtitle: "Processes sampled over a short live window.", items: performance.cpuProcesses)
        ProcessList(title: "Memory Details", subtitle: "Resident memory currently held by each process.", items: performance.memoryProcesses)
      }

      PriorityPanel(title: "Findings", subtitle: "Signals that deserve interpretation.", findings: performance.findings)
      SafeActionPanel(title: "Safe actions", actions: performance.actions)
      SourceNote(text: performance.sourceNote, dataMode: performance.summary.dataMode)
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

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SectionHero(
        title: "App Issues",
        subtitle: "Repeated crashes, bundle IDs, versions, and diagnostic access.",
        systemImage: "app.badge",
        metric: appIssues.summary
      )

      MetricBoard(metrics: appIssues.metrics)

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
        HealthScoreRing(score: snapshot.healthScore, status: snapshot.overallStatus)
          .frame(width: 132, height: 132)

        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 10) {
            Image(systemName: snapshot.overallStatus.systemImage)
              .foregroundStyle(color(for: snapshot.overallStatus))
            Text(snapshot.overallStatus.rawValue)
              .font(.system(size: 30, weight: .semibold))
          }

          Text("Your Mac’s health, explained clearly.")
            .font(.title3.weight(.medium))

          Text("Corewise separates live signals from planned and unavailable coverage, tells you what it cannot know yet, and keeps every action manual.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)

          HStack(spacing: 8) {
            StatusPill(status: snapshot.overallStatus)
            DataModeBadge(dataMode: .planned)
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
        subtitle: "Top app groups from live samples; idle apps may not appear.",
        systemImage: "cpu",
        processes: performance.cpuProcesses,
        unit: "% CPU"
      )

      ProcessChartPanel(
        title: "Memory now",
        subtitle: "Grouped by app bundle so helpers roll up to the app.",
        systemImage: "memorychip",
        processes: performance.memoryProcesses,
        unit: "GB"
      )
    }
  }
}

private struct ProcessChartPanel: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var processes: [ProcessSample]
  var unit: String

  var body: some View {
    PremiumPanel(title: title, subtitle: subtitle, systemImage: systemImage) {
      ProcessBarChart(processes: processes, unit: unit)
    }
  }
}

private struct HealthScoreRing: View {
  var score: Int
  var status: OverallStatus

  private var progress: Double {
    min(max(Double(score) / 100, 0), 1)
  }

  private var centerValue: String {
    status == .notScored ? "--" : "\(score)"
  }

  private var centerLabel: String {
    status == .notScored ? "Not scored" : "Score"
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(.quaternary, lineWidth: 12)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(color(for: status), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text(centerValue)
          .font(.system(size: 38, weight: .semibold, design: .rounded))
        Text(centerLabel)
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityLabel(status == .notScored ? "Health score not calculated yet" : "Health score \(score) out of 100")
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
          .lineLimit(1)
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
    HStack(alignment: .center, spacing: 18) {
      Chart(data) { item in
        SectorMark(
          angle: .value("Size", item.value),
          innerRadius: .ratio(0.64),
          angularInset: 1.2
        )
        .foregroundStyle(color(for: item.status))
      }
      .chartLegend(.hidden)
      .frame(width: 154, height: 154)

      VStack(alignment: .leading, spacing: 7) {
        ForEach(data) { item in
          LegendRow(title: item.title, value: "\(number(item.value)) \(item.unit)", dataMode: item.dataMode, status: item.status)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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

private struct ProcessBarChart: View {
  var processes: [ProcessSample]
  var unit: String

  private var maxValue: Double {
    max(processes.map(\.value).max() ?? 1, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if processes.isEmpty {
        Text("No live process samples available yet")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
      } else {
        ForEach(processes) { process in
          ProcessUsageRow(process: process, maxValue: maxValue)
        }
      }
    }
    .frame(minHeight: CGFloat(max(processes.count, 3)) * 42)
  }
}

private struct ProcessUsageRow: View {
  var process: ProcessSample
  var maxValue: Double

  private var fraction: Double {
    min(max(process.value / maxValue, 0), 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(process.name)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
          .truncationMode(.tail)

        Spacer(minLength: 10)

        Text("\(number(process.value)) \(process.unit)")
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
            .frame(width: max(proxy.size.width * fraction, process.value > 0 ? 4 : 0))
        }
      }
      .frame(height: 9)
    }
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

private struct ProcessList: View {
  var title: String
  var subtitle: String
  var items: [ProcessSample]

  var body: some View {
    DataGroup(title: title, subtitle: subtitle, systemImage: "waveform.path.ecg") {
      ForEach(items) { item in
        DetailRow(
          title: item.name,
          subtitle: item.explanation,
          value: "\(number(item.value)) \(item.unit)",
          status: item.status,
          severityScore: item.severityScore,
          explanation: item.recommendedAction,
          action: item.source,
          source: item.confidence,
          dataMode: item.dataMode
        )
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
          message: "Corewise has not implemented permitted crash report reading, so it does not show app names or crash counts.",
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
      Spacer(minLength: 8)
      DataModeBadge(dataMode: dataMode)
      Text(value)
        .foregroundStyle(.secondary)
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
