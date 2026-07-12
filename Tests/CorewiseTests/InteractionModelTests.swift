import Foundation
import Testing
@testable import Corewise

@Test func quickActionsUseLocalizedStandardFiltering() {
  let refresh = QuickActionDescriptor.all.first { $0.id == .refresh }
  let storage = QuickActionDescriptor.all.first { $0.id == .enableFullStorageAnalysis }

  #expect(refresh?.matches("reload") == true)
  #expect(storage?.matches("SCAN") == true)
  #expect(storage?.title == "Enable Full Storage Analysis")
  #expect(QuickActionDescriptor.all.contains { $0.title == "Scan a Folder" } == false)
  #expect(storage?.matches("unrelated") == false)
}

@Test @MainActor func appRouteStorePublishesAndConsumesTypedRoutes() {
  let store = AppRouteStore()

  store.show(.performance, performanceMode: .memory)
  #expect(store.requestedRoute == DashboardRoute(section: .performance, performanceMode: .memory))
  store.consume()
  #expect(store.requestedRoute == nil)
}

@Test func processTablePresenterFiltersAndSortsWithoutChangingSource() {
  let source = [
    tableProcess(name: "Renderer", cpu: 12, memoryMB: 900),
    tableProcess(name: "Compiler", cpu: 70, memoryMB: 300)
  ]

  #expect(ProcessTablePresenter.filtered(source, query: "render").map(\.displayName) == ["Renderer"])
  #expect(ProcessTablePresenter.sorted(source, by: .cpu).map(\.displayName) == ["Compiler", "Renderer"])
  #expect(ProcessTablePresenter.sorted(source, by: .memory).map(\.displayName) == ["Renderer", "Compiler"])
  #expect(source.map(\.displayName) == ["Renderer", "Compiler"])
}

@Test func processTablePresenterBuildsDifferentCPUAndMemoryWorksets() {
  let source = [
    tableProcess(name: "CPU Worker", cpu: 80, memoryMB: 5),
    tableProcess(name: "Memory Cache", cpu: 0, memoryMB: 900),
    tableProcess(name: "Mixed App", cpu: 12, memoryMB: 300)
  ]

  let cpuRows = ProcessTablePresenter.presented(source, mode: .cpu, query: "", sort: .cpu)
  let memoryRows = ProcessTablePresenter.presented(source, mode: .memory, query: "", sort: .memory)

  #expect(cpuRows.map(\.displayName) == ["CPU Worker", "Mixed App"])
  #expect(memoryRows.map(\.displayName) == ["Memory Cache", "Mixed App"])
  #expect(ProcessTablePresenter.availableSorts(for: .cpu) == [.cpu, .cpuTime, .threads, .name])
  #expect(ProcessTablePresenter.availableSorts(for: .memory) == [.memory, .footprint, .resident, .pageIns, .name])
}

@Test func performanceChartAccessibilitySummaryIncludesPeriodValuesMaximumAndTrend() {
  let start = Date(timeIntervalSince1970: 1_000)
  let points = [
    PerformanceTimePoint(timestamp: start, cpuPercent: 12, memoryUsedPercent: 40, swapUsedBytes: nil),
    PerformanceTimePoint(timestamp: start.addingTimeInterval(60), cpuPercent: 35, memoryUsedPercent: 40.2, swapUsedBytes: nil)
  ]

  let cpu = performanceChartAccessibilityValue(points: points, mode: .cpu)
  let memory = performanceChartAccessibilityValue(points: points, mode: .memory)

  #expect(cpu.contains("2 points"))
  #expect(cpu.contains("12"))
  #expect(cpu.contains("35"))
  #expect(cpu.contains("rising trend"))
  #expect(memory.contains("stable trend"))
  #expect(performanceChartAccessibilityValue(points: [], mode: .cpu).contains("Collecting"))
}

@Test func targetedStorageScanEmitsTruthfulStartAndFinalProgress() throws {
  let root = FileManager.default.temporaryDirectory.appending(path: "corewise-progress-\(UUID().uuidString)")
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: root) }
  try Data(repeating: 1, count: 32).write(to: root.appending(path: "one.bin"))
  try Data(repeating: 2, count: 64).write(to: root.appending(path: "two.bin"))
  let recorder = ProgressRecorder()

  _ = StorageTargetedScanCollector().scan(root: root) { progress in
    recorder.append(progress)
  }

  let progress = recorder.values
  #expect(progress.first?.scannedFiles == 0)
  #expect(progress.last?.scannedFiles == 2)
  #expect(progress.last?.scopeLabel == "Scope 1 of 1")
  #expect(progress.allSatisfy { $0.scopeCount == 1 })
}

@Test func storageScanPhaseKeepsProgressAndFailureExplicit() {
  let progress = StorageScanProgress(currentScope: "Downloads", scopeIndex: 2, scopeCount: 4, scannedFiles: 12, scannedFolders: 3, unreadableCount: 1, elapsed: 2)

  #expect(StorageScanPhase.scanning(progress) == .scanning(progress))
  #expect(StorageScanPhase.failed("Denied") == .failed("Denied"))
  #expect(progress.scopeLabel == "Scope 2 of 4")
}

private final class ProgressRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [StorageScanProgress] = []

  var values: [StorageScanProgress] {
    lock.withLock { storage }
  }

  func append(_ progress: StorageScanProgress) {
    lock.withLock { storage.append(progress) }
  }
}

private func tableProcess(name: String, cpu: Double, memoryMB: UInt64) -> ProcessObservation {
  let now = Date()
  return ProcessObservation(
    pid: Int32(cpu),
    processName: name,
    displayName: name,
    appName: name,
    path: "/Applications/\(name).app",
    user: "tester",
    cpuPercent: cpu,
    cpuTimeSeconds: cpu,
    threadCount: 4,
    residentMemoryBytes: memoryMB * 1024 * 1024,
    physicalFootprintBytes: memoryMB * 1024 * 1024,
    pageIns: 0,
    dataMode: .live,
    status: .info,
    severityScore: Int(cpu),
    explanation: "Unit test",
    source: "Unit test",
    confidence: "Live / high",
    recommendedAction: "None",
    lastUpdated: now
  )
}
