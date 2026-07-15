// SPDX-License-Identifier: MPL-2.0

import Foundation
import Testing
@testable import Corewise

@Test func dataModeLabelsAreStable() {
  #expect(DataMode.live.rawValue == "Live")
  #expect(DataMode.planned.rawValue == "Planned")
  #expect(DataMode.unavailable.rawValue == "Unavailable")
  #expect(DataMode.avoided.rawValue == "Avoided")
}

@Test func diagnosticMetricDefaultsToUnavailableDataMode() {
  let metric = DiagnosticMetric(
    title: "Example",
    value: "1",
    unit: "GB",
    status: .info,
    severityScore: 10,
    explanation: "Example metric.",
    source: "Unit test",
    confidence: "Unavailable / high",
    recommendedAction: "No action.",
    lastUpdated: Date()
  )

  #expect(metric.dataMode == .unavailable)
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
