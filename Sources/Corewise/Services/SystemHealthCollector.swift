import Foundation

struct SystemHealthCollector: SystemHealthCollecting {
  private let performanceHistory = PerformanceHistoryTracker()

  func currentSnapshot() async throws -> HealthSnapshot {
    let now = Date()
    let instant = await SystemMetricsSampler.sample()
    let historySummary = performanceHistory.record(instant: instant, now: now)
    let cpuValue = instant.cpu.totalPercent.map { number($0) } ?? "N/A"
    let memoryUsedValue = number(instant.memory.usedGB)
    let memoryTotalValue = number(instant.memory.physicalGB)
    let memoryPercentValue = number(instant.memory.usedPercent)
    let batteryHealth = BatteryDiagnosticsCollector().currentBattery(now: now)
    let storageHealth = StorageDiagnosticsCollector().currentStorage(now: now)
    let startupHealth = StartupDiagnosticsCollector().currentStartup(now: now)
    let appIssuesHealth = CrashReportDiagnosticsCollector().unavailableAppIssues(now: now)
    let thermalState = ProcessInfo.processInfo.thermalState
    let thermalStateValue = thermalStateLabel(thermalState)
    let thermalStateStatus = thermalStatus(thermalState)
    let uptimeDays = ProcessInfo.processInfo.systemUptime / 86_400
    let sustainedCPU = sustainedCPUMetric(historySummary, now: now)
    let processes = instant.processes
    let appGroups = instant.appGroups
    let cpuProcesses = processes.sorted { $0.cpuPercent > $1.cpuPercent }

    let performanceMetrics = [
      metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpu.totalPercent), cpuSeverity(instant.cpu.totalPercent), "Live CPU load sampled over a 1 second window from macOS CPU ticks.", instant.cpu.source, instant.cpu.confidence, "Watch sustained high CPU, not a single short spike.", now, dataMode: instant.cpu.dataMode),
      metric("CPU User", instant.cpu.userPercent.map { number($0) } ?? "Unavailable", "%", .info, cpuSeverity(instant.cpu.userPercent), "User CPU share from the same live CPU tick window.", instant.cpu.source, instant.cpu.confidence, "Use with system CPU to understand where load comes from.", now, dataMode: instant.cpu.dataMode),
      metric("CPU System", instant.cpu.systemPercent.map { number($0) } ?? "Unavailable", "%", .info, cpuSeverity(instant.cpu.systemPercent), "System CPU share from the same live CPU tick window.", instant.cpu.source, instant.cpu.confidence, "High system CPU can be normal during indexing, I/O, or monitoring.", now, dataMode: instant.cpu.dataMode),
      metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memory.usedPercent), memorySeverity(instant.memory.usedPercent), "\(memoryUsedValue) GB of \(memoryTotalValue) GB physical memory is app memory, wired memory, or compressed memory in Corewise's public VM view.", instant.memory.source, instant.memory.confidence, "Use process memory, wired, compressed, cached files, and swap together before blaming an app.", now, dataMode: instant.memory.dataMode),
      metric("App Memory", number(instant.memory.appMemoryGB), "GB", .info, 0, "Anonymous/internal pages from macOS VM statistics; this is the closest public component to Activity Monitor's App Memory.", instant.memory.source, instant.memory.confidence, "Use it as a system component, not a per-app blame signal.", now, dataMode: instant.memory.dataMode),
      metric("Cached Files", number(instant.memory.cachedFilesGB), "GB", .info, 0, "File-backed pages from macOS VM statistics. macOS can reclaim much of this when needed.", instant.memory.source, instant.memory.confidence, "Cached files are normal and are not a cleanup target.", now, dataMode: instant.memory.dataMode),
      metric("Wired Memory", number(instant.memory.wiredGB), "GB", .info, 0, "Wired memory reported by macOS VM statistics.", instant.memory.source, instant.memory.confidence, "Wired memory is managed by macOS and is not a cleanup target.", now, dataMode: instant.memory.dataMode),
      metric("Compressed Memory", number(instant.memory.compressedGB), "GB", .info, 0, "Compressed memory reported by macOS VM statistics.", instant.memory.source, instant.memory.confidence, "Compression is normal; interpret it together with swap and symptoms.", now, dataMode: instant.memory.dataMode),
      metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Unavailable / high", "Use wattage later only if Corewise can obtain it through a safe, user-approved path.", now, dataMode: .unavailable),
      SystemMetricsSampler.memoryPressureEstimate(memoryPercent: instant.memory.usedPercent, swapUsedGB: instant.memory.swapUsedGB),
      swapMetric(instant.memory.swapUsedGB, now: now),
      metric("Uptime", number(uptimeDays), "days", .info, min(max(Int(uptimeDays.rounded()), 0), 100), "Current system uptime reported by ProcessInfo.", "ProcessInfo.systemUptime", "Live / high", "Restart only if performance symptoms persist.", now, dataMode: .live),
      sustainedCPU,
      metric("WindowServer Impact", "Planned", "", .info, 0, "WindowServer interpretation needs careful live process context before Corewise can present it.", "Process interpretation", "Planned / low", "Use live CPU rows as context, not a WindowServer diagnosis.", now, dataMode: .planned)
    ]

    let thermalMetrics = [
      metric("Thermal State", thermalStateValue, "", thermalStateStatus, thermalSeverity(thermalState), "macOS high-level thermal pressure state.", "ProcessInfo.thermalState", "Live / high", "No action needed unless macOS reports elevated thermal pressure.", now, dataMode: .live),
      metric("Low Power Mode", "Planned", "", .info, 0, "Low Power Mode is not collected in this build.", "Power settings", "Planned / medium", "Use macOS settings when battery life matters more than peak speed.", now, dataMode: .planned),
      metric("Likely Contributors", "Planned", "", .info, 0, "Corewise needs sustained live process history before attributing heat to apps.", "Process correlation", "Planned / low", "Use live CPU rows as context, not a thermal diagnosis.", now, dataMode: .planned)
    ]

    let issueMetrics = appIssuesHealth.metrics
    let crashes = appIssuesHealth.crashes
    let crashesByApp = appIssuesHealth.crashesByApp
    let dataAccess = dataAccessCapabilities()
    let coverageSummary = DataCoverageSummary(
      modes: coverageModes(
        dataAccess: dataAccess,
        battery: batteryHealth,
        storage: storageHealth,
        performanceMetrics: performanceMetrics,
        processes: processes,
        appGroups: appGroups,
        startup: startupHealth,
        thermalMetrics: thermalMetrics,
        issueMetrics: issueMetrics,
        crashes: crashes,
        crashCharts: crashesByApp
      )
    )
    let scoreConfidence = ScoreConfidenceCalculator.metric(summary: coverageSummary, now: now)

    return HealthSnapshot(
      generatedAt: now,
      healthScore: 0,
      overallStatus: .notScored,
      coverageSummary: coverageSummary,
      overviewMetrics: [
        metric("Global Score", "Planned", "", .info, 0, "Corewise will calculate a global score only after enough live signals are stable.", "Corewise scoring model", "Planned / high", "Use section-level Live badges instead of a global score for now.", now, dataMode: .planned),
        metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpu.totalPercent), cpuSeverity(instant.cpu.totalPercent), "Live CPU usage sampled from macOS CPU ticks.", instant.cpu.source, instant.cpu.confidence, "Refresh or wait a few seconds to see whether this is sustained.", now, dataMode: instant.cpu.dataMode),
        metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memory.usedPercent), memorySeverity(instant.memory.usedPercent), "\(memoryPercentValue)% of physical memory is app memory, wired memory, or compressed memory in Corewise's VM view.", instant.memory.source, instant.memory.confidence, "Check process memory and swap before blaming a single app.", now, dataMode: instant.memory.dataMode),
        metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Unavailable / high", "Do not show unsupported or elevated-tool wattage readings in the MVP.", now, dataMode: .unavailable),
        metric("Main Attention Area", "Unavailable", "", .info, 0, "Corewise has not implemented real cross-section prioritization yet.", "Corewise scoring model", "Unavailable / high", "Review section-level live data instead of a generated priority.", now, dataMode: .unavailable),
        scoreConfidence,
        metric("Synthetic Runtime Data", "None", "", .good, 0, "Corewise runtime values are now live, planned, unavailable, or avoided; synthetic diagnostic rows are not used.", "App build", "Live / high", "Treat missing areas as intentionally not implemented, not hidden diagnostics.", now, dataMode: .live)
      ],
      dataAccess: dataAccess,
      battery: batteryHealth,
      storage: storageHealth,
      performance: PerformanceHealth(
        summary: performanceMetrics[0],
        cpu: instant.cpu,
        memory: instant.memory,
        metrics: performanceMetrics,
        processes: cpuProcesses,
        appGroups: appGroups,
        findings: performanceFindings(historySummary, processes: processes),
        actions: [
          SafeAction(title: "Pause unused development services", body: "Stop containers and simulators you are not actively using.", systemImage: "pause.circle", status: .info),
          SafeAction(title: "Restart only when symptoms persist", body: "A restart can clear stuck work, but Corewise should present it as a manual troubleshooting step.", systemImage: "power", status: .info)
        ],
        sourceNote: "Live data. CPU split, process rows, thread count, resident memory, physical footprint when macOS returns it, observed memory, system VM memory, uptime, swap, and sustained CPU history are read locally. Observed memory is the larger public value between footprint and resident memory to avoid under-reporting. Memory pressure and WindowServer interpretation remain unavailable/planned until a reliable public source is selected."
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
      appIssues: appIssuesHealth,
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

  private func swapMetric(_ swapUsedGB: Double?, now: Date) -> DiagnosticMetric {
    guard let swapUsedGB else {
      return metric(
        "Swap Used",
        "Unavailable",
        "GB",
        .info,
        0,
        "Swap usage was not returned by the safe VM query on this Mac.",
        "sysctl vm.swapusage",
        "Unavailable / medium",
        "Do not infer swap pressure from resident memory alone.",
        now,
        dataMode: .unavailable
      )
    }

    return metric(
      "Swap Used",
      number(swapUsedGB),
      "GB",
      swapUsedGB >= 8 ? .warning : (swapUsedGB >= 2 ? .info : .good),
      min(Int((swapUsedGB * 10).rounded()), 100),
      "Live swap usage reported by macOS through a safe VM query.",
      "sysctl vm.swapusage",
      "Live / medium",
      "Interpret swap together with memory pressure and symptoms.",
      now,
      dataMode: .live
    )
  }

  private func dataAccessCapabilities() -> [DataAccessCapability] {
    [
      DataAccessCapability(title: "CPU, RAM, and processes", dataMode: .live, source: "Mach and libproc", reason: "Read automatically from public local process and VM signals.", actionLabel: nil),
      DataAccessCapability(title: "Startup volume capacity", dataMode: .live, source: "FileManager volume values", reason: "Read automatically without opening personal folders.", actionLabel: nil),
      DataAccessCapability(title: "Battery basics", dataMode: .live, source: "IOKit power sources", reason: "Charge, power source, and charging state are read when macOS exposes an internal battery.", actionLabel: nil),
      DataAccessCapability(title: "Thermal state", dataMode: .live, source: "ProcessInfo.thermalState", reason: "Safe high-level pressure signal, not a low-level hardware reading.", actionLabel: nil),
      DataAccessCapability(title: "Launch plist inventory", dataMode: .live, source: "LaunchAgents and LaunchDaemons", reason: "Reads accessible plist metadata only.", actionLabel: nil),
      DataAccessCapability(title: "Storage folder details", dataMode: .unavailable, source: "User-selected folder", reason: "Corewise waits for you to choose a folder before scanning personal files.", actionLabel: "Choose Folder"),
      DataAccessCapability(title: "Crash report patterns", dataMode: .unavailable, source: "User-selected report folder", reason: "Crash reports may contain sensitive metadata, so Corewise reads them only after manual selection.", actionLabel: "Choose Reports"),
      DataAccessCapability(title: "Detailed battery health", dataMode: .planned, source: "IOKit battery registry", reason: "Cycle count, condition, and capacity are used only when safe keys are present.", actionLabel: nil),
      DataAccessCapability(title: "System watts and low-level readings", dataMode: .avoided, source: "Unsupported or elevated sources", reason: "Corewise avoids private hardware paths, elevated tools, and unsupported claims.", actionLabel: nil)
    ]
  }

  private func performanceFindings(_ summary: PerformanceHistorySummary, processes: [ProcessObservation]) -> [DiagnosticFinding] {
    var findings = [
      DiagnosticFinding(title: "Live process table is available", detail: "Process rows include PID, user, thread count, CPU, observed memory, RSS, and footprint when macOS returns it.", status: .info, severityScore: 24)
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
          detail: processes.isEmpty ? "No live process samples are available right now." : "Current spikes have not repeated enough to count as sustained.",
          status: .good,
          severityScore: 8
        )
      )
    }

    if processes.contains(where: { $0.displayName.localizedCaseInsensitiveContains("Helper") }) {
      findings.append(
        DiagnosticFinding(
          title: "Helper processes are normal",
          detail: "Browsers and Electron apps often split work across renderer, service, and helper rows. Use the app owner shown under each row before blaming a single process.",
          status: .info,
          severityScore: 12
        )
      )
    }

    if processes.contains(where: { ($0.path ?? "").hasPrefix("/System/") || ($0.path ?? "").hasPrefix("/usr/") }) {
      findings.append(
        DiagnosticFinding(
          title: "System processes are labeled separately",
          detail: "Rows such as WindowServer, fileproviderd, Spotlight, and media services can be normal macOS work. Corewise shows them as context, not automatic issues.",
          status: .info,
          severityScore: 10
        )
      )
    }

    if processes.contains(where: { $0.processName == "Corewise" }) {
      findings.append(
        DiagnosticFinding(
          title: "Corewise is included in its own sample",
          detail: "This keeps the table honest when the app itself is spending CPU or memory during refresh.",
          status: .good,
          severityScore: 0
        )
      )
    }

    return findings
  }

  private func coverageModes(
    dataAccess: [DataAccessCapability],
    battery: BatteryHealth,
    storage: StorageHealth,
    performanceMetrics: [DiagnosticMetric],
    processes: [ProcessObservation],
    appGroups: [AppProcessGroup],
    startup: StartupHealth,
    thermalMetrics: [DiagnosticMetric],
    issueMetrics: [DiagnosticMetric],
    crashes: [CrashIssue],
    crashCharts: [ChartDatum]
  ) -> [DataMode] {
    let storageScanModes = [
      storage.largeFolders.first?.dataMode,
      storage.largeFiles.first?.dataMode,
      storage.developerCaches.first?.dataMode,
      storage.browserCaches.first?.dataMode,
      storage.spaceOffenders.first?.dataMode
    ].compactMap(\.self)
    let processTableMode: DataMode = processes.isEmpty ? .unavailable : .live
    let appGroupMode: DataMode = appGroups.isEmpty ? .unavailable : .live
    let startupInventoryMode: DataMode = startup.launchAgents.isEmpty && startup.launchDaemons.isEmpty ? .unavailable : .live
    let crashReportMode: DataMode = crashes.isEmpty && crashCharts.isEmpty ? .unavailable : .live

    // Coverage is a product-level summary. Count diagnostic signal families, not every table row.
    return dataAccess.map(\.dataMode)
      + battery.metrics.map(\.dataMode)
      + storage.metrics.map(\.dataMode)
      + storage.breakdown.map(\.dataMode)
      + storageScanModes
      + performanceMetrics.map(\.dataMode)
      + [processTableMode, appGroupMode]
      + startup.metrics.map(\.dataMode)
      + [startupInventoryMode]
      + thermalMetrics.map(\.dataMode)
      + issueMetrics.map(\.dataMode)
      + [crashReportMode]
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
