import Foundation

struct DiagnosticReportBuilder {
  func markdown(for snapshot: HealthSnapshot) -> String {
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
    let storageScan = snapshot.storage.spaceOffenders.isEmpty
      ? "No user-selected folder scan in this snapshot."
      : snapshot.storage.spaceOffenders.prefix(5).map { "- \($0.title): \(number($0.value)) \($0.unit)" }.joined(separator: "\n")
    let startupRows = snapshot.startup.launchAgents.count + snapshot.startup.launchDaemons.count
    let crashSummary = snapshot.appIssues.crashes.isEmpty
      ? "No diagnostic reports selected in this snapshot."
      : snapshot.appIssues.crashes.prefix(5).map { "- \($0.appName): \($0.crashesLast7Days) in 7 days, \($0.crashesLast30Days) in 30 days" }.joined(separator: "\n")

    return """
    # Corewise Diagnostic Report

    Generated: \(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))
    Data policy: local read-only snapshot. No cleanup, upload, stack traces, or file contents.

    ## System Signals
    - CPU: \(percent(snapshot.performance.cpu.totalPercent)) total, \(percent(snapshot.performance.cpu.userPercent)) user, \(percent(snapshot.performance.cpu.systemPercent)) system, \(percent(snapshot.performance.cpu.idlePercent)) idle
    - Memory used: \(bytes(snapshot.performance.memory.usedBytes)) of \(bytes(snapshot.performance.memory.physicalBytes))
    - Swap used: \(snapshot.performance.memory.swapUsedBytes.map(bytes) ?? "Unavailable")
    - Storage free: \(number(snapshot.storage.availableGB)) GB of \(number(snapshot.storage.totalGB)) GB
    - Battery: \(displayValue(snapshot.battery.summary))
    - Thermal: \(displayValue(snapshot.thermal.summary))

    ## Top CPU Processes
    \(cpuProcesses.isEmpty ? "No readable process rows in this snapshot." : cpuProcesses)

    ## Top Memory Processes
    \(memoryProcesses.isEmpty ? "No readable process rows in this snapshot." : memoryProcesses)

    ## Storage Scan
    \(storageScan)

    ## Startup Inventory
    - Launch plist rows: \(startupRows)
    - Login items: \(snapshot.startup.loginItems.isEmpty ? "Unavailable" : "\(snapshot.startup.loginItems.count)")
    - Background items: \(snapshot.startup.backgroundItems.isEmpty ? "Planned" : "\(snapshot.startup.backgroundItems.count)")

    ## Crash Report Patterns
    \(crashSummary)

    ## Limits
    - Global health score is planned, not calculated.
    - Memory values use public macOS APIs and are not a private Activity Monitor clone.
    - Storage and crash details appear only after user-selected scans.
    """
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
