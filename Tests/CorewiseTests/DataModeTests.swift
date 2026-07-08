import Foundation
import Testing
@testable import Corewise

@Test func dataModeLabelsAreStable() {
  #expect(DataMode.live.rawValue == "Live")
  #expect(DataMode.mock.rawValue == "Mock")
  #expect(DataMode.planned.rawValue == "Planned")
  #expect(DataMode.unavailable.rawValue == "Unavailable")
}

@Test func diagnosticMetricDefaultsToMockDataMode() {
  let metric = DiagnosticMetric(
    title: "Example",
    value: "1",
    unit: "GB",
    status: .info,
    severityScore: 10,
    explanation: "Example metric.",
    source: "Unit test",
    confidence: "Mock / high",
    recommendedAction: "No action.",
    lastUpdated: Date()
  )

  #expect(metric.dataMode == .mock)
}

@Test func storageCollectorReturnsLiveVolumeMetrics() {
  let storage = StorageDiagnosticsCollector().currentStorage(now: Date())

  #expect(storage.summary.dataMode == .live)
  #expect(storage.metrics.allSatisfy { $0.dataMode == .live })
  #expect(storage.totalGB >= 0)
  #expect(storage.availableGB >= 0)
  #expect(storage.usedGB >= 0)
  #expect(storage.breakdown.allSatisfy { $0.dataMode == .live })
}
