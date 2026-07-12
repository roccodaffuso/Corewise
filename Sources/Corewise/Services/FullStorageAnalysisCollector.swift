import Foundation

struct FullStorageAnalysisCollector {
  private var fileManager: FileManager
  private var canReadDirectory: (URL) -> Bool
  private var targetedCollector: StorageTargetedScanCollector
  private var configuredScopes: [URL]?
  private var configuredProbeScopes: [URL]?

  init(
    fileManager: FileManager = .default,
    scopes: [URL]? = nil,
    probeScopes: [URL]? = nil,
    canReadDirectory: ((URL) -> Bool)? = nil,
    targetedCollector: StorageTargetedScanCollector = StorageTargetedScanCollector()
  ) {
    self.fileManager = fileManager
    self.configuredScopes = scopes
    self.configuredProbeScopes = probeScopes
    self.targetedCollector = targetedCollector
    self.canReadDirectory = canReadDirectory ?? { url in
      guard FileManager.default.fileExists(atPath: url.path) else {
        return false
      }
      return (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsHiddenFiles])) != nil
    }
  }

  func probe(now: Date = Date()) -> StorageAccessProbeResult {
    let scopes = existingFullDiskAccessProbeScopes()
    guard !scopes.isEmpty else {
      return StorageAccessProbeResult(status: .unavailable, accessibleScopeCount: 0, totalScopeCount: 0, accessibleScopes: [], inaccessibleScopes: [], lastUpdated: now)
    }

    var accessible: [URL] = []
    var inaccessible: [URL] = []
    for scope in scopes {
      if canReadDirectory(scope) {
        accessible.append(scope)
      } else {
        inaccessible.append(scope)
      }
    }
    let status: StorageAccessStatus = inaccessible.isEmpty ? .fullDiskAccessLikelyGranted : .needsFullDiskAccess

    return StorageAccessProbeResult(
      status: status,
      accessibleScopeCount: accessible.count,
      totalScopeCount: scopes.count,
      accessibleScopes: accessible.map(scopeTitle),
      inaccessibleScopes: inaccessible.map(scopeTitle),
      lastUpdated: now
    )
  }

  func scan(
    now: Date = Date(),
    onProgress: @escaping @Sendable (StorageScanProgress) -> Void = { _ in }
  ) -> StorageScanResult {
    let start = Date()
    let readableScopes = existingStandardScopes().filter(canReadDirectory)
    var results: [StorageScanResult] = []
    for (offset, scope) in readableScopes.enumerated() {
      if Task.isCancelled {
        break
      }
      results.append(
        targetedCollector.scan(
          root: scope,
          now: now,
          source: "Full Storage Analysis",
          scopeIndex: offset + 1,
          scopeCount: readableScopes.count,
          onProgress: onProgress
        )
      )
    }
    return aggregate(results: results, scopeCount: readableScopes.count, now: now, duration: Date().timeIntervalSince(start))
  }

  func existingStandardScopes() -> [URL] {
    if let configuredScopes {
      return uniqueExistingScopes(configuredScopes)
    }

    let home = fileManager.homeDirectoryForCurrentUser
    let candidates = [
      URL(fileURLWithPath: "/Applications"),
      home.appendingPathComponent("Applications"),
      home.appendingPathComponent("Desktop"),
      home.appendingPathComponent("Documents"),
      home.appendingPathComponent("Downloads"),
      home.appendingPathComponent("Movies"),
      home.appendingPathComponent("Music"),
      home.appendingPathComponent("Pictures"),
      home.appendingPathComponent("Library/Developer"),
      home.appendingPathComponent("Library/Caches"),
      home.appendingPathComponent("Library/Application Support")
    ]

    return uniqueExistingScopes(candidates)
  }

  private func existingFullDiskAccessProbeScopes() -> [URL] {
    if let configuredProbeScopes {
      return uniqueExistingScopes(configuredProbeScopes)
    }
    if let configuredScopes {
      return uniqueExistingScopes(configuredScopes)
    }

    let home = fileManager.homeDirectoryForCurrentUser
    let candidates = [
      home.appendingPathComponent("Library/Application Support/com.apple.TCC"),
      home.appendingPathComponent("Library/Mail"),
      home.appendingPathComponent("Library/Safari"),
      home.appendingPathComponent("Library/Messages")
    ]
    return uniqueExistingScopes(candidates)
  }

  private func uniqueExistingScopes(_ urls: [URL]) -> [URL] {
    var seen = Set<String>()
    return urls.filter { url in
      let path = url.standardizedFileURL.path
      guard fileManager.fileExists(atPath: path), !seen.contains(path) else {
        return false
      }
      seen.insert(path)
      return true
    }
  }

  private func aggregate(results: [StorageScanResult], scopeCount: Int, now: Date, duration: TimeInterval) -> StorageScanResult {
    var categoryTotals: [StorageCategory: StorageCategorySummary] = [:]
    let files = results.flatMap(\.largestFiles).sorted { $0.sizeGB > $1.sizeGB }.prefix(10)
    let folders = results.flatMap(\.largestFolders).sorted { $0.sizeGB > $1.sizeGB }.prefix(10)
    let totalSize = results.reduce(0) { $0 + $1.totalSizeGB }
    let fileCount = results.reduce(0) { $0 + $1.scannedFileCount }
    let folderCount = results.reduce(0) { $0 + $1.scannedFolderCount }
    let inaccessibleCount = results.reduce(0) { $0 + $1.inaccessibleItemCount }

    for summary in results.flatMap(\.categoryBreakdown) {
      if let existing = categoryTotals[summary.category] {
        let examples = (existing.largestExamples + summary.largestExamples).sorted { $0.sizeGB > $1.sizeGB }.prefix(3)
        categoryTotals[summary.category] = StorageCategorySummary(
          category: summary.category,
          title: summary.title,
          sizeGB: existing.sizeGB + summary.sizeGB,
          fileCount: existing.fileCount + summary.fileCount,
          folderCount: existing.folderCount + summary.folderCount,
          largestExamples: Array(examples),
          dataMode: .live,
          status: status(for: existing.sizeGB + summary.sizeGB),
          source: "Full Storage Analysis",
          confidence: "Live / medium"
        )
      } else {
        categoryTotals[summary.category] = StorageCategorySummary(
          category: summary.category,
          title: summary.title,
          sizeGB: summary.sizeGB,
          fileCount: summary.fileCount,
          folderCount: summary.folderCount,
          largestExamples: summary.largestExamples,
          dataMode: .live,
          status: status(for: summary.sizeGB),
          source: "Full Storage Analysis",
          confidence: "Live / medium"
        )
      }
    }

    let categories = categoryTotals.values.sorted { $0.sizeGB > $1.sizeGB }
    let chartData = categories.filter { $0.sizeGB > 0 }.map {
      ChartDatum(title: $0.title, value: $0.sizeGB, unit: "GB", dataMode: .live, status: $0.status, detail: "\($0.fileCount) files · \($0.folderCount) folders")
    }
    let largestItems = Array((Array(folders) + Array(files)).sorted { $0.sizeGB > $1.sizeGB }.prefix(10))

    return StorageScanResult(
      rootTitle: "Full Storage Analysis",
      rootPath: "\(scopeCount) standard scopes",
      totalSizeGB: totalSize,
      scannedItemCount: fileCount,
      scannedFileCount: fileCount,
      scannedFolderCount: folderCount,
      inaccessibleItemCount: inaccessibleCount,
      scanDuration: duration,
      largestItems: largestItems,
      largestFiles: Array(files),
      largestFolders: Array(folders),
      categoryBreakdown: categories,
      chartData: chartData,
      lastUpdated: now
    )
  }

  private func scopeTitle(_ url: URL) -> String {
    let home = fileManager.homeDirectoryForCurrentUser.standardizedFileURL.path
    let path = url.standardizedFileURL.path
    if path.hasPrefix(home) {
      let relative = path.dropFirst(home.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      return relative.isEmpty ? "Home" : relative
    }
    return url.lastPathComponent.isEmpty ? path : url.lastPathComponent
  }

  private func status(for gb: Double) -> FindingSeverity {
    if gb >= 50 {
      return .warning
    }
    if gb >= 10 {
      return .info
    }
    return .good
  }
}
