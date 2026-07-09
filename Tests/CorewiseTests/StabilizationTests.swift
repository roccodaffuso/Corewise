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

@Test func swapInsightTrendIsUnavailableWithOneSample() {
  let start = Date()
  let sample = PerformanceHistorySample(
    timestamp: start,
    cpuPercent: 20,
    memoryUsedPercent: 50,
    swap: swap(usedMB: 1_024, swapIns: 10, swapOuts: 20),
    processes: [process("Renderer", cpu: 1, residentMB: 700, footprintMB: 900, pageIns: 42)]
  )

  let insight = SwapInsightCalculator.insight(samples: [sample], now: start)

  #expect(insight.trend == .unavailable)
  #expect(insight.swapInRateBytesPerSecond == nil)
  #expect(insight.swapOutRateBytesPerSecond == nil)
  #expect(insight.reading?.usedBytes == 1_024 * 1024 * 1024)
}

@Test func swapInsightDetectsRisingStableAndFallingTrends() {
  let start = Date()
  let rising = SwapInsightCalculator.insight(
    samples: [
      historySample(at: start, swap: swap(usedMB: 1_000, swapOuts: 0)),
      historySample(at: start.addingTimeInterval(60), swap: swap(usedMB: 1_300, swapOuts: 10))
    ],
    now: start.addingTimeInterval(60)
  )
  let stable = SwapInsightCalculator.insight(
    samples: [
      historySample(at: start, swap: swap(usedMB: 1_000, swapOuts: 0)),
      historySample(at: start.addingTimeInterval(60), swap: swap(usedMB: 1_100, swapOuts: 10))
    ],
    now: start.addingTimeInterval(60)
  )
  let falling = SwapInsightCalculator.insight(
    samples: [
      historySample(at: start, swap: swap(usedMB: 1_400, swapOuts: 10)),
      historySample(at: start.addingTimeInterval(60), swap: swap(usedMB: 1_000, swapOuts: 10))
    ],
    now: start.addingTimeInterval(60)
  )

  #expect(rising.trend == .rising)
  #expect(stable.trend == .stable)
  #expect(falling.trend == .falling)
}

@Test func swapInsightCalculatesRatesFromPageDeltas() throws {
  let start = Date()
  let pageSize = UInt64(4_096)
  let insight = SwapInsightCalculator.insight(
    samples: [
      historySample(at: start, swap: swap(pageSize: pageSize, swapIns: 10, swapOuts: 20)),
      historySample(at: start.addingTimeInterval(10), swap: swap(pageSize: pageSize, swapIns: 20, swapOuts: 50))
    ],
    now: start.addingTimeInterval(10)
  )

  #expect(try #require(insight.swapInRateBytesPerSecond) == Double(10 * pageSize) / 10)
  #expect(try #require(insight.swapOutRateBytesPerSecond) == Double(30 * pageSize) / 10)
}

@Test func swapInsightRanksLikelyContributorsWithoutOwnershipClaim() throws {
  let start = Date()
  let previous = historySample(
    at: start,
    swap: swap(usedMB: 1_000),
    processes: [
      process("Small", cpu: 1, residentMB: 200, footprintMB: 220, pageIns: 1),
      process("Grew", cpu: 1, residentMB: 300, footprintMB: 300, pageIns: 10)
    ]
  )
  let latest = historySample(
    at: start.addingTimeInterval(30),
    swap: swap(usedMB: 1_200),
    processes: [
      process("Small", cpu: 1, residentMB: 210, footprintMB: 230, pageIns: 1),
      process("Grew", cpu: 1, residentMB: 900, footprintMB: 1_000, pageIns: 80)
    ]
  )

  let insight = SwapInsightCalculator.insight(samples: [previous, latest], now: latest.timestamp)

  #expect(try #require(insight.contributors.first).processName == "Grew")
  #expect(insight.explanation.contains("does not expose exact per-process swap ownership"))
}

@Test func swapUsedBytesComputedCompatibilityUsesSwapReading() {
  let memory = memoryReading(swap: swap(usedMB: 768))

  #expect(memory.swapUsedBytes == 768 * 1024 * 1024)
  #expect(memory.swapUsedGB == 0.75)
}

@Test func swapInsightHandlesMissingSwapAsUnavailable() {
  let insight = SwapInsightCalculator.insight(
    samples: [historySample(at: Date(), swap: nil)],
    now: Date()
  )

  #expect(insight.dataMode == .unavailable)
  #expect(insight.reading == nil)
  #expect(insight.contributors.isEmpty)
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

@Test func processInsightsExplainLivePatternsWithoutCausalClaims() {
  let processes = [
    process("Google Chrome Helper (Renderer)", cpu: 3, appName: "Google Chrome"),
    process("WindowServer", cpu: 8, path: "/System/Library/PrivateFrameworks/SkyLight.framework/WindowServer"),
    process("mdworker_shared", cpu: 2),
    process("fileproviderd", cpu: 2, path: "/System/Library/Frameworks/FileProvider.framework/Support/fileproviderd"),
    process("Corewise", cpu: 1)
  ]

  let insights = ProcessInsightBuilder().insights(for: processes)
  let titles = insights.map(\.title)

  #expect(titles.contains("Helpers belong to apps"))
  #expect(titles.contains("WindowServer is display work"))
  #expect(titles.contains("Spotlight may be indexing"))
  #expect(titles.contains("Cloud sync can be visible"))
  #expect(titles.contains("Corewise includes itself"))
  #expect(insights.allSatisfy { $0.dataMode == .live })
  #expect(!insights.map(\.detail).joined(separator: " ").localizedCaseInsensitiveContains("kill"))
}

@Test func dataCoverageSummaryCountsModes() {
  let summary = DataCoverageSummary(modes: [.live, .live, .planned, .unavailable, .avoided])

  #expect(summary.live == 2)
  #expect(summary.planned == 1)
  #expect(summary.unavailable == 1)
  #expect(summary.avoided == 1)
  #expect(summary.total == 5)
  #expect(summary.livePercent == 40)
}

@Test func dataCoverageSummaryHandlesEmptyInput() {
  let summary = DataCoverageSummary(modes: [])

  #expect(summary.total == 0)
  #expect(summary.livePercent == 0)
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
  #expect(snapshot.coverageSummary.total > 0)
  #expect(snapshot.coverageSummary.live > 0)
  #expect(snapshot.coverageSummary.total < 80)
  #expect(snapshot.appIssues.crashes.isEmpty)
  #expect(snapshot.appIssues.crashesByApp.isEmpty)
  #expect(!overviewText.contains("Health Score 74"))
  #expect(!overviewText.contains("Not Scored Yet"))
  #expect(snapshot.overviewMetrics.first { $0.title == "Global Score" }?.value == "Planned")
  #expect(!snapshot.overviewMetrics.contains { $0.title == "Data Mode" })
  #expect(!overviewText.contains("Example" + "App"))
  #expect(!overviewText.contains("Photo" + "Tool"))
  #expect(!overviewText.contains("Helper" + "Service"))
}

@Test func diagnosticReportUsesSafeSnapshotSummary() async throws {
  let snapshot = try await SystemHealthCollector().currentSnapshot()
  let builder = DiagnosticReportBuilder()
  let summary = builder.summary(for: snapshot)
  let report = builder.markdown(for: snapshot)

  #expect(summary.contains("Corewise Diagnostic Summary"))
  #expect(summary.contains("Notable findings"))
  #expect(summary.contains("Manual next steps"))
  #expect(report.contains("Corewise Diagnostic Report"))
  #expect(report.contains("## Summary"))
  #expect(report.contains("## Performance"))
  #expect(report.contains("## Storage"))
  #expect(report.contains("## Battery"))
  #expect(report.contains("## Thermal"))
  #expect(report.contains("## Startup"))
  #expect(report.contains("## App Issues"))
  #expect(report.contains("## Limits"))
  #expect(report.contains("Global score is planned"))
  #expect(report.contains("Source:"))
  #expect(report.contains("Confidence:"))
  #expect(!summary.localizedCaseInsensitiveContains("Thread 0 Crashed"))
  #expect(!summary.localizedCaseInsensitiveContains("Binary Images"))
  #expect(!report.localizedCaseInsensitiveContains("Thread 0 Crashed"))
  #expect(!report.localizedCaseInsensitiveContains("Binary Images"))
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
    memory: memoryReading(swap: swap(usedMB: 0, now: now), now: now),
    processes: processes,
    appGroups: [],
    systemWatts: nil,
    powerSourceNote: "Unavailable"
  )
}

private func historySample(
  at timestamp: Date,
  swap: SwapReading?,
  processes: [ProcessObservation] = []
) -> PerformanceHistorySample {
  PerformanceHistorySample(
    timestamp: timestamp,
    cpuPercent: 20,
    memoryUsedPercent: 50,
    swap: swap,
    processes: processes
  )
}

private func memoryReading(swap: SwapReading?, now: Date = Date()) -> SystemMemoryReading {
  SystemMemoryReading(
    physicalBytes: 16 * 1024 * 1024 * 1024,
    usedBytes: 4 * 1024 * 1024 * 1024,
    freeBytes: 12 * 1024 * 1024 * 1024,
    appMemoryBytes: 2 * 1024 * 1024 * 1024,
    cachedFilesBytes: 1 * 1024 * 1024 * 1024,
    wiredBytes: 1 * 1024 * 1024 * 1024,
    compressedBytes: 512 * 1024 * 1024,
    swap: swap,
    dataMode: .live,
    source: "Unit test",
    confidence: "Live / high",
    lastUpdated: now
  )
}

private func swap(
  usedMB: UInt64 = 512,
  totalMB: UInt64 = 4_096,
  availableMB: UInt64 = 3_584,
  pageSize: UInt64 = 4_096,
  swapIns: UInt64 = 0,
  swapOuts: UInt64 = 0,
  swappedMB: UInt64 = 0,
  now: Date = Date()
) -> SwapReading {
  SwapReading(
    usedBytes: usedMB * 1024 * 1024,
    totalBytes: totalMB * 1024 * 1024,
    availableBytes: availableMB * 1024 * 1024,
    pageSize: pageSize,
    isEncrypted: true,
    swappedBytes: swappedMB * 1024 * 1024,
    swapIns: swapIns,
    swapOuts: swapOuts,
    dataMode: .live,
    source: "Unit test",
    confidence: "Live / medium",
    lastUpdated: now
  )
}

private func process(
  _ name: String,
  cpu: Double,
  residentMB: UInt64 = 128,
  footprintMB: UInt64 = 160,
  pageIns: UInt64 = 0,
  appName: String? = nil,
  path: String? = nil
) -> ProcessObservation {
  ProcessObservation(
    pid: Int32(abs(name.hashValue % 30_000) + 100),
    processName: name,
    displayName: name,
    appName: appName,
    path: path,
    user: "tester",
    cpuPercent: cpu,
    cpuTimeSeconds: 10,
    threadCount: 4,
    residentMemoryBytes: residentMB * 1024 * 1024,
    physicalFootprintBytes: footprintMB * 1024 * 1024,
    pageIns: pageIns,
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
    + snapshot.performance.insights.map(\.dataMode)
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
