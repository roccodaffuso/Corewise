import Foundation

struct StorageTargetedScanCollector {
  private var fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func scan(root: URL, now: Date = Date()) -> StorageScanResult {
    let start = Date()
    let rootPath = root.standardizedFileURL.path
    var totalBytes: UInt64 = 0
    var scannedItemCount = 0
    var inaccessibleItemCount = 0
    var fileRecords: [(url: URL, bytes: UInt64)] = []
    var folderTotals: [String: UInt64] = [:]

    guard let enumerator = fileManager.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey],
      options: [.skipsPackageDescendants]
    ) else {
      return emptyResult(root: root, now: now, duration: Date().timeIntervalSince(start), inaccessibleItemCount: 1)
    }

    for case let url as URL in enumerator {
      do {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey])
        guard values.isRegularFile == true else {
          continue
        }

        let bytes = UInt64(max(values.totalFileAllocatedSize ?? values.fileSize ?? 0, 0))
        totalBytes += bytes
        scannedItemCount += 1
        fileRecords.append((url, bytes))

        if let topFolder = topLevelFolderName(for: url, rootPath: rootPath) {
          folderTotals[topFolder, default: 0] += bytes
        }
      } catch {
        inaccessibleItemCount += 1
      }
    }

    let lastUpdated = now
    let largestFiles = fileRecords
      .sorted { $0.bytes > $1.bytes }
      .prefix(10)
      .map { storageItem(title: $0.url.lastPathComponent, path: displayPath($0.url), bytes: $0.bytes, source: "User-selected folder scan", now: lastUpdated) }

    let largestFolders = folderTotals
      .map { (title: $0.key, bytes: $0.value) }
      .sorted { $0.bytes > $1.bytes }
      .prefix(10)
      .map { storageItem(title: $0.title, path: "\(displayPath(root))/\($0.title)", bytes: $0.bytes, source: "User-selected folder scan", now: lastUpdated) }

    let largestItems = (largestFolders + largestFiles)
      .sorted { $0.sizeGB > $1.sizeGB }
      .prefix(10)

    return StorageScanResult(
      rootTitle: root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent,
      rootPath: displayPath(root),
      totalSizeGB: gb(totalBytes),
      scannedItemCount: scannedItemCount,
      inaccessibleItemCount: inaccessibleItemCount,
      scanDuration: Date().timeIntervalSince(start),
      largestItems: Array(largestItems),
      largestFiles: largestFiles,
      largestFolders: largestFolders,
      chartData: largestItems.map {
        ChartDatum(title: $0.title, value: $0.sizeGB, unit: "GB", dataMode: .live, status: $0.status, detail: $0.path)
      },
      lastUpdated: lastUpdated
    )
  }

  private func emptyResult(root: URL, now: Date, duration: TimeInterval, inaccessibleItemCount: Int) -> StorageScanResult {
    StorageScanResult(
      rootTitle: root.lastPathComponent,
      rootPath: displayPath(root),
      totalSizeGB: 0,
      scannedItemCount: 0,
      inaccessibleItemCount: inaccessibleItemCount,
      scanDuration: duration,
      largestItems: [],
      largestFiles: [],
      largestFolders: [],
      chartData: [],
      lastUpdated: now
    )
  }

  private func storageItem(title: String, path: String, bytes: UInt64, source: String, now: Date) -> StorageItem {
    let sizeGB = gb(bytes)
    return StorageItem(
      title: title,
      path: path,
      sizeGB: sizeGB,
      dataMode: .live,
      status: status(for: sizeGB),
      severityScore: severity(for: sizeGB),
      explanation: "Size found during a read-only scan of a user-selected folder.",
      source: source,
      confidence: "Live / medium",
      recommendedAction: "Review this item manually in Finder before changing anything.",
      lastUpdated: now
    )
  }

  private func topLevelFolderName(for url: URL, rootPath: String) -> String? {
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(rootPath) else {
      return nil
    }

    let relative = path.dropFirst(rootPath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let parts = relative.split(separator: "/", omittingEmptySubsequences: true)
    guard parts.count > 1 else {
      return nil
    }
    return String(parts[0])
  }

  private func displayPath(_ url: URL) -> String {
    let home = fileManager.homeDirectoryForCurrentUser.path
    let path = url.standardizedFileURL.path
    if path.hasPrefix(home) {
      return "~" + path.dropFirst(home.count)
    }
    return path
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

  private func severity(for gb: Double) -> Int {
    min(max(Int((gb * 2).rounded()), 0), 100)
  }

  private func gb(_ bytes: UInt64) -> Double {
    Double(bytes) / bytesPerGB
  }

  private let bytesPerGB = 1024.0 * 1024.0 * 1024.0
}
