import Foundation

struct StorageDiagnosticsCollector {
  func currentStorage(now: Date) -> StorageHealth {
    let volume = volumeStats()
    let knownGroups = scanKnownGroups(now: now)
    let allItems = knownGroups.largeFolders + knownGroups.largeFiles + knownGroups.developerCaches + knownGroups.browserCaches
    let offenders = allItems
      .sorted { $0.sizeGB > $1.sizeGB }
      .prefix(8)
      .map { item in
        ChartDatum(
          title: item.title,
          value: item.sizeGB,
          unit: "GB",
          dataMode: item.dataMode,
          status: item.status,
          detail: item.path
        )
      }

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
      largeFolders: knownGroups.largeFolders,
      largeFiles: knownGroups.largeFiles,
      developerCaches: knownGroups.developerCaches,
      browserCaches: knownGroups.browserCaches,
      spaceOffenders: Array(offenders),
      findings: findings(availablePercent: availablePercent, offenders: allItems),
      actions: [
        SafeAction(title: "Review readable folders", body: "Open large folders and decide manually what you recognize.", systemImage: "folder", status: .good),
        SafeAction(title: "Use app-owned cleanup", body: "Use Xcode or browser settings for app caches when possible.", systemImage: "wrench.and.screwdriver", status: .info)
      ],
      sourceNote: "Live storage data. Corewise reads volume capacity and selected known paths without modifying files. Missing or unreadable folders are omitted instead of estimated."
    )
  }

  private func scanKnownGroups(now: Date) -> KnownStorageGroups {
    let home = FileManager.default.homeDirectoryForCurrentUser

    let largeFolders = [
      storageItemIfReadable("Downloads", url: home.appendingPathComponent("Downloads"), now: now),
      storageItemIfReadable("Trash", url: home.appendingPathComponent(".Trash"), now: now)
    ].compactMap { $0 }

    let developerCaches = [
      storageItemIfReadable("Xcode DerivedData", url: home.appendingPathComponent("Library/Developer/Xcode/DerivedData"), now: now),
      storageItemIfReadable("Simulators", url: home.appendingPathComponent("Library/Developer/CoreSimulator"), now: now),
      storageItemIfReadable("Archives", url: home.appendingPathComponent("Library/Developer/Xcode/Archives"), now: now)
    ].compactMap { $0 }

    let browserCaches = [
      storageItemIfReadable("Safari Cache", url: home.appendingPathComponent("Library/Caches/com.apple.Safari"), now: now),
      storageItemIfReadable("Chrome Cache", url: home.appendingPathComponent("Library/Caches/Google/Chrome"), now: now)
    ].compactMap { $0 }

    let largeFiles = largestFiles(in: home.appendingPathComponent("Downloads"), now: now)

    return KnownStorageGroups(
      largeFolders: largeFolders,
      largeFiles: largeFiles,
      developerCaches: developerCaches,
      browserCaches: browserCaches
    )
  }

  private func storageItemIfReadable(_ title: String, url: URL, now: Date) -> StorageItem? {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return nil
    }

    let size = folderSize(url)
    guard size > 0 else {
      return nil
    }

    let sizeGB = Double(size) / bytesPerGB
    return StorageItem(
      title: title,
      path: displayPath(url),
      sizeGB: sizeGB,
      dataMode: .live,
      status: storageItemStatus(sizeGB),
      severityScore: min(max(Int((sizeGB * 2).rounded()), 0), 100),
      explanation: "Readable folder size from a local read-only scan.",
      source: "FileManager read-only size scan",
      confidence: "Live / medium",
      recommendedAction: "Open and review manually; Corewise will not remove files.",
      lastUpdated: now
    )
  }

  private func largestFiles(in url: URL, now: Date) -> [StorageItem] {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return []
    }

    let keys: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
    guard let enumerator = FileManager.default.enumerator(
      at: url,
      includingPropertiesForKeys: keys,
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) else {
      return []
    }

    var files: [StorageItem] = []

    for case let fileURL as URL in enumerator {
      guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
            values.isRegularFile == true else {
        continue
      }

      let bytes = UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
      let sizeGB = Double(bytes) / bytesPerGB
      guard sizeGB >= 0.5 else {
        continue
      }

      files.append(
        StorageItem(
          title: fileURL.lastPathComponent,
          path: displayPath(fileURL),
          sizeGB: sizeGB,
          dataMode: .live,
          status: storageItemStatus(sizeGB),
          severityScore: min(max(Int((sizeGB * 4).rounded()), 0), 100),
          explanation: "Large readable file found in Downloads.",
          source: "FileManager read-only file scan",
          confidence: "Live / medium",
          recommendedAction: "Open in Finder and decide whether you still need it.",
          lastUpdated: now
        )
      )
    }

    return Array(files.sorted { $0.sizeGB > $1.sizeGB }.prefix(8))
  }

  private func folderSize(_ url: URL) -> UInt64 {
    let keys: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
    guard let enumerator = FileManager.default.enumerator(
      at: url,
      includingPropertiesForKeys: keys,
      options: [.skipsHiddenFiles]
    ) else {
      return 0
    }

    var total: UInt64 = 0

    for case let fileURL as URL in enumerator {
      guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
            values.isRegularFile == true else {
        continue
      }

      total += UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }

    return total
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

  private func findings(availablePercent: Double, offenders: [StorageItem]) -> [DiagnosticFinding] {
    let status = statusForAvailablePercent(availablePercent)
    let severity = severityForAvailablePercent(availablePercent)
    let largest = offenders.sorted { $0.sizeGB > $1.sizeGB }.first

    return [
      DiagnosticFinding(
        title: "Free space is \(status.rawValue.lowercased())",
        detail: "\(number(availablePercent))% of the startup volume is available.",
        status: status,
        severityScore: severity
      ),
      DiagnosticFinding(
        title: largest == nil ? "No large readable offender yet" : "\(largest!.title) is the largest readable item",
        detail: largest == nil ? "Known folders were absent, unreadable, or below the display threshold." : "\(largest!.path) is currently the largest item Corewise scanned.",
        status: largest == nil ? .info : largest!.status,
        severityScore: largest == nil ? 0 : largest!.severityScore
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

  private func storageItemStatus(_ sizeGB: Double) -> FindingSeverity {
    if sizeGB >= 30 {
      return .warning
    }
    if sizeGB >= 8 {
      return .info
    }
    return .good
  }

  private func displayPath(_ url: URL) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    if url.path.hasPrefix(home) {
      return "~" + url.path.dropFirst(home.count)
    }
    return url.path
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }

  private let bytesPerGB = 1024.0 * 1024.0 * 1024.0
}

private struct KnownStorageGroups {
  var largeFolders: [StorageItem]
  var largeFiles: [StorageItem]
  var developerCaches: [StorageItem]
  var browserCaches: [StorageItem]
}
