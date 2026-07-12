import Foundation

struct DiagnosticReportBuilder {
  func focusedCheckSummary(for result: FocusedCheckResult) -> String {
    let evidence = result.evidence.isEmpty
      ? "- No ranked evidence was available."
      : result.evidence.map { "- \($0.title): \($0.value). \($0.detail)" }.joined(separator: "\n")
    let aiWorkloads = result.aiWorkloads.isEmpty ? "" : """

      AI workloads
      \(result.aiWorkloads.map { "- \($0.name): \(bytes($0.peakMemoryBytes)) peak memory, \(percent($0.maximumCPUPercent)) peak CPU, \(bytes($0.peakRelatedMemoryBytes)) related local work" }.joined(separator: "\n"))
      """
    return redactHomeDirectory(
      """
      Corewise Focused Check
      Check: \(result.intent.title)
      Generated: \(result.generatedAt.formatted(date: .abbreviated, time: .shortened))
      Observed for: \(duration(result.observationEndedAt.timeIntervalSince(result.observationStartedAt)))

      Result
      - \(result.headline)
      - \(result.detail)

      Evidence
      \(evidence)
      \(aiWorkloads)

      Next step
      - \(result.primaryAction.title): \(result.primaryAction.detail)

      Coverage and limitations
      - \(result.coverage)
      - This local observation reports coincidence and supported signals, not proven causation.
      """
    )
  }

  func focusedCheckMarkdown(for result: FocusedCheckResult) -> String {
    let evidence = result.evidence.isEmpty
      ? "No ranked evidence was available."
      : result.evidence.map {
        "- **\($0.title)** — \($0.value)\n  - \($0.detail)\n  - Confidence: \($0.confidence.title); samples: \($0.sampleCount); source: \($0.source)"
      }.joined(separator: "\n")
    let aiWorkloads = result.aiWorkloads.isEmpty ? "" : """

      ## AI Workloads
      \(result.aiWorkloads.map { "- **\($0.name)** — peak memory \(bytes($0.peakMemoryBytes)); average / peak CPU \(percent($0.averageCPUPercent)) / \(percent($0.maximumCPUPercent)); related local work \(bytes($0.peakRelatedMemoryBytes)); maximum process count \($0.maximumProcessCount)" }.joined(separator: "\n"))
      """
    return redactHomeDirectory(
      """
      # Corewise Focused Check

      - Check: \(result.intent.title)
      - Generated: \(result.generatedAt.formatted(date: .abbreviated, time: .shortened))
      - Observed for: \(duration(result.observationEndedAt.timeIntervalSince(result.observationStartedAt)))
      - State: \(result.state.rawValue)

      ## Result
      \(result.headline)

      \(result.detail)

      ## Evidence
      \(evidence)
      \(aiWorkloads)

      ## Next Step
      **\(result.primaryAction.title)** — \(result.primaryAction.detail)

      ## Coverage and Limitations
      \(result.coverage)

      This local observation reports coincidence and supported signals, not proven causation. No raw file contents or crash stacks are included.
      """
    )
  }

  func summary(for snapshot: HealthSnapshot, options: DiagnosticReportOptions = .default) -> String {
    """
    Corewise Diagnostic Summary
    Generated: \(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))

    Current signal summary
    - \(snapshot.attentionSummary.headline)
    - \(snapshot.attentionSummary.detail)

    Notable findings
    \(notableFindings(snapshot).isEmpty ? "- No notable findings in the current snapshot." : notableFindings(snapshot))

    Manual next steps
    \(manualNextSteps(snapshot).isEmpty ? "- Review live sections manually. Corewise does not make automatic changes." : manualNextSteps(snapshot))

    Current live signals
    - CPU: \(percent(snapshot.performance.cpu.totalPercent)) total, \(percent(snapshot.performance.cpu.userPercent)) user, \(percent(snapshot.performance.cpu.systemPercent)) system
    - Memory: \(memoryContextSummary(snapshot.performance.memoryContext))
    - Swap: \(swapInsightSummary(snapshot.performance.swapInsight))
    - Storage: \(number(snapshot.storage.availableGB)) GB free of \(number(snapshot.storage.totalGB)) GB
    - Battery: \(displayValue(snapshot.battery.summary))
    - Thermal: \(displayValue(snapshot.thermal.summary))
    - Startup plist rows: \(snapshot.startup.launchAgents.count + snapshot.startup.launchDaemons.count)
    - Storage scan: \(storageScanSummary(snapshot, options: options))
    - Crash reports: \(crashReportSummary(snapshot, options: options))

    Limits
    - Corewise does not calculate a global health score.
    - Storage folder and crash report details require manual selection.
    - Swap insight shows system swap context and likely memory pressure contributors, not exact per-process swap ownership.
    - This report is local clipboard text only.
    """
  }

  func markdown(for snapshot: HealthSnapshot, options: DiagnosticReportOptions = .default) -> String {
    let cpuProcesses = snapshot.performance.processes
      .sorted { $0.cpuPercent > $1.cpuPercent }
      .prefix(5)
      .map { "- \($0.displayName): \(number($0.cpuPercent))% CPU, \(bytes($0.observedMemoryBytes)) memory, PID \($0.pid)" }
      .joined(separator: "\n")
    let memoryProcesses = snapshot.performance.processes
      .sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }
      .prefix(5)
      .map { "- \($0.displayName): \(bytes($0.observedMemoryBytes)) memory, \(number($0.cpuPercent))% CPU, PID \($0.pid)" }
      .joined(separator: "\n")
    let storageScan = storageScanMarkdown(snapshot, options: options)
    let startupRows = snapshot.startup.launchAgents.count + snapshot.startup.launchDaemons.count
    let crashSummary = crashSummaryMarkdown(snapshot, options: options)
    let swapInsight = swapInsightMarkdown(snapshot.performance.swapInsight)

    return """
    # Corewise Diagnostic Report

    Generated: \(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))
    Data policy: local read-only snapshot. No cleanup, upload, stack traces, or file contents.

    ## Summary
    - Signal summary: \(snapshot.attentionSummary.headline)
    - Interpretation: \(snapshot.attentionSummary.detail)
    - CPU: \(percent(snapshot.performance.cpu.totalPercent)) total, \(percent(snapshot.performance.cpu.userPercent)) user, \(percent(snapshot.performance.cpu.systemPercent)) system, \(percent(snapshot.performance.cpu.idlePercent)) idle
    - Memory used: \(bytes(snapshot.performance.memory.usedBytes)) of \(bytes(snapshot.performance.memory.physicalBytes))
    - Swap: \(swapInsightSummary(snapshot.performance.swapInsight))
    - Storage free: \(number(snapshot.storage.availableGB)) GB of \(number(snapshot.storage.totalGB)) GB
    - Battery: \(displayValue(snapshot.battery.summary))
    - Thermal: \(displayValue(snapshot.thermal.summary))
    - Startup plist rows: \(startupRows)
    - Crash report apps: \(snapshot.appIssues.crashes.count)

    ## Notable Findings
    \(notableFindings(snapshot).isEmpty ? "No notable findings in the current snapshot." : notableFindings(snapshot))

    ## Manual Next Steps
    \(manualNextSteps(snapshot).isEmpty ? "Review live sections manually. Corewise does not make automatic changes." : manualNextSteps(snapshot))

    ## Performance
    Source: \(snapshot.performance.summary.source)
    Confidence: \(snapshot.performance.summary.confidence)

    Top CPU processes:
    \(cpuProcesses.isEmpty ? "No readable process rows in this snapshot." : cpuProcesses)

    Top memory processes:
    \(memoryProcesses.isEmpty ? "No readable process rows in this snapshot." : memoryProcesses)

    ## Memory And Swap
    Source: \(snapshot.performance.memoryContext.source)
    Confidence: \(snapshot.performance.memoryContext.confidence)

    Memory context:
    \(memoryContextMarkdown(snapshot.performance.memoryContext))

    Swap insight:
    \(swapInsight)

    ## Storage
    Source: \(snapshot.storage.summary.source)
    Confidence: \(snapshot.storage.summary.confidence)

    Volume: \(number(snapshot.storage.availableGB)) GB free of \(number(snapshot.storage.totalGB)) GB.

    Selected scan:
    \(storageScan)

    ## Battery
    Source: \(snapshot.battery.summary.source)
    Confidence: \(snapshot.battery.summary.confidence)
    Summary: \(displayValue(snapshot.battery.summary))

    ## Thermal
    Source: \(snapshot.thermal.summary.source)
    Confidence: \(snapshot.thermal.summary.confidence)
    Summary: \(displayValue(snapshot.thermal.summary))

    ## Startup
    Source: \(snapshot.startup.summary.source)
    Confidence: \(snapshot.startup.summary.confidence)
    - Launch plist rows: \(startupRows)
    - Login items: \(snapshot.startup.loginItems.isEmpty ? "Unavailable" : "\(snapshot.startup.loginItems.count)")
    - Background items: \(snapshot.startup.backgroundItems.isEmpty ? "Planned" : "\(snapshot.startup.backgroundItems.count)")

    ## App Issues
    Source: \(snapshot.appIssues.summary.source)
    Confidence: \(snapshot.appIssues.summary.confidence)
    \(crashSummary)

    ## Limits
    - Corewise does not calculate a global health score.
    - Memory values use public macOS APIs and are not a private Activity Monitor clone.
    - Corewise memory context is derived from public VM and swap counters; it is not Activity Monitor's private memory-pressure graph.
    - macOS does not expose exact per-process swap ownership through public APIs.
    - Storage and crash details appear only after user-selected scans.
    """
  }

  private func notableFindings(_ snapshot: HealthSnapshot) -> String {
    let findings = snapshot.performance.findings
      + snapshot.storage.findings
      + snapshot.battery.findings
      + snapshot.thermal.contributors
      + snapshot.startup.findings
      + snapshot.appIssues.findings

    return findings
      .prefix(8)
      .map { "- \($0.title): \($0.detail)" }
      .joined(separator: "\n")
  }

  private func manualNextSteps(_ snapshot: HealthSnapshot) -> String {
    let actions = snapshot.performance.actions
      + snapshot.storage.actions
      + snapshot.battery.actions
      + snapshot.thermal.actions
      + snapshot.startup.actions
      + snapshot.appIssues.actions

    return actions
      .prefix(8)
      .map { "- \($0.title): \($0.body)" }
      .joined(separator: "\n")
  }

  private func storageScanSummary(_ snapshot: HealthSnapshot, options: DiagnosticReportOptions) -> String {
    guard options.includeStorageScan else {
      return "Excluded by Settings"
    }

    return snapshot.storage.spaceOffenders.isEmpty
      ? "No user-selected folder scan"
      : "\(snapshot.storage.spaceOffenders.count) selected-scan categories"
  }

  private func crashReportSummary(_ snapshot: HealthSnapshot, options: DiagnosticReportOptions) -> String {
    guard options.includeCrashSummary else {
      return "Excluded by Settings"
    }

    return snapshot.appIssues.crashes.isEmpty
      ? "No user-selected reports"
      : "\(snapshot.appIssues.crashes.count) apps with reports"
  }

  private func storageScanMarkdown(_ snapshot: HealthSnapshot, options: DiagnosticReportOptions) -> String {
    guard options.includeStorageScan else {
      return "Excluded by Settings."
    }

    if snapshot.storage.spaceOffenders.isEmpty {
      return "No user-selected folder scan in this snapshot."
    }

    return snapshot.storage.spaceOffenders.prefix(5)
      .map { "- \($0.title): \(number($0.value)) \($0.unit) classified in selected scope" }
      .joined(separator: "\n")
  }

  private func crashSummaryMarkdown(_ snapshot: HealthSnapshot, options: DiagnosticReportOptions) -> String {
    guard options.includeCrashSummary else {
      return "Excluded by Settings."
    }

    return snapshot.appIssues.crashes.isEmpty
      ? "No diagnostic reports selected in this snapshot."
      : snapshot.appIssues.crashes.prefix(5).map { "- \($0.appName): \($0.crashesLast7Days) in 7 days, \($0.crashesLast30Days) in 30 days" }.joined(separator: "\n")
  }

  private func swapInsightSummary(_ insight: SwapInsight) -> String {
    guard let reading = insight.reading else {
      return "Unavailable"
    }

    return "\(bytes(reading.usedBytes)) used of \(bytes(reading.totalBytes)); \(insight.trend.title.lowercased())"
  }

  private func memoryContextSummary(_ context: MemoryPressureContext) -> String {
    "\(context.title); \(bytes(context.usedBytes)) used of \(bytes(context.physicalBytes)); swap \(context.swapUsedBytes.map(bytes) ?? "Unavailable")"
  }

  private func memoryContextMarkdown(_ context: MemoryPressureContext) -> String {
    """
    - State: \(context.title)
    - Detail: \(context.detail)
    - Physical memory: \(bytes(context.physicalBytes))
    - Used memory: \(bytes(context.usedBytes)) (\(number(context.memoryUsedPercent))%)
    - App memory: \(bytes(context.appMemoryBytes))
    - Cached files: \(bytes(context.cachedFilesBytes))
    - Wired memory: \(bytes(context.wiredBytes))
    - Compressed memory: \(bytes(context.compressedBytes))
    - Swap used: \(context.swapUsedBytes.map(bytes) ?? "Unavailable")
    - Swap trend: \(context.swapTrend.title)
    - Limit: Corewise derives this from public VM and swap counters; it is not Activity Monitor's private memory-pressure graph.
    """
  }

  private func swapInsightMarkdown(_ insight: SwapInsight) -> String {
    guard let reading = insight.reading else {
      return "Unavailable in this snapshot."
    }

    let contributors = insight.contributors.isEmpty
      ? "No likely contributors ranked yet."
      : insight.contributors.prefix(5).map {
        "- \($0.processName): \(bytes($0.observedMemoryBytes)) observed memory, \(bytes($0.residentMemoryBytes)) RSS, \($0.pageIns) page-ins"
      }.joined(separator: "\n")

    return """
    - Used: \(bytes(reading.usedBytes))
    - Total: \(bytes(reading.totalBytes))
    - Available: \(bytes(reading.availableBytes))
    - Trend: \(insight.trend.title)
    - Swap in rate: \(rate(insight.swapInRateBytesPerSecond))
    - Swap out rate: \(rate(insight.swapOutRateBytesPerSecond))
    - Swapped VM pages: \(bytes(reading.swappedBytes))
    - Encrypted: \(reading.isEncrypted ? "Yes" : "No")
    - Limit: macOS does not expose exact per-process swap ownership through public APIs. Contributors are likely memory pressure contributors based on live memory, page-ins, and growth.

    Likely contributors:
    \(contributors)
    """
  }

  private func rate(_ bytesPerSecond: Double?) -> String {
    guard let bytesPerSecond else {
      return "Unavailable"
    }
    return "\(bytes(UInt64(max(0, bytesPerSecond * 60))))/min"
  }

  private func displayValue(_ metric: DiagnosticMetric) -> String {
    metric.unit.isEmpty ? metric.value : "\(metric.value) \(metric.unit)"
  }

  private func percent(_ value: Double?) -> String {
    guard let value else {
      return "Unavailable"
    }
    return "\(number(value))%"
  }

  private func bytes(_ value: UInt64) -> String {
    let gb = Double(value) / SystemMetricsSampler.bytesPerGB
    if gb >= 1 {
      return "\(number(gb)) GB"
    }

    let mb = Double(value) / (1024.0 * 1024.0)
    return "\(number(mb)) MB"
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }

  private func duration(_ interval: TimeInterval) -> String {
    let seconds = max(Int(interval.rounded()), 0)
    return seconds >= 60 ? "\(seconds / 60)m \(seconds % 60)s" : "\(seconds)s"
  }

  private func redactHomeDirectory(_ text: String) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    guard !home.isEmpty else { return text }
    return text.replacingOccurrences(of: home, with: "~")
  }
}
