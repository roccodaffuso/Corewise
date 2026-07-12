import Foundation
import UniformTypeIdentifiers

struct StorageTargetedScanCollector {
  private var fileManager: FileManager
  private var classifier: StorageCategoryClassifier
  private var isCancelled: () -> Bool

  init(
    fileManager: FileManager = .default,
    classifier: StorageCategoryClassifier = StorageCategoryClassifier(),
    isCancelled: @escaping () -> Bool = { Task.isCancelled }
  ) {
    self.fileManager = fileManager
    self.classifier = classifier
    self.isCancelled = isCancelled
  }

  func scan(
    root: URL,
    now: Date = Date(),
    source: String = "User-selected folder scan",
    scopeIndex: Int = 1,
    scopeCount: Int = 1,
    onProgress: @escaping @Sendable (StorageScanProgress) -> Void = { _ in }
  ) -> StorageScanResult {
    let start = Date()
    let rootPath = root.standardizedFileURL.path
    var totalBytes: UInt64 = 0
    var scannedFileCount = 0
    var scannedFolderCount = 0
    var inaccessibleItemCount = 0
    var largestFileRecords: [(url: URL, bytes: UInt64)] = []
    var folderTotals: [String: UInt64] = [:]
    var categoryTotals: [StorageCategory: CategoryAccumulator] = [:]
    var lastProgressEmission = Date.distantPast

    func emitProgress(force: Bool = false) {
      let timestamp = Date()
      guard force || timestamp.timeIntervalSince(lastProgressEmission) >= 0.25 else {
        return
      }
      lastProgressEmission = timestamp
      onProgress(
        StorageScanProgress(
          currentScope: root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent,
          scopeIndex: max(scopeIndex, 1),
          scopeCount: max(scopeCount, 1),
          scannedFiles: scannedFileCount,
          scannedFolders: scannedFolderCount,
          unreadableCount: inaccessibleItemCount,
          elapsed: timestamp.timeIntervalSince(start)
        )
      )
    }

    emitProgress(force: true)

    guard let enumerator = fileManager.enumerator(
      at: root,
      includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .contentTypeKey, .fileSizeKey, .totalFileAllocatedSizeKey],
      options: []
    ) else {
      return emptyResult(root: root, now: now, duration: Date().timeIntervalSince(start), inaccessibleItemCount: 1)
    }

    while !isCancelled() {
      let nextURL: URL? = autoreleasepool {
        enumerator.nextObject() as? URL
      }
      guard let url = nextURL else {
        break
      }

      autoreleasepool {
        let standardizedPath = url.standardizedFileURL.path
        let topFolder = topLevelFolderName(forPath: standardizedPath, rootPath: rootPath)

        do {
          let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey, .isPackageKey, .contentTypeKey, .fileSizeKey, .totalFileAllocatedSizeKey])
          if values.isDirectory == true {
            scannedFolderCount += 1
            return
          }
          guard values.isRegularFile == true else {
            return
          }

          let bytes = UInt64(max(values.totalFileAllocatedSize ?? values.fileSize ?? 0, 0))
          let category = classifier.category(
            normalizedPath: standardizedPath.lowercased(),
            pathExtension: url.pathExtension.lowercased(),
            isDirectory: false,
            isPackage: values.isPackage == true,
            contentType: values.contentType
          )
          totalBytes += bytes
          scannedFileCount += 1
          insertLargestFile((url, bytes), into: &largestFileRecords)
          categoryTotals[category, default: CategoryAccumulator()].add(
            url: url,
            bytes: bytes,
            topFolder: topFolder
          )

          if let topFolder {
            folderTotals[topFolder, default: 0] += bytes
          }
        } catch {
          inaccessibleItemCount += 1
          categoryTotals[.unreadable, default: CategoryAccumulator()].add(
            url: url,
            bytes: 0,
            topFolder: topFolder
          )
        }
      }
      emitProgress()
    }
    emitProgress(force: true)

    let lastUpdated = now
    let largestFiles = largestFileRecords
      .map { storageItem(title: $0.url.lastPathComponent, path: displayPath($0.url), bytes: $0.bytes, source: source, now: lastUpdated) }

    let largestFolders = folderTotals
      .map { (title: $0.key, bytes: $0.value) }
      .sorted { $0.bytes > $1.bytes }
      .prefix(10)
      .map { storageItem(title: $0.title, path: "\(displayPath(root))/\($0.title)", bytes: $0.bytes, source: source, now: lastUpdated) }

    let largestItems = (largestFolders + largestFiles)
      .sorted { $0.sizeGB > $1.sizeGB }
      .prefix(10)
    let categoryBreakdown = categoryTotals
      .map { categorySummary(category: $0.key, accumulator: $0.value, source: source, now: lastUpdated) }
      .sorted { $0.sizeGB > $1.sizeGB }
    let categoryChartData = categoryBreakdown
      .filter { $0.sizeGB > 0 }
      .map {
        ChartDatum(
          title: $0.title,
          value: $0.sizeGB,
          unit: "GB",
          dataMode: .live,
          status: $0.status,
          detail: "\($0.fileCount) files · \($0.folderCount) folders"
        )
      }

    return StorageScanResult(
      rootTitle: root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent,
      rootPath: displayPath(root),
      totalSizeGB: gb(totalBytes),
      scannedItemCount: scannedFileCount,
      scannedFileCount: scannedFileCount,
      scannedFolderCount: scannedFolderCount,
      inaccessibleItemCount: inaccessibleItemCount,
      scanDuration: Date().timeIntervalSince(start),
      largestItems: Array(largestItems),
      largestFiles: largestFiles,
      largestFolders: largestFolders,
      categoryBreakdown: categoryBreakdown,
      chartData: categoryChartData,
      lastUpdated: lastUpdated
    )
  }

  private func emptyResult(root: URL, now: Date, duration: TimeInterval, inaccessibleItemCount: Int) -> StorageScanResult {
    StorageScanResult(
      rootTitle: root.lastPathComponent,
      rootPath: displayPath(root),
      totalSizeGB: 0,
      scannedItemCount: 0,
      scannedFileCount: 0,
      scannedFolderCount: 0,
      inaccessibleItemCount: inaccessibleItemCount,
      scanDuration: duration,
      largestItems: [],
      largestFiles: [],
      largestFolders: [],
      categoryBreakdown: [],
      chartData: [],
      lastUpdated: now
    )
  }

  private struct CategoryAccumulator {
    var bytes: UInt64 = 0
    var fileCount: Int = 0
    var folderNames: Set<String> = []
    var examples: [(url: URL, bytes: UInt64)] = []

    mutating func add(url: URL, bytes: UInt64, topFolder: String?) {
      self.bytes += bytes
      fileCount += 1
      if let topFolder {
        folderNames.insert(topFolder)
      }
      if let insertionIndex = examples.firstIndex(where: { bytes > $0.bytes }) {
        examples.insert((url, bytes), at: insertionIndex)
        if examples.count > 3 {
          examples.removeLast()
        }
      } else if examples.count < 3 {
        examples.append((url, bytes))
      }
    }
  }

  private func insertLargestFile(
    _ record: (url: URL, bytes: UInt64),
    into records: inout [(url: URL, bytes: UInt64)],
    limit: Int = 10
  ) {
    guard limit > 0 else {
      return
    }

    let insertionIndex = records.firstIndex { record.bytes > $0.bytes } ?? records.endIndex
    records.insert(record, at: insertionIndex)
    if records.count > limit {
      records.removeLast(records.count - limit)
    }
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

  private func categorySummary(category: StorageCategory, accumulator: CategoryAccumulator, source: String, now: Date) -> StorageCategorySummary {
    let sizeGB = gb(accumulator.bytes)
    let examples = accumulator.examples.map {
      storageItem(title: $0.url.lastPathComponent, path: displayPath($0.url), bytes: $0.bytes, source: source, now: now)
    }
    return StorageCategorySummary(
      category: category,
      title: category.title,
      sizeGB: sizeGB,
      fileCount: accumulator.fileCount,
      folderCount: accumulator.folderNames.count,
      largestExamples: examples,
      dataMode: .live,
      status: status(for: sizeGB),
      source: source,
      confidence: "Live / medium"
    )
  }

  private func topLevelFolderName(forPath path: String, rootPath: String) -> String? {
    guard path.hasPrefix(rootPath) else {
      return nil
    }

    var relative = path.dropFirst(rootPath.count)
    while relative.first == "/" {
      relative = relative.dropFirst()
    }
    guard let separator = relative.firstIndex(of: "/"), separator != relative.startIndex else {
      return nil
    }
    return String(relative[..<separator])
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
