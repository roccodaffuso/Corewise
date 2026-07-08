import Darwin
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
  let summary = tracker.record(instant: instant(processes: [process("Indexer", cpu: 40)]), now: Date())

  #expect(summary.hasEnoughSamples == false)
  #expect(summary.hasSustainedHighCPU == false)
  #expect(summary.recentSampleCount == 1)
}

@Test func performanceHistoryDetectsRepeatedHighCPU() {
  let tracker = PerformanceHistoryTracker()
  let start = Date()

  _ = tracker.record(instant: instant(processes: [process("Indexer", cpu: 30)]), now: start)
  _ = tracker.record(instant: instant(processes: [process("Indexer", cpu: 32)]), now: start.addingTimeInterval(10))
  let summary = tracker.record(instant: instant(processes: [process("Indexer", cpu: 35)]), now: start.addingTimeInterval(20))

  #expect(summary.hasEnoughSamples)
  #expect(summary.hasSustainedHighCPU)
  #expect(summary.repeatedHighCPUProcesses == ["Indexer"])
}

@Test func performanceHistoryPrunesAfterRetentionWindow() {
  let tracker = PerformanceHistoryTracker()
  let start = Date()

  _ = tracker.record(instant: instant(processes: [process("Old", cpu: 30)]), now: start)
  let summary = tracker.record(instant: instant(processes: [process("New", cpu: 30)]), now: start.addingTimeInterval(130))

  #expect(summary.retainedSampleCount == 1)
  #expect(summary.repeatedHighCPUProcesses.isEmpty)
}

@Test func processObservedMemoryDoesNotUnderreportResidentMemory() {
  let observation = process("Renderer", cpu: 1, residentMB: 800, footprintMB: 120)

  #expect(observation.observedMemoryBytes == 800 * 1024 * 1024)
}

@Test func appGroupObservedMemoryDoesNotUnderreportResidentMemory() {
  let group = AppProcessGroup(
    name: "Codex",
    processCount: 2,
    cpuPercent: 2,
    residentMemoryBytes: 1_200 * 1024 * 1024,
    physicalFootprintBytes: 300 * 1024 * 1024,
    dataMode: .live,
    status: .info,
    severityScore: 20,
    source: "Unit test",
    confidence: "Live / medium",
    lastUpdated: Date()
  )

  #expect(group.observedMemoryBytes == 1_200 * 1024 * 1024)
}

@Test func processCPUTicksAreConvertedWithMachTimebase() {
  var timebase = mach_timebase_info_data_t()
  let result = mach_timebase_info(&timebase)

  #expect(result == KERN_SUCCESS)
  #expect(SystemMetricsSampler.machTicksToNanoseconds(UInt64(timebase.denom) * 1_000_000) == UInt64(timebase.numer) * 1_000_000)
}

@Test func scoreConfidenceStaysLowWhenCoverageIsSparse() {
  let metric = ScoreConfidenceCalculator.metric(modes: [.live, .planned, .unavailable, .avoided], now: Date())

  #expect(metric.value == "Low")
  #expect(metric.dataMode == .live)
  #expect(metric.explanation.contains("1 avoided"))
}

@Test func scoreConfidenceCanRiseWhenLiveCoverageIsHigh() {
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

@Test func systemSnapshotContainsNoSyntheticRuntimeDiagnostics() async throws {
  let snapshot = try await SystemHealthCollector().currentSnapshot()
  let modes = allDataModes(in: snapshot)
  let overviewText = snapshot.overviewMetrics.map { "\($0.title) \($0.value) \($0.explanation)" }.joined(separator: " ")

  #expect(modes.allSatisfy { DataMode.allCases.contains($0) })
  #expect(snapshot.overallStatus == .notScored)
  #expect(snapshot.healthScore == 0)
  #expect(snapshot.appIssues.crashes.isEmpty)
  #expect(snapshot.appIssues.crashesByApp.isEmpty)
  #expect(!overviewText.contains("Health Score 74"))
  #expect(!snapshot.overviewMetrics.contains { $0.title == "Data Mode" })
  #expect(!overviewText.contains("Example" + "App"))
  #expect(!overviewText.contains("Photo" + "Tool"))
  #expect(!overviewText.contains("Helper" + "Service"))
}

private func instant(processes: [ProcessObservation]) -> InstantSystemMetrics {
  let now = Date()
  return InstantSystemMetrics(
    cpu: SystemCPUReading(
      totalPercent: 20,
      userPercent: 12,
      systemPercent: 8,
      idlePercent: 80,
      nicePercent: 0,
      dataMode: .live,
      source: "Unit test",
      confidence: "Live / high",
      lastUpdated: now
    ),
    memory: SystemMemoryReading(
      physicalBytes: 16 * 1024 * 1024 * 1024,
      usedBytes: 4 * 1024 * 1024 * 1024,
      freeBytes: 12 * 1024 * 1024 * 1024,
      appMemoryBytes: 2 * 1024 * 1024 * 1024,
      cachedFilesBytes: 1 * 1024 * 1024 * 1024,
      wiredBytes: 1 * 1024 * 1024 * 1024,
      compressedBytes: 512 * 1024 * 1024,
      swapUsedBytes: 0,
      dataMode: .live,
      source: "Unit test",
      confidence: "Live / high",
      lastUpdated: now
    ),
    processes: processes,
    appGroups: [],
    systemWatts: nil,
    powerSourceNote: "Unavailable"
  )
}

private func process(_ name: String, cpu: Double, residentMB: UInt64 = 128, footprintMB: UInt64 = 160) -> ProcessObservation {
  ProcessObservation(
    pid: Int32(abs(name.hashValue % 30_000) + 100),
    processName: name,
    displayName: name,
    appName: nil,
    path: nil,
    user: "tester",
    cpuPercent: cpu,
    cpuTimeSeconds: 10,
    threadCount: 4,
    residentMemoryBytes: residentMB * 1024 * 1024,
    physicalFootprintBytes: footprintMB * 1024 * 1024,
    dataMode: .live,
    status: .info,
    severityScore: Int(cpu),
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

private func allDataModes(in snapshot: HealthSnapshot) -> [DataMode] {
  snapshot.overviewMetrics.map(\.dataMode)
    + snapshot.dataAccess.map(\.dataMode)
    + snapshot.battery.metrics.map(\.dataMode)
    + snapshot.storage.metrics.map(\.dataMode)
    + snapshot.storage.breakdown.map(\.dataMode)
    + snapshot.storage.largeFolders.map(\.dataMode)
    + snapshot.storage.largeFiles.map(\.dataMode)
    + snapshot.storage.developerCaches.map(\.dataMode)
    + snapshot.storage.browserCaches.map(\.dataMode)
    + snapshot.storage.spaceOffenders.map(\.dataMode)
    + snapshot.performance.metrics.map(\.dataMode)
    + snapshot.performance.processes.map(\.dataMode)
    + snapshot.performance.appGroups.map(\.dataMode)
    + snapshot.startup.metrics.map(\.dataMode)
    + snapshot.startup.loginItems.map(\.dataMode)
    + snapshot.startup.launchAgents.map(\.dataMode)
    + snapshot.startup.launchDaemons.map(\.dataMode)
    + snapshot.startup.backgroundItems.map(\.dataMode)
    + snapshot.startup.privilegedHelpers.map(\.dataMode)
    + snapshot.thermal.metrics.map(\.dataMode)
    + snapshot.appIssues.metrics.map(\.dataMode)
    + snapshot.appIssues.crashes.map(\.dataMode)
    + snapshot.appIssues.crashesByApp.map(\.dataMode)
}
