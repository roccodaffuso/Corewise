import Foundation
import Testing
@testable import Corewise

@Test func targetedStorageScanReadsOnlyChosenFolder() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-storage-\(UUID().uuidString)")
  let nested = root.appendingPathComponent("Nested")
  try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
  try Data(repeating: 1, count: 1024).write(to: root.appendingPathComponent("root.bin"))
  try Data(repeating: 2, count: 2048).write(to: nested.appendingPathComponent("nested.bin"))

  let result = StorageTargetedScanCollector().scan(root: root, now: Date())

  #expect(result.scannedItemCount == 2)
  #expect(result.inaccessibleItemCount == 0)
  #expect(result.totalSizeGB > 0)
  #expect(result.largestFiles.contains { $0.title == "nested.bin" })
  #expect(result.largestFolders.contains { $0.title == "Nested" })
  #expect(result.chartData.allSatisfy { $0.dataMode == .live })
}

@Test func targetedStorageScanHandlesEmptyFolder() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-empty-storage-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

  let result = StorageTargetedScanCollector().scan(root: root, now: Date())

  #expect(result.scannedItemCount == 0)
  #expect(result.totalSizeGB == 0)
  #expect(result.largestItems.isEmpty)
  #expect(result.chartData.isEmpty)
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
