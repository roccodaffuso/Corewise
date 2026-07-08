import Foundation

struct MockSystemHealthCollector: SystemHealthCollecting {
  private let performanceHistory = PerformanceHistoryTracker()

  func currentSnapshot() async throws -> HealthSnapshot {
    let now = Date()
    let instant = await SystemMetricsSampler.sample()
    let historySummary = performanceHistory.record(instant: instant, now: now)
    let cpuValue = instant.cpuPercent.map { number($0) } ?? "N/A"
    let memoryUsedValue = number(instant.usedMemoryGB)
    let memoryTotalValue = number(instant.totalMemoryGB)
    let memoryPercentValue = number(instant.memoryPercent)
    let batteryHealth = BatteryDiagnosticsCollector().currentBattery(now: now)
    let storageHealth = StorageDiagnosticsCollector().currentStorage(now: now)
    let startupHealth = StartupDiagnosticsCollector().currentStartup(now: now)
    let thermalState = ProcessInfo.processInfo.thermalState
    let thermalStateValue = thermalStateLabel(thermalState)
    let thermalStateStatus = thermalStatus(thermalState)
    let uptimeDays = ProcessInfo.processInfo.systemUptime / 86_400
    let sustainedCPU = sustainedCPUMetric(historySummary, now: now)

    let performanceMetrics = [
      metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpuPercent), cpuSeverity(instant.cpuPercent), "Instant CPU load sampled over a short window from macOS CPU ticks.", "host_statistics CPU_LOAD_INFO", "Live / medium", "Watch sustained high CPU, not a single short spike.", now, dataMode: .live),
      metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "\(memoryUsedValue) GB of \(memoryTotalValue) GB physical memory is actively used or compressed.", "host_statistics64 VM_INFO64", "Live / medium", "Close heavy apps only if memory pressure or swap also stays high.", now, dataMode: .live),
      metric("RAM Used Now", memoryPercentValue, "%", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "This is an instant memory-use estimate from active, wired, and compressed pages.", "host_statistics64 VM_INFO64", "Live / medium", "Use this as a direction signal rather than an exact Activity Monitor duplicate.", now, dataMode: .live),
      metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Unavailable / high", "Use wattage later only if Corewise can obtain it through a safe, user-approved path.", now, dataMode: .unavailable),
      metric("Memory Pressure", "Moderate", "", .warning, 58, "The Mac has enough memory, but swap and large apps suggest pressure during heavier work.", "Activity sample", "Mock / medium", "Close unused simulators or browser windows before heavy builds.", now),
      metric("Swap Used", "3.1", "GB", .warning, 56, "Swap means macOS is using disk as overflow memory; occasional use is normal, sustained high use can feel slow.", "VM statistics", "Mock / medium", "Watch whether this stays high after closing heavy apps.", now),
      metric("Uptime", number(uptimeDays), "days", .info, min(max(Int(uptimeDays.rounded()), 0), 100), "Current system uptime reported by ProcessInfo.", "ProcessInfo.systemUptime", "Live / high", "Restart only if performance symptoms persist.", now, dataMode: .live),
      sustainedCPU,
      metric("WindowServer Impact", "Elevated", "", .info, 38, "WindowServer usage is higher with external displays, screen recording, or many animated windows.", "Process sample", "Mock / medium", "Close unneeded display-heavy apps if UI feels sluggish.", now)
    ]

    let cpuProcesses = instant.topCPUProcesses
    let memoryProcesses = instant.topMemoryProcesses

    let thermalMetrics = [
      metric("Thermal State", thermalStateValue, "", thermalStateStatus, thermalSeverity(thermalState), "macOS high-level thermal pressure state.", "ProcessInfo.thermalState", "Live / high", "No action needed unless macOS reports elevated thermal pressure.", now, dataMode: .live),
      metric("Low Power Mode", "Planned", "", .info, 0, "Low Power Mode is not collected in this build.", "Power settings", "Planned / medium", "Use macOS settings when battery life matters more than peak speed.", now, dataMode: .planned),
      metric("Likely Contributors", "Planned", "", .info, 0, "Corewise needs sustained live process history before attributing heat to apps.", "Process correlation", "Planned / low", "Use live CPU rows as context, not a thermal diagnosis.", now, dataMode: .planned)
    ]

    let issueMetrics = [
      metric("Diagnostic Access", "Limited", "", .info, 20, "Corewise can explain crash patterns only from data macOS allows it to read.", "Permission state", "Unavailable / medium", "Grant access only if you want deeper diagnostics later.", now, dataMode: .unavailable),
      metric("Crashes Last 7 Days", "6", "crashes", .warning, 52, "One app appears to be failing repeatedly this week.", "Diagnostic reports", "Mock / medium", "Update or reinstall the repeated-crash app first.", now),
      metric("Crashes Last 30 Days", "14", "crashes", .warning, 46, "Crash volume is noticeable but not system-wide critical.", "Diagnostic reports", "Mock / medium", "Look for repeated bundle IDs rather than one-off crashes.", now),
      metric("Repeated Crash Flag", "Yes", "", .warning, 60, "At least one app has multiple recent crashes.", "Corewise score", "Mock / medium", "Focus on the repeated app before broad troubleshooting.", now)
    ]

    let crashes = [
      crash("ExampleApp", "com.example.ExampleApp", "3.4.1", 3, 7, daysAgo(1), true, "Limited", .warning, 60, "This app has repeated crashes and is the clearest issue.", "Diagnostic reports", "Mock / medium", "Update the app, then relaunch and watch whether crashes stop."),
      crash("PhotoTool", "com.vendor.PhotoTool", "9.2", 2, 4, daysAgo(3), false, "Limited", .info, 32, "Crashes are present but not yet clearly repeated.", "Diagnostic reports", "Mock / medium", "Check for an update if you rely on it."),
      crash("HelperService", "com.vendor.HelperService", "1.8", 1, 3, daysAgo(6), false, "Limited", .info, 28, "Background helper crashes can come from stale vendor services.", "Diagnostic reports", "Mock / low", "Use the vendor app or uninstaller rather than deleting helpers.")
    ]
    let crashesByApp = crashes.map {
      ChartDatum(title: $0.appName, value: Double($0.crashesLast30Days), unit: "crashes", status: $0.status, detail: $0.bundleID)
    }
    let scoreConfidence = ScoreConfidenceCalculator.metric(
      modes: coverageModes(
        battery: batteryHealth,
        storage: storageHealth,
        performanceMetrics: performanceMetrics,
        cpuProcesses: cpuProcesses,
        memoryProcesses: memoryProcesses,
        startup: startupHealth,
        thermalMetrics: thermalMetrics,
        issueMetrics: issueMetrics,
        crashes: crashes,
        crashCharts: crashesByApp
      ),
      now: now
    )

    return HealthSnapshot(
      generatedAt: now,
      healthScore: 74,
      overallStatus: .needsAttention,
      overviewMetrics: [
        metric("Health Score", "74", "/100", .warning, 42, "The current score is still a placeholder; trust section-level live badges more than the global score.", "Corewise scoring model", "Mock / medium", "Use live section values for decisions until scoring is rebuilt.", now),
        metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpuPercent), cpuSeverity(instant.cpuPercent), "Live CPU usage sampled from macOS CPU ticks.", "host_statistics CPU_LOAD_INFO", "Live / medium", "Refresh or wait a few seconds to see whether this is sustained.", now, dataMode: .live),
        metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "\(memoryPercentValue)% of physical memory is estimated as active, wired, or compressed.", "host_statistics64 VM_INFO64", "Live / medium", "Check memory pressure before blaming a single app.", now, dataMode: .live),
        metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Unavailable / high", "Do not show unsupported or elevated-tool wattage readings in the MVP.", now, dataMode: .unavailable),
        metric("Main Attention Area", "Storage", "", .warning, 58, "Available space is the strongest current signal, but detailed folder scans are not automatic.", "Corewise scoring model", "Mock / medium", "Review storage manually; Corewise will not inspect personal folders without an explicit flow.", now),
        scoreConfidence,
        metric("Data Mode", "Mock", "", .info, 0, "This build uses realistic mock data until safe collectors are implemented.", "App build", "High", "Treat values as UI/product scaffolding, not real device diagnostics.", now)
      ],
      battery: batteryHealth,
      storage: storageHealth,
      performance: PerformanceHealth(
        summary: performanceMetrics[0],
        metrics: performanceMetrics,
        cpuProcesses: cpuProcesses,
        memoryProcesses: memoryProcesses,
        findings: performanceFindings(historySummary, cpuProcesses: cpuProcesses),
        actions: [
          SafeAction(title: "Pause unused development services", body: "Stop containers and simulators you are not actively using.", systemImage: "pause.circle", status: .info),
          SafeAction(title: "Restart only when symptoms persist", body: "A restart can clear stuck work, but Corewise should present it as a manual troubleshooting step.", systemImage: "power", status: .info)
        ],
        sourceNote: "Mixed data. CPU, RAM, process rankings, uptime, and sustained CPU history are live. Memory pressure, swap, and WindowServer interpretation remain mock until safe sources are added."
      ),
      startup: startupHealth,
      thermal: ThermalHealth(
        summary: thermalMetrics[0],
        metrics: thermalMetrics,
        contributors: [
          DiagnosticFinding(title: "Thermal state is \(thermalStateValue.lowercased())", detail: "The safe public signal is read from ProcessInfo.", status: thermalStateStatus, severityScore: thermalSeverity(thermalState)),
          DiagnosticFinding(title: "Low-level readings are intentionally absent", detail: "Corewise should not rely on unsupported hardware APIs for a consumer MVP.", status: .info, severityScore: 12),
          DiagnosticFinding(title: "CPU-heavy tools can still create heat", detail: "Xcode, builds, and background developer tasks are likely contributors if fans are audible.", status: .warning, severityScore: 44)
        ],
        actions: [
          SafeAction(title: "Trust macOS thermal pressure", body: "Use ProcessInfo thermal state for safe high-level thermal status.", systemImage: "thermometer.medium", status: .good),
          SafeAction(title: "Reduce sustained load", body: "Pause long builds or containers if the Mac feels hot for a long period.", systemImage: "speedometer", status: .info)
        ],
        sourceNote: "Mixed data. Thermal state is live from ProcessInfo.thermalState; low power mode and likely contributors remain planned. Corewise avoids unsupported low-level hardware readings."
      ),
      appIssues: AppIssuesHealth(
        summary: issueMetrics[1],
        metrics: issueMetrics,
        crashes: crashes,
        crashesByApp: crashesByApp,
        findings: [
          DiagnosticFinding(title: "One repeated-crash app stands out", detail: "ExampleApp accounts for half of the recent mock crash volume.", status: .warning, severityScore: 60),
          DiagnosticFinding(title: "Crash data may be permission-limited", detail: "Corewise should disclose when diagnostic reports are incomplete or unavailable.", status: .info, severityScore: 20)
        ],
        actions: [
          SafeAction(title: "Update the repeated-crash app", body: "Start with the app that repeats, not broad system cleanup.", systemImage: "arrow.down.app", status: .info),
          SafeAction(title: "Do not erase logs automatically", body: "Diagnostic data should be read to explain patterns, not cleaned away.", systemImage: "doc.text.magnifyingglass", status: .good)
        ],
        sourceNote: "Mock data. Real crash diagnostics should read only permitted diagnostic reports and clearly show permission state."
      ),
      suggestions: [
        Suggestion(title: "Keep storage review manual", body: "Corewise now reads startup volume capacity without opening personal folders automatically.", severity: .good),
        Suggestion(title: "Watch repeated CPU load", body: "Process history is more useful than a single spike once a few refreshes have been collected.", severity: .info),
        Suggestion(title: "Treat values as diagnostic context", body: "Corewise explains what is likely happening and leaves all cleanup decisions to you.", severity: .good)
      ]
    )
  }

  private func sustainedCPUMetric(_ summary: PerformanceHistorySummary, now: Date) -> DiagnosticMetric {
    guard summary.hasEnoughSamples else {
      return metric(
        "Sustained High CPU",
        "Collecting",
        "",
        .info,
        0,
        "Corewise needs at least \(summary.requiredSampleCount) recent samples before it can call CPU usage sustained.",
        "Local in-memory performance history",
        "Unavailable / medium",
        "Wait a few refreshes before interpreting sustained CPU.",
        now,
        dataMode: .unavailable
      )
    }

    if summary.hasSustainedHighCPU {
      return metric(
        "Sustained High CPU",
        "Yes",
        "",
        .warning,
        58,
        "\(summary.repeatedHighCPUProcesses.joined(separator: ", ")) stayed above \(number(summary.sustainedCPUThreshold))% CPU across recent samples.",
        "Local in-memory performance history",
        "Live / medium",
        "Check whether the repeated process is doing expected work before quitting anything.",
        now,
        dataMode: .live
      )
    }

    return metric(
      "Sustained High CPU",
      "No",
      "",
      .good,
      8,
      "No process has stayed above \(number(summary.sustainedCPUThreshold))% CPU across enough recent samples.",
      "Local in-memory performance history",
      "Live / medium",
      "No action needed for sustained CPU right now.",
      now,
      dataMode: .live
    )
  }

  private func performanceFindings(_ summary: PerformanceHistorySummary, cpuProcesses: [ProcessSample]) -> [DiagnosticFinding] {
    var findings = [
      DiagnosticFinding(title: "Live process ranking is available", detail: "Top CPU and memory charts are based on short per-process samples when macOS returns process data.", status: .info, severityScore: 24)
    ]

    if !summary.hasEnoughSamples {
      findings.append(
        DiagnosticFinding(
          title: "Sustained CPU history is collecting",
          detail: "\(summary.recentSampleCount) of \(summary.requiredSampleCount) recent samples are available.",
          status: .info,
          severityScore: 0
        )
      )
    } else if summary.hasSustainedHighCPU {
      findings.append(
        DiagnosticFinding(
          title: "Repeated CPU load detected",
          detail: "\(summary.repeatedHighCPUProcesses.joined(separator: ", ")) crossed the sustained CPU threshold in recent samples.",
          status: .warning,
          severityScore: 58
        )
      )
    } else {
      findings.append(
        DiagnosticFinding(
          title: "No repeated CPU load yet",
          detail: cpuProcesses.isEmpty ? "No live process samples are available right now." : "Current spikes have not repeated enough to count as sustained.",
          status: .good,
          severityScore: 8
        )
      )
    }

    return findings
  }

  private func coverageModes(
    battery: BatteryHealth,
    storage: StorageHealth,
    performanceMetrics: [DiagnosticMetric],
    cpuProcesses: [ProcessSample],
    memoryProcesses: [ProcessSample],
    startup: StartupHealth,
    thermalMetrics: [DiagnosticMetric],
    issueMetrics: [DiagnosticMetric],
    crashes: [CrashIssue],
    crashCharts: [ChartDatum]
  ) -> [DataMode] {
    battery.metrics.map(\.dataMode)
      + storage.metrics.map(\.dataMode)
      + storage.breakdown.map(\.dataMode)
      + storage.largeFolders.map(\.dataMode)
      + storage.largeFiles.map(\.dataMode)
      + storage.developerCaches.map(\.dataMode)
      + storage.browserCaches.map(\.dataMode)
      + storage.spaceOffenders.map(\.dataMode)
      + performanceMetrics.map(\.dataMode)
      + cpuProcesses.map(\.dataMode)
      + memoryProcesses.map(\.dataMode)
      + startup.metrics.map(\.dataMode)
      + startup.loginItems.map(\.dataMode)
      + startup.launchAgents.map(\.dataMode)
      + startup.launchDaemons.map(\.dataMode)
      + startup.backgroundItems.map(\.dataMode)
      + startup.privilegedHelpers.map(\.dataMode)
      + thermalMetrics.map(\.dataMode)
      + issueMetrics.map(\.dataMode)
      + crashes.map(\.dataMode)
      + crashCharts.map(\.dataMode)
  }

  private func metric(
    _ title: String,
    _ value: String,
    _ unit: String,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date,
    dataMode: DataMode = .mock
  ) -> DiagnosticMetric {
    DiagnosticMetric(
      title: title,
      value: value,
      unit: unit,
      dataMode: dataMode,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func crash(
    _ appName: String,
    _ bundleID: String,
    _ appVersion: String,
    _ crashesLast7Days: Int,
    _ crashesLast30Days: Int,
    _ lastCrashDate: Date,
    _ repeatedCrash: Bool,
    _ diagnosticPermissionState: String,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    dataMode: DataMode = .mock
  ) -> CrashIssue {
    CrashIssue(
      appName: appName,
      bundleID: bundleID,
      appVersion: appVersion,
      crashesLast7Days: crashesLast7Days,
      crashesLast30Days: crashesLast30Days,
      lastCrashDate: lastCrashDate,
      repeatedCrash: repeatedCrash,
      diagnosticPermissionState: diagnosticPermissionState,
      dataMode: dataMode,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction
    )
  }

  private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }

  private func cpuStatus(_ percent: Double?) -> FindingSeverity {
    guard let percent else {
      return .info
    }
    if percent >= 90 {
      return .critical
    }
    if percent >= 65 {
      return .warning
    }
    if percent >= 35 {
      return .info
    }
    return .good
  }

  private func cpuSeverity(_ percent: Double?) -> Int {
    guard let percent else {
      return 0
    }
    return min(max(Int(percent.rounded()), 0), 100)
  }

  private func memoryStatus(_ percent: Double) -> FindingSeverity {
    if percent >= 90 {
      return .critical
    }
    if percent >= 75 {
      return .warning
    }
    if percent >= 55 {
      return .info
    }
    return .good
  }

  private func memorySeverity(_ percent: Double) -> Int {
    min(max(Int(percent.rounded()), 0), 100)
  }

  private func thermalStateLabel(_ state: ProcessInfo.ThermalState) -> String {
    switch state {
    case .nominal:
      return "Nominal"
    case .fair:
      return "Fair"
    case .serious:
      return "Serious"
    case .critical:
      return "Critical"
    @unknown default:
      return "Unknown"
    }
  }

  private func thermalStatus(_ state: ProcessInfo.ThermalState) -> FindingSeverity {
    switch state {
    case .nominal:
      return .good
    case .fair:
      return .info
    case .serious:
      return .warning
    case .critical:
      return .critical
    @unknown default:
      return .info
    }
  }

  private func thermalSeverity(_ state: ProcessInfo.ThermalState) -> Int {
    switch state {
    case .nominal:
      return 8
    case .fair:
      return 28
    case .serious:
      return 66
    case .critical:
      return 92
    @unknown default:
      return 20
    }
  }
}
