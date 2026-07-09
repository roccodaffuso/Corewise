import Foundation

struct DiagnosticReportBuilder {
  func summary(for snapshot: HealthSnapshot, options: DiagnosticReportOptions = .default) -> String {
    """
    Corewise Diagnostic Summary
    Generated: \(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))

    Notable findings
    \(notableFindings(snapshot).isEmpty ? "- No notable findings in the current snapshot." : notableFindings(snapshot))

    Manual next steps
    \(manualNextSteps(snapshot).isEmpty ? "- Review live sections manually. Corewise does not make automatic changes." : manualNextSteps(snapshot))

    Current live signals
    - CPU: \(percent(snapshot.performance.cpu.totalPercent)) total, \(percent(snapshot.performance.cpu.userPercent)) user, \(percent(snapshot.performance.cpu.systemPercent)) system
    - Memory: \(bytes(snapshot.performance.memory.usedBytes)) used of \(bytes(snapshot.performance.memory.physicalBytes)); swap \(swapInsightSummary(snapshot.performance.swapInsight))
    - Storage: \(number(snapshot.storage.availableGB)) GB free of \(number(snapshot.storage.totalGB)) GB
    - Battery: \(displayValue(snapshot.battery.summary))
    - Thermal: \(displayValue(snapshot.thermal.summary))
    - Startup plist rows: \(snapshot.startup.launchAgents.count + snapshot.startup.launchDaemons.count)
    - Storage scan: \(storageScanSummary(snapshot, options: options))
    - Crash reports: \(crashReportSummary(snapshot, options: options))

    Limits
    - Global score is planned, not calculated.
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
    - Global score is planned, not calculated.
    - Memory values use public macOS APIs and are not a private Activity Monitor clone.
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
      : "\(snapshot.storage.spaceOffenders.count) selected-scan items"
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

    return snapshot.storage.spaceOffenders.isEmpty
      ? "No user-selected folder scan in this snapshot."
      : snapshot.storage.spaceOffenders.prefix(5).map { "- \($0.title): \(number($0.value)) \($0.unit)" }.joined(separator: "\n")
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
}
