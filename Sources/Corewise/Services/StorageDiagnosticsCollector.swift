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
      metric("Used", usedValue, "GB", .live, storageStatus, storageSeverity, "Capacity currently allocated on the startup volume.", "Derived from volume capacity and available capacity", "Live / high", "Review the largest readable folders before removing anything.", now),
      metric("Available", availableValue, "GB", .live, storageStatus, storageSeverity, "Free space currently available for important work on the startup volume.", "FileManager volumeAvailableCapacityForImportantUsage", "Live / high", "Keep enough room for updates, builds, and temporary files.", now),
      metric("Available", percentValue, "%", .live, storageStatus, storageSeverity, "Percentage of startup volume capacity still available for important work.", "Derived from volume capacity and important-usage capacity", "Live / high", "Aim for comfortable free space before large macOS or Xcode updates.", now),
      metric("Finder Available", number(volume.rawAvailableGB), "GB", .live, .info, 0, "Raw available capacity reported by the volume, similar to the lower-level file-system free-space view.", "FileManager volumeAvailableCapacity", "Live / high", "Use Important Available for practical update/build headroom.", now),
      metric("Opportunistic", volume.opportunisticAvailableGB.map(number) ?? "N/A", volume.opportunisticAvailableGB == nil ? "" : "GB", volume.opportunisticAvailableGB == nil ? .unavailable : .live, .info, 0, "Space macOS reports as available for less urgent opportunistic work when exposed by the volume.", "FileManager volumeAvailableCapacityForOpportunisticUsage", volume.opportunisticAvailableGB == nil ? "Unavailable" : "Live / medium", "Treat this as context, not cleanup advice.", now),
      metric("Volume", volume.name, "", .live, .info, 0, "Startup volume name returned by macOS.", "FileManager volumeLocalizedName", "Live / high", "No action needed.", now),
      metric("Format", volume.formatDescription, "", .live, .info, 0, "File-system format description returned by macOS.", "FileManager volumeLocalizedFormatDescription", "Live / high", "No action needed.", now),
      metric("Volume Type", volume.volumeType, "", .live, .info, 0, "Whether the startup volume is local/internal when macOS exposes those flags.", "FileManager volume flags", "Live / medium", "No action needed.", now),
      metric("Read-only", volume.isReadOnly ? "Yes" : "No", "", .live, volume.isReadOnly ? .warning : .good, volume.isReadOnly ? 55 : 0, "Whether macOS reports the startup volume as read-only.", "FileManager volumeIsReadOnly", "Live / high", volume.isReadOnly ? "Review the volume state in Disk Utility." : "No action needed.", now)
    ]

    return StorageHealth(
      summary: metrics[2],
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
        SafeAction(title: "Enable Full Storage Analysis", body: "Grant Full Disk Access in macOS for local read-only size classification.", systemImage: "externaldrive.badge.checkmark", status: .info)
      ],
      sourceNote: "Live storage data. Corewise reads startup volume capacity automatically. Full Storage Analysis requires optional Full Disk Access and stays local/read-only."
    )
  }

  private func volumeStats() -> (
    totalGB: Double,
    availableGB: Double,
    usedGB: Double,
    rawAvailableGB: Double,
    opportunisticAvailableGB: Double?,
    name: String,
    formatDescription: String,
    volumeType: String,
    isReadOnly: Bool
  ) {
    let url = URL(fileURLWithPath: NSHomeDirectory())
    let keys: Set<URLResourceKey> = [
      .volumeTotalCapacityKey,
      .volumeAvailableCapacityForImportantUsageKey,
      .volumeAvailableCapacityForOpportunisticUsageKey,
      .volumeAvailableCapacityKey,
      .volumeLocalizedNameKey,
      .volumeLocalizedFormatDescriptionKey,
      .volumeIsInternalKey,
      .volumeIsLocalKey,
      .volumeIsReadOnlyKey
    ]
    let values = try? url.resourceValues(forKeys: keys)
    let totalBytes = Double(values?.volumeTotalCapacity ?? 0)
    let rawAvailableBytes = Double(values?.volumeAvailableCapacity ?? 0)
    let availableBytes = Double(values?.volumeAvailableCapacityForImportantUsage ?? Int64(values?.volumeAvailableCapacity ?? 0))
    let opportunisticAvailableGB = values?.volumeAvailableCapacityForOpportunisticUsage.map { Double($0) / bytesPerGB }
    let usedBytes = max(totalBytes - availableBytes, 0)
    let volumeName = values?.volumeLocalizedName ?? "Startup Volume"
    let formatDescription = values?.volumeLocalizedFormatDescription ?? "Unknown"
    let isInternal = values?.volumeIsInternal
    let isLocal = values?.volumeIsLocal
    let isReadOnly = values?.volumeIsReadOnly ?? false

    return (
      totalBytes / bytesPerGB,
      availableBytes / bytesPerGB,
      usedBytes / bytesPerGB,
      rawAvailableBytes / bytesPerGB,
      opportunisticAvailableGB,
      volumeName,
      formatDescription,
      volumeType(isInternal: isInternal, isLocal: isLocal),
      isReadOnly
    )
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
        title: "Full Storage Analysis needs consent",
        detail: "Corewise can classify standard folders after Full Disk Access is granted in macOS. It does not silently scan protected folders before that.",
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

  private func volumeType(isInternal: Bool?, isLocal: Bool?) -> String {
    switch (isInternal, isLocal) {
    case (.some(true), .some(true)):
      return "Internal local"
    case (.some(false), .some(true)):
      return "External local"
    case (_, .some(false)):
      return "Network"
    case (.some(true), nil):
      return "Internal"
    case (.some(false), nil):
      return "External"
    default:
      return "Unknown"
    }
  }

  private let bytesPerGB = 1024.0 * 1024.0 * 1024.0
}
