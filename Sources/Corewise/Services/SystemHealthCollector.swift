import Foundation

struct SystemHealthCollector: SystemHealthCollecting {
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
      metric("Memory Pressure", "Unavailable", "", .info, 0, "Memory pressure is not collected in this build through a safe implemented source.", "Memory pressure collector", "Unavailable / medium", "Use Activity Monitor if you need memory pressure before Corewise implements it.", now, dataMode: .unavailable),
      metric("Swap Used", "Planned", "GB", .info, 0, "Swap usage needs a safe implemented VM source before Corewise can display it.", "Swap collector", "Planned / medium", "Do not infer swap pressure from resident memory alone.", now, dataMode: .planned),
      metric("Uptime", number(uptimeDays), "days", .info, min(max(Int(uptimeDays.rounded()), 0), 100), "Current system uptime reported by ProcessInfo.", "ProcessInfo.systemUptime", "Live / high", "Restart only if performance symptoms persist.", now, dataMode: .live),
      sustainedCPU,
      metric("WindowServer Impact", "Planned", "", .info, 0, "WindowServer interpretation needs careful live process context before Corewise can present it.", "Process interpretation", "Planned / low", "Use live CPU rows as context, not a WindowServer diagnosis.", now, dataMode: .planned)
    ]

    let cpuProcesses = instant.topCPUProcesses
    let memoryProcesses = instant.topMemoryProcesses

    let thermalMetrics = [
      metric("Thermal State", thermalStateValue, "", thermalStateStatus, thermalSeverity(thermalState), "macOS high-level thermal pressure state.", "ProcessInfo.thermalState", "Live / high", "No action needed unless macOS reports elevated thermal pressure.", now, dataMode: .live),
      metric("Low Power Mode", "Planned", "", .info, 0, "Low Power Mode is not collected in this build.", "Power settings", "Planned / medium", "Use macOS settings when battery life matters more than peak speed.", now, dataMode: .planned),
      metric("Likely Contributors", "Planned", "", .info, 0, "Corewise needs sustained live process history before attributing heat to apps.", "Process correlation", "Planned / low", "Use live CPU rows as context, not a thermal diagnosis.", now, dataMode: .planned)
    ]

    let issueMetrics = [
      metric("Diagnostic Access", "Not Read", "", .info, 0, "Corewise does not read diagnostic reports in this build.", "Diagnostic report collector", "Unavailable / high", "Grant access only if a future explicit crash diagnostics flow asks for it.", now, dataMode: .unavailable),
      metric("Crashes Last 7 Days", "Unavailable", "crashes", .info, 0, "Crash counts are unavailable until Corewise implements permitted diagnostic report reading.", "Diagnostic report collector", "Unavailable / high", "Use Console or app update history for crash review until then.", now, dataMode: .unavailable),
      metric("Crashes Last 30 Days", "Unavailable", "crashes", .info, 0, "Crash counts are unavailable until Corewise implements permitted diagnostic report reading.", "Diagnostic report collector", "Unavailable / high", "Look for repeated crashes manually only if you are troubleshooting a specific app.", now, dataMode: .unavailable),
      metric("Repeated Crash Flag", "Planned", "", .info, 0, "Repeated crash detection needs real crash metadata before it can be trusted.", "Crash pattern collector", "Planned / medium", "Do not treat App Issues as diagnostic until this collector is implemented.", now, dataMode: .planned)
    ]

    let crashes: [CrashIssue] = []
    let crashesByApp: [ChartDatum] = []
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
      healthScore: 0,
      overallStatus: .notScored,
      overviewMetrics: [
        metric("Health Score", "Not Scored Yet", "", .info, 0, "Corewise does not calculate a global health score until enough section data is live.", "Corewise scoring model", "Planned / high", "Use section-level Live badges instead of a global score for now.", now, dataMode: .planned),
        metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpuPercent), cpuSeverity(instant.cpuPercent), "Live CPU usage sampled from macOS CPU ticks.", "host_statistics CPU_LOAD_INFO", "Live / medium", "Refresh or wait a few seconds to see whether this is sustained.", now, dataMode: .live),
        metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "\(memoryPercentValue)% of physical memory is estimated as active, wired, or compressed.", "host_statistics64 VM_INFO64", "Live / medium", "Check memory pressure before blaming a single app.", now, dataMode: .live),
        metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Unavailable / high", "Do not show unsupported or elevated-tool wattage readings in the MVP.", now, dataMode: .unavailable),
        metric("Main Attention Area", "Unavailable", "", .info, 0, "Corewise has not implemented real cross-section prioritization yet.", "Corewise scoring model", "Unavailable / high", "Review section-level live data instead of a generated priority.", now, dataMode: .unavailable),
        scoreConfidence,
        metric("Synthetic Runtime Data", "None", "", .good, 0, "Corewise runtime values are now live, planned, unavailable, or avoided; synthetic diagnostic rows are not used.", "App build", "Live / high", "Treat missing areas as intentionally not implemented, not hidden diagnostics.", now, dataMode: .live)
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
        sourceNote: "Mixed data. CPU, RAM, process rankings, uptime, and sustained CPU history are live. Memory pressure, swap, and WindowServer interpretation are unavailable or planned until safe sources are added."
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
        summary: issueMetrics[0],
        metrics: issueMetrics,
        crashes: crashes,
        crashesByApp: crashesByApp,
        findings: [
          DiagnosticFinding(title: "Diagnostic reports not read yet", detail: "Corewise does not show crash patterns until a permitted read-only diagnostic report collector exists.", status: .info, severityScore: 0),
          DiagnosticFinding(title: "No app crash rows are invented", detail: "This page stays empty rather than showing synthetic app names.", status: .good, severityScore: 0)
        ],
        actions: [
          SafeAction(title: "Use app updates first", body: "If you already know an app is crashing, update that app before broad troubleshooting.", systemImage: "arrow.down.app", status: .info),
          SafeAction(title: "Do not erase logs automatically", body: "Diagnostic data should be read to explain patterns, not cleaned away.", systemImage: "doc.text.magnifyingglass", status: .good)
        ],
        sourceNote: "Unavailable data. Corewise does not read diagnostic reports yet, so App Issues does not invent crash rows or counts."
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
    dataMode: DataMode = .unavailable
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
