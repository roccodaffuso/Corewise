import Foundation

enum ScoreConfidenceCalculator {
  static func metric(modes: [DataMode], now: Date) -> DiagnosticMetric {
    let total = max(modes.count, 1)
    let liveCount = modes.filter { $0 == .live }.count
    let mockCount = modes.filter { $0 == .mock }.count
    let plannedCount = modes.filter { $0 == .planned }.count
    let unavailableCount = modes.filter { $0 == .unavailable }.count
    let livePercent = Double(liveCount) / Double(total) * 100
    let label: String
    let status: FindingSeverity
    let severity: Int

    if mockCount > 0 {
      label = "Low"
      status = .info
      severity = 20
    } else if livePercent >= 80 {
      label = "High"
      status = .good
      severity = 8
    } else if livePercent >= 50 {
      label = "Medium"
      status = .info
      severity = 28
    } else {
      label = "Low"
      status = .info
      severity = 20
    }

    return DiagnosticMetric(
      title: "Score Confidence",
      value: label,
      unit: "",
      dataMode: .live,
      status: status,
      severityScore: severity,
      explanation: "\(liveCount) of \(total) diagnostic values are live; \(mockCount) mock, \(plannedCount) planned, \(unavailableCount) unavailable.",
      source: "DataMode coverage count",
      confidence: "Live calculation / high",
      recommendedAction: "Use section-level Live badges before trusting the global score.",
      lastUpdated: now
    )
  }
}
