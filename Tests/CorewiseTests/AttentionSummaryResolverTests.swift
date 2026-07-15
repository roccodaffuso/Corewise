// SPDX-License-Identifier: MPL-2.0

import Foundation
import Testing
@testable import Corewise

@Test func attentionSummaryIsUnavailableWithoutSupportedLiveSignals() {
  let summary = AttentionSummaryResolver.resolve(
    metrics: [attentionMetric(role: .storageHeadroom, mode: .planned, status: .critical)]
  )

  #expect(summary.state == .unavailable)
  #expect(summary.signals.isEmpty)
  #expect(summary.reviewAreaCount == 0)
}

@Test func attentionSummaryDoesNotTurnClearSignalsIntoAHealthDiagnosis() {
  let summary = AttentionSummaryResolver.resolve(
    metrics: [
      attentionMetric(role: .cpuNow, status: .good),
      attentionMetric(role: .storageHeadroom, status: .good)
    ]
  )

  #expect(summary.state == .clear)
  #expect(summary.headline == "No urgent live signals detected")
  #expect(summary.detail.contains("not a complete health diagnosis"))
}

@Test func attentionSummaryCountsAreasAndUsesHighestPriorityAction() {
  let summary = AttentionSummaryResolver.resolve(
    metrics: [
      attentionMetric(role: .cpuNow, status: .warning, severity: 70, action: "Review CPU"),
      attentionMetric(role: .sustainedCPU, status: .warning, severity: 80, action: "Review sustained work"),
      attentionMetric(role: .storageHeadroom, status: .warning, severity: 60, action: "Review storage")
    ]
  )

  #expect(summary.state == .review)
  #expect(summary.reviewAreaCount == 2)
  #expect(summary.recommendedAction == "Review sustained work")
  #expect(summary.signals.prefix(2).map(\.area) == [.performance, .storage])
}

@Test func criticalSignalRanksAheadOfWarnings() throws {
  let summary = AttentionSummaryResolver.resolve(
    metrics: [
      attentionMetric(role: .storageHeadroom, status: .warning, severity: 99),
      attentionMetric(role: .thermalState, status: .critical, severity: 70)
    ]
  )

  #expect(summary.state == .critical)
  #expect(try #require(summary.signals.first).role == .thermalState)
}

@Test func overviewSignalBuilderSelectsPerformanceStorageAndOneSystemSignal() {
  let result = OverviewSignalBuilder.signals(
    from: [
      attentionMetric(role: .cpuNow, status: .good),
      attentionMetric(role: .storageHeadroom, status: .warning, severity: 60),
      attentionMetric(role: .startupLoad, status: .warning, severity: 70),
      attentionMetric(role: .thermalState, status: .good)
    ]
  )

  #expect(result.map(\.area) == [.performance, .storage, .startup])
}

@Test func thermalCoincidenceAppearsOnlyForElevatedStateWithSustainedCPU() {
  let nominal = ThermalContributorResolver.contributors(stateLabel: "Nominal", status: .good, severityScore: 0, hasSustainedCPU: true)
  let elevatedWithoutCPU = ThermalContributorResolver.contributors(stateLabel: "Serious", status: .warning, severityScore: 60, hasSustainedCPU: false)
  let coincident = ThermalContributorResolver.contributors(stateLabel: "Serious", status: .warning, severityScore: 60, hasSustainedCPU: true)

  #expect(!nominal.contains { $0.title == "Coincident sustained CPU activity" })
  #expect(!elevatedWithoutCPU.contains { $0.title == "Coincident sustained CPU activity" })
  #expect(coincident.contains { $0.title == "Coincident sustained CPU activity" })
}

@Test func performanceHistoryExposesOnlySixtyOrderedPoints() {
  let tracker = PerformanceHistoryTracker(retentionSeconds: 1_000, maximumVisiblePoints: 60)
  let start = Date()
  var summary: PerformanceHistorySummary?

  for offset in 0..<75 {
    summary = tracker.record(instant: instantForHistory(cpu: Double(offset)), now: start.addingTimeInterval(Double(offset)))
  }

  #expect(summary?.recentPoints.count == 60)
  #expect(summary?.retainedSampleCount == 60)
  #expect(summary?.recentPoints.first?.cpuPercent == 15)
  #expect(summary?.recentPoints.last?.cpuPercent == 74)
  #expect(summary?.recentPoints == summary?.recentPoints.sorted { $0.timestamp < $1.timestamp })
}

private func attentionMetric(
  role: DiagnosticMetricRole,
  mode: DataMode = .live,
  status: FindingSeverity,
  severity: Int = 10,
  action: String = "No action"
) -> DiagnosticMetric {
  DiagnosticMetric(
    title: role.rawValue,
    value: "1",
    unit: "%",
    role: role,
    dataMode: mode,
    status: status,
    severityScore: severity,
    explanation: "Unit test",
    source: "Unit test",
    confidence: "Live / high",
    recommendedAction: action,
    lastUpdated: .now
  )
}

private func instantForHistory(cpu: Double) -> InstantSystemMetrics {
  let now = Date()
  return InstantSystemMetrics(
    cpu: SystemCPUReading(
      totalPercent: cpu,
      userPercent: cpu,
      systemPercent: 0,
      idlePercent: max(100 - cpu, 0),
      nicePercent: 0,
      dataMode: .live,
      source: "Unit test",
      confidence: "Live / high",
      lastUpdated: now
    ),
    memory: SystemMemoryReading(
      physicalBytes: 16 * 1024 * 1024 * 1024,
      usedBytes: 8 * 1024 * 1024 * 1024,
      freeBytes: 8 * 1024 * 1024 * 1024,
      appMemoryBytes: 4 * 1024 * 1024 * 1024,
      cachedFilesBytes: 2 * 1024 * 1024 * 1024,
      wiredBytes: 1 * 1024 * 1024 * 1024,
      compressedBytes: 1 * 1024 * 1024 * 1024,
      swap: nil,
      dataMode: .live,
      source: "Unit test",
      confidence: "Live / high",
      lastUpdated: now
    ),
    processes: [],
    appGroups: [],
    powerSourceNote: "Unavailable"
  )
}
