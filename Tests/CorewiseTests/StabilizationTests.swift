import Foundation
import Testing
@testable import Corewise

@Test func storageCollectorDoesNotPopulateAutomaticFolderScans() {
  let storage = StorageDiagnosticsCollector().currentStorage(now: Date())

  #expect(storage.metrics.allSatisfy { $0.dataMode == .live })
  #expect(storage.breakdown.allSatisfy { $0.dataMode == .live })
  #expect(storage.largeFolders.isEmpty)
  #expect(storage.largeFiles.isEmpty)
  #expect(storage.developerCaches.isEmpty)
  #expect(storage.browserCaches.isEmpty)
  #expect(storage.spaceOffenders.isEmpty)
  #expect(storage.sourceNote.contains("not scanned automatically"))
}

@Test func performanceHistoryIsUnavailableUntilEnoughSamples() {
  let tracker = PerformanceHistoryTracker()
  let summary = tracker.record(instant: instant(cpuProcesses: [process("Indexer", value: 40)]), now: Date())

  #expect(summary.hasEnoughSamples == false)
  #expect(summary.hasSustainedHighCPU == false)
  #expect(summary.recentSampleCount == 1)
}

@Test func performanceHistoryDetectsRepeatedHighCPU() {
  let tracker = PerformanceHistoryTracker()
  let start = Date()

  _ = tracker.record(instant: instant(cpuProcesses: [process("Indexer", value: 30)]), now: start)
  _ = tracker.record(instant: instant(cpuProcesses: [process("Indexer", value: 32)]), now: start.addingTimeInterval(10))
  let summary = tracker.record(instant: instant(cpuProcesses: [process("Indexer", value: 35)]), now: start.addingTimeInterval(20))

  #expect(summary.hasEnoughSamples)
  #expect(summary.hasSustainedHighCPU)
  #expect(summary.repeatedHighCPUProcesses == ["Indexer"])
}

@Test func performanceHistoryPrunesAfterRetentionWindow() {
  let tracker = PerformanceHistoryTracker()
  let start = Date()

  _ = tracker.record(instant: instant(cpuProcesses: [process("Old", value: 30)]), now: start)
  let summary = tracker.record(instant: instant(cpuProcesses: [process("New", value: 30)]), now: start.addingTimeInterval(130))

  #expect(summary.retainedSampleCount == 1)
  #expect(summary.repeatedHighCPUProcesses.isEmpty)
}

@Test func scoreConfidenceStaysLowWhenMockValuesRemain() {
  let metric = ScoreConfidenceCalculator.metric(modes: [.live, .live, .mock, .planned, .unavailable], now: Date())

  #expect(metric.value == "Low")
  #expect(metric.dataMode == .live)
  #expect(metric.explanation.contains("1 mock"))
}

@Test func scoreConfidenceCanRiseWhenMocksAreGone() {
  let medium = ScoreConfidenceCalculator.metric(modes: [.live, .live, .planned, .unavailable], now: Date())
  let high = ScoreConfidenceCalculator.metric(modes: [.live, .live, .live, .live, .unavailable], now: Date())

  #expect(medium.value == "Medium")
  #expect(high.value == "High")
}

@Test func startupCollectorReadsAccessiblePlistsOnly() throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-startup-\(UUID().uuidString)")
  let agents = root.appendingPathComponent("LaunchAgents")
  let daemons = root.appendingPathComponent("LaunchDaemons")
  try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
  try FileManager.default.createDirectory(at: daemons, withIntermediateDirectories: true)
  try writePlist(
    [
      "Label": "com.example.agent",
      "ProgramArguments": ["/usr/bin/example", "--flag"],
      "RunAtLoad": true,
      "KeepAlive": true
    ],
    to: agents.appendingPathComponent("com.example.agent.plist")
  )
  try "not a plist".write(to: daemons.appendingPathComponent("broken.plist"), atomically: true, encoding: .utf8)

  let startup = StartupDiagnosticsCollector(
    locations: [
      StartupScanLocation(kind: "Launch Agent", displayName: "Test Agents", url: agents),
      StartupScanLocation(kind: "Launch Daemon", displayName: "Test Daemons", url: daemons)
    ]
  ).currentStartup(now: Date())

  let agent = try #require(startup.launchAgents.first)

  #expect(startup.summary.dataMode == .live)
  #expect(startup.launchAgents.count == 1)
  #expect(startup.launchDaemons.isEmpty)
  #expect(agent.title == "com.example.agent")
  #expect(agent.dataMode == .live)
  #expect(agent.signedState == "Not checked")
  #expect(agent.explanation.contains("RunAtLoad: Yes"))
  #expect(startup.metrics.first { $0.title == "Login Items" }?.dataMode == .unavailable)
  #expect(startup.metrics.first { $0.title == "Background Items" }?.dataMode == .planned)
}

@Test func startupCollectorOmitsMissingDirectories() {
  let missing = FileManager.default.temporaryDirectory.appendingPathComponent("corewise-missing-\(UUID().uuidString)")
  let startup = StartupDiagnosticsCollector(
    locations: [
      StartupScanLocation(kind: "Launch Agent", displayName: "Missing", url: missing)
    ]
  ).currentStartup(now: Date())

  #expect(startup.launchAgents.isEmpty)
  #expect(startup.summary.dataMode == .live)
}

private func instant(cpuProcesses: [ProcessSample]) -> InstantSystemMetrics {
  InstantSystemMetrics(
    cpuPercent: 20,
    usedMemoryGB: 4,
    totalMemoryGB: 16,
    memoryPercent: 25,
    topCPUProcesses: cpuProcesses,
    topMemoryProcesses: [],
    systemWatts: nil,
    powerSourceNote: "Unavailable"
  )
}

private func process(_ name: String, value: Double) -> ProcessSample {
  ProcessSample(
    name: name,
    value: value,
    unit: "% CPU",
    dataMode: .live,
    status: .info,
    severityScore: Int(value),
    explanation: "Synthetic sample.",
    source: "Unit test",
    confidence: "Live / high",
    recommendedAction: "No action.",
    lastUpdated: Date()
  )
}

private func writePlist(_ dictionary: [String: Any], to url: URL) throws {
  let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
  try data.write(to: url)
}
