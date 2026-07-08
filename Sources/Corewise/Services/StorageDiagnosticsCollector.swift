import Foundation

struct StorageDiagnosticsCollector {
  func currentStorage(now: Date) -> StorageHealth {
    let volume = volumeStats()
    let availablePercent = volume.totalGB > 0 ? volume.availableGB / volume.totalGB * 100 : 0
    let storageStatus = statusForAvailablePercent(availablePercent)
    let storageSeverity = severityForAvailablePercent(availablePercent)
    let totalValue = number(volume.totalGB)
    let availableValue = number(volume.availableGB)
    let usedValue = number(volume.usedGB)
    let percentValue = number(availablePercent)

    let metrics = [
      metric("Total Storage", totalValue, "GB", .live, .info, 0, "Total capacity reported by the startup volume.", "FileManager volume resource values", "Live / high", "No action needed.", now),
      metric("Available", availableValue, "GB", .live, storageStatus, storageSeverity, "Free space currently available on the startup volume.", "FileManager volume resource values", "Live / high", "Keep enough room for updates, builds, and temporary files.", now),
      metric("Used", usedValue, "GB", .live, storageStatus, storageSeverity, "Capacity currently allocated on the startup volume.", "Derived from volume capacity and available capacity", "Live / high", "Review the largest readable folders before removing anything.", now),
      metric("Available", percentValue, "%", .live, storageStatus, storageSeverity, "Percentage of startup volume capacity still available.", "Derived from volume capacity and available capacity", "Live / high", "Aim for comfortable free space before large macOS or Xcode updates.", now)
    ]

    return StorageHealth(
      summary: metrics[1],
      totalGB: volume.totalGB,
      availableGB: volume.availableGB,
      usedGB: volume.usedGB,
      availablePercent: availablePercent,
      metrics: metrics,
      breakdown: [
        ChartDatum(title: "Used", value: volume.usedGB, unit: "GB", dataMode: .live, status: storageStatus, detail: "Startup volume used space"),
        ChartDatum(title: "Available", value: volume.availableGB, unit: "GB", dataMode: .live, status: .good, detail: "Startup volume free space")
      ],
      largeFolders: [],
      largeFiles: [],
      developerCaches: [],
      browserCaches: [],
      spaceOffenders: [],
      findings: findings(availablePercent: availablePercent),
      actions: [
        SafeAction(title: "Review Downloads manually", body: "Open Downloads in Finder only when you choose to review personal files.", systemImage: "folder", status: .good),
        SafeAction(title: "Enable targeted scan later", body: "Future storage scans should be explicit, scoped, and permission-aware.", systemImage: "hand.raised", status: .info)
      ],
      sourceNote: "Live storage data. Corewise reads startup volume capacity only during automatic refresh. Personal folders such as Downloads are not scanned automatically."
    )
  }

  private func volumeStats() -> (totalGB: Double, availableGB: Double, usedGB: Double) {
    let url = URL(fileURLWithPath: NSHomeDirectory())
    let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey]
    let values = try? url.resourceValues(forKeys: keys)
    let totalBytes = Double(values?.volumeTotalCapacity ?? 0)
    let availableBytes = Double(values?.volumeAvailableCapacityForImportantUsage ?? Int64(values?.volumeAvailableCapacity ?? 0))
    let usedBytes = max(totalBytes - availableBytes, 0)

    return (totalBytes / bytesPerGB, availableBytes / bytesPerGB, usedBytes / bytesPerGB)
  }

  private func findings(availablePercent: Double) -> [DiagnosticFinding] {
    let status = statusForAvailablePercent(availablePercent)
    let severity = severityForAvailablePercent(availablePercent)

    return [
      DiagnosticFinding(
        title: "Free space is \(status.rawValue.lowercased())",
        detail: "\(number(availablePercent))% of the startup volume is available.",
        status: status,
        severityScore: severity
      ),
      DiagnosticFinding(
        title: "Personal folders are not scanned automatically",
        detail: "Downloads, caches, Trash, and developer folders stay unscanned until Corewise has an explicit targeted review flow.",
        status: .info,
        severityScore: 0
      )
    ]
  }

  private func metric(
    _ title: String,
    _ value: String,
    _ unit: String,
    _ dataMode: DataMode,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date
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

  private func statusForAvailablePercent(_ percent: Double) -> FindingSeverity {
    if percent < 8 {
      return .critical
    }
    if percent < 18 {
      return .warning
    }
    if percent < 28 {
      return .info
    }
    return .good
  }

  private func severityForAvailablePercent(_ percent: Double) -> Int {
    min(max(Int((100 - percent).rounded()), 0), 100)
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }

  private let bytesPerGB = 1024.0 * 1024.0 * 1024.0
}
