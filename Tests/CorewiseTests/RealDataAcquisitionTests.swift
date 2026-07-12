import Foundation
import Testing
import UniformTypeIdentifiers
@testable import Corewise

@Test func storageCategoryClassifierUsesPathTypeAndExtensionPriority() {
  let classifier = StorageCategoryClassifier()

  #expect(classifier.category(for: URL(fileURLWithPath: "/Applications/Foo.app"), isDirectory: true, isPackage: true, contentType: .applicationBundle) == .applications)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/Library/Developer/Xcode/DerivedData/App/file.o"), isDirectory: false, isPackage: false, contentType: nil) == .development)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/project/node_modules/pkg/index.js"), isDirectory: false, isPackage: false, contentType: .sourceCode) == .development)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/Pictures/photo.png"), isDirectory: false, isPackage: false, contentType: .png) == .photos)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/Movies/clip.mov"), isDirectory: false, isPackage: false, contentType: .quickTimeMovie) == .video)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/Music/song.mp3"), isDirectory: false, isPackage: false, contentType: .mp3) == .music)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/Downloads/archive.zip"), isDirectory: false, isPackage: false, contentType: .zip) == .archivesInstallers)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/Library/Caches/cache.bin"), isDirectory: false, isPackage: false, contentType: nil) == .cacheTemporary)
  #expect(classifier.category(for: URL(fileURLWithPath: "/Users/rocco/unknown.custom"), isDirectory: false, isPackage: false, contentType: nil) == .other)
}

@Test func targetedStorageScanReadsOnlyChosenFolder() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-storage-\(UUID().uuidString)")
  let nested = root.appendingPathComponent("Nested")
  let appBundle = root.appendingPathComponent("Fake.app/Contents/MacOS")
  let development = root.appendingPathComponent("node_modules/pkg")
  let cache = root.appendingPathComponent("Library/Caches/App")
  try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: appBundle, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: development, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
  try Data(repeating: 1, count: 1024).write(to: root.appendingPathComponent("root.bin"))
  try Data(repeating: 2, count: 2048).write(to: nested.appendingPathComponent("nested.bin"))
  try Data(repeating: 3, count: 4096).write(to: root.appendingPathComponent("movie.mov"))
  try Data(repeating: 4, count: 4096).write(to: root.appendingPathComponent("archive.zip"))
  try Data(repeating: 5, count: 4096).write(to: appBundle.appendingPathComponent("Fake"))
  try Data(repeating: 6, count: 4096).write(to: development.appendingPathComponent("index.js"))
  try Data(repeating: 7, count: 4096).write(to: cache.appendingPathComponent("cache.db"))

  let result = StorageTargetedScanCollector().scan(root: root, now: Date())

  #expect(result.scannedItemCount == 7)
  #expect(result.scannedFileCount == 7)
  #expect(result.scannedFolderCount >= 1)
  #expect(result.inaccessibleItemCount == 0)
  #expect(result.totalSizeGB > 0)
  #expect(result.largestFiles.contains { $0.title == "nested.bin" })
  #expect(result.largestFolders.contains { $0.title == "Nested" })
  #expect(result.categoryBreakdown.contains { $0.title == "Video" })
  #expect(result.categoryBreakdown.contains { $0.category == .archivesInstallers })
  #expect(result.categoryBreakdown.contains { $0.category == .applications })
  #expect(result.categoryBreakdown.contains { $0.category == .development })
  #expect(result.categoryBreakdown.contains { $0.category == .cacheTemporary })
  #expect(result.categoryBreakdown.allSatisfy { $0.source == "User-selected folder scan" })
  #expect(result.categoryBreakdown.allSatisfy { !$0.confidence.isEmpty })
  #expect(result.categoryBreakdown.contains { !$0.largestExamples.isEmpty })
  #expect(result.chartData.allSatisfy { $0.dataMode == .live })
  #expect(result.chartData.contains { $0.title == "Archives & Installers" })
}

@Test func targetedStorageScanHandlesEmptyFolder() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-empty-storage-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

  let result = StorageTargetedScanCollector().scan(root: root, now: Date())

  #expect(result.scannedItemCount == 0)
  #expect(result.scannedFileCount == 0)
  #expect(result.totalSizeGB == 0)
  #expect(result.largestItems.isEmpty)
  #expect(result.categoryBreakdown.isEmpty)
  #expect(result.chartData.isEmpty)
}

@Test func targetedStorageScanKeepsOnlyTenLargestFiles() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-top-files-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }

  for index in 1...15 {
    try Data(repeating: UInt8(index), count: index * 64 * 1024)
      .write(to: root.appendingPathComponent("file-\(index).bin"))
  }

  let result = StorageTargetedScanCollector().scan(root: root, now: Date())

  #expect(result.scannedFileCount == 15)
  #expect(result.largestFiles.count == 10)
  #expect(result.largestFiles.map(\.sizeGB) == result.largestFiles.map(\.sizeGB).sorted(by: >))
  #expect(result.largestFiles.contains { $0.title == "file-15.bin" })
  #expect(result.largestFiles.contains { $0.title == "file-1.bin" } == false)
  let category = try #require(result.categoryBreakdown.first { $0.largestExamples.contains { $0.title == "file-15.bin" } })
  #expect(category.largestExamples.count == 3)
  #expect(category.largestExamples.map(\.sizeGB) == category.largestExamples.map(\.sizeGB).sorted(by: >))
  #expect(category.largestExamples.contains { $0.title == "file-1.bin" } == false)
}

@Test func targetedStorageScanStopsWhenCancellationIsRequested() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-cancelled-scan-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }

  for index in 0..<20 {
    try Data(repeating: UInt8(index), count: 1024)
      .write(to: root.appendingPathComponent("file-\(index).bin"))
  }

  var cancellationChecks = 0
  let result = StorageTargetedScanCollector(isCancelled: {
    cancellationChecks += 1
    return cancellationChecks > 4
  }).scan(root: root, now: Date())

  #expect(result.scannedFileCount < 20)
}

@Test func fullStorageAccessProbeReflectsReadableScopes() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-full-probe-\(UUID().uuidString)")
  let readable = root.appendingPathComponent("Documents")
  let blocked = root.appendingPathComponent("Pictures")
  try FileManager.default.createDirectory(at: readable, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)

  let denied = FullStorageAnalysisCollector(scopes: [readable, blocked], canReadDirectory: { $0 != blocked })
    .probe(now: Date())
  #expect(denied.status == .needsFullDiskAccess)
  #expect(denied.accessibleScopeCount == 1)
  #expect(denied.totalScopeCount == 2)

  let granted = FullStorageAnalysisCollector(scopes: [readable, blocked], canReadDirectory: { _ in true })
    .probe(now: Date())
  #expect(granted.status == .fullDiskAccessLikelyGranted)
  #expect(granted.accessibleScopeCount == 2)
}

@Test func fullStorageAccessProbeChecksEachScopeOnce() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-probe-once-\(UUID().uuidString)")
  let first = root.appendingPathComponent("First")
  let second = root.appendingPathComponent("Second")
  try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }

  var checks = 0
  _ = FullStorageAnalysisCollector(scopes: [first, second], canReadDirectory: { _ in
    checks += 1
    return true
  }).probe(now: Date())

  #expect(checks == 2)
}

@Test func fullStorageAccessProbeDoesNotTouchScanFoldersBeforeConsent() throws {
  let root = FileManager.default.temporaryDirectory.appending(path: "corewise-fda-probe-\(UUID().uuidString)")
  let documents = root.appendingPathComponent("Documents")
  let downloads = root.appendingPathComponent("Downloads")
  let protectedSentinel = root.appendingPathComponent("Protected Sentinel")
  for directory in [documents, downloads, protectedSentinel] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }
  defer { try? FileManager.default.removeItem(at: root) }

  var checked: [URL] = []
  let collector = FullStorageAnalysisCollector(
    scopes: [documents, downloads],
    probeScopes: [protectedSentinel],
    canReadDirectory: { url in
      checked.append(url)
      return false
    }
  )

  let probe = collector.probe()

  #expect(probe.status == .needsFullDiskAccess)
  #expect(checked == [protectedSentinel])
}

@Test func fullStorageAnalysisAggregatesMultipleScopes() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-full-scan-\(UUID().uuidString)")
  let documents = root.appendingPathComponent("Documents")
  let developer = root.appendingPathComponent("Library/Developer/Xcode/DerivedData/App")
  let pictures = root.appendingPathComponent("Pictures")
  try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: developer, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: pictures, withIntermediateDirectories: true)
  try Data(repeating: 1, count: 2048).write(to: documents.appendingPathComponent("brief.pdf"))
  try Data(repeating: 2, count: 4096).write(to: developer.appendingPathComponent("build.o"))
  try Data(repeating: 3, count: 1024).write(to: pictures.appendingPathComponent("photo.png"))

  let result = FullStorageAnalysisCollector(scopes: [documents, root.appendingPathComponent("Library/Developer"), pictures], canReadDirectory: { _ in true })
    .scan(now: Date())

  #expect(result.rootTitle == "Full Storage Analysis")
  #expect(result.scannedFileCount == 3)
  #expect(result.categoryBreakdown.contains { $0.category == .documents })
  #expect(result.categoryBreakdown.contains { $0.category == .development })
  #expect(result.categoryBreakdown.contains { $0.category == .photos })
  #expect(result.chartData.allSatisfy { $0.dataMode == .live })
  #expect(result.categoryBreakdown.allSatisfy { $0.source == "Full Storage Analysis" })
}

@MainActor
@Test func fullStorageAnalysisRunsOnlyWhenExplicitlyRequested() {
  let now = Date()
  let interval: TimeInterval = 6 * 60 * 60

  #expect(!HealthDashboardStore.shouldRunStorageAnalysis(lastScanAt: nil, now: now, interval: interval, force: false))
  #expect(!HealthDashboardStore.shouldRunStorageAnalysis(lastScanAt: now.addingTimeInterval(-60), now: now, interval: interval, force: false))
  #expect(!HealthDashboardStore.shouldRunStorageAnalysis(lastScanAt: now.addingTimeInterval(-interval - 1), now: now, interval: interval, force: false))
  #expect(HealthDashboardStore.shouldRunStorageAnalysis(lastScanAt: now.addingTimeInterval(-60), now: now, interval: interval, force: true))
}

@MainActor
@Test func storageAccessProbeRunsInitiallyAndThenUsesItsThrottle() {
  let now = Date()
  let interval: TimeInterval = 60

  #expect(HealthDashboardStore.shouldProbeStorageAccess(lastProbeAt: nil, now: now, interval: interval, force: false))
  #expect(!HealthDashboardStore.shouldProbeStorageAccess(lastProbeAt: now.addingTimeInterval(-30), now: now, interval: interval, force: false))
  #expect(HealthDashboardStore.shouldProbeStorageAccess(lastProbeAt: now.addingTimeInterval(-61), now: now, interval: interval, force: false))
  #expect(HealthDashboardStore.shouldProbeStorageAccess(lastProbeAt: now, now: now, interval: interval, force: true))
}

@MainActor
@Test func storageScanSessionSupportsBreadcrumbDrilldown() async throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-session-\(UUID().uuidString)")
  let nested = root.appendingPathComponent("Nested")
  try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
  try Data(repeating: 1, count: 1024).write(to: nested.appendingPathComponent("nested.bin"))

  let store = HealthDashboardStore(collector: SystemHealthCollector())
  await store.scanStorageSessionFolder(root)
  let rootSession = try #require(store.storageScanSession)

  #expect(rootSession.rootURL.standardizedFileURL == root.standardizedFileURL)
  #expect(rootSession.currentURL.standardizedFileURL == root.standardizedFileURL)
  #expect(rootSession.breadcrumbs.count == 1)
  #expect(rootSession.result.largestFolders.contains { $0.title == "Nested" })

  await store.scanStorageSessionFolder(nested)
  let nestedSession = try #require(store.storageScanSession)

  #expect(nestedSession.rootURL.standardizedFileURL == root.standardizedFileURL)
  #expect(nestedSession.currentURL.standardizedFileURL == nested.standardizedFileURL)
  #expect(nestedSession.breadcrumbs.map(\.title).contains("Nested"))
  #expect(nestedSession.result.largestFiles.contains { $0.title == "nested.bin" })

  await store.scanStorageParentFolder()
  let parentSession = try #require(store.storageScanSession)

  #expect(parentSession.currentURL.standardizedFileURL == root.standardizedFileURL)
}

@Test func crashReportCollectorParsesRepeatedAppsFromSelectedFolder() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-reports-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  let now = try #require(reportDate("2026-07-08 12:00:00.000 +0000"))

  try report(
    process: "Notes",
    identifier: "com.apple.Notes",
    version: "1.0",
    date: "2026-07-07 12:00:00.000 +0000"
  ).write(to: root.appendingPathComponent("Notes_2026-07-07.crash"), atomically: true, encoding: .utf8)

  try report(
    process: "Notes",
    identifier: "com.apple.Notes",
    version: "1.0",
    date: "2026-07-06 12:00:00.000 +0000"
  ).write(to: root.appendingPathComponent("Notes_2026-07-06.crash"), atomically: true, encoding: .utf8)

  let issues = CrashReportDiagnosticsCollector().currentAppIssues(reportDirectory: root, now: now)
  let notes = try #require(issues.crashes.first)

  #expect(issues.summary.dataMode == .live)
  #expect(notes.appName == "Notes")
  #expect(notes.bundleID == "com.apple.Notes")
  #expect(notes.crashesLast7Days == 2)
  #expect(notes.crashesLast30Days == 2)
  #expect(notes.repeatedCrash)
  #expect(issues.crashesByApp.first?.dataMode == .live)
}

@Test func crashReportCollectorUnavailableBeforeFolderSelection() {
  let issues = CrashReportDiagnosticsCollector().unavailableAppIssues(now: Date())

  #expect(issues.summary.dataMode == .unavailable)
  #expect(issues.crashes.isEmpty)
  #expect(issues.crashesByApp.isEmpty)
}

@Test func memoryPressureStaysUnavailableWithoutReliablePublicParitySource() {
  let metric = SystemMetricsSampler.memoryPressureEstimate(memoryPercent: 95, swapUsedGB: 9)

  #expect(metric.value == "Unavailable")
  #expect(metric.dataMode == .unavailable)
  #expect(metric.explanation.contains("public source"))
}

private func report(process: String, identifier: String, version: String, date: String) -> String {
  """
  Process:               \(process) [123]
  Identifier:            \(identifier)
  Version:               \(version)
  Date/Time:             \(date)
  Thread 0 Crashed:
  """
}

private func reportDate(_ value: String) -> Date? {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
  return formatter.date(from: value)
}
