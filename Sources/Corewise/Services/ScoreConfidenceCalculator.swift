import Foundation

enum ScoreConfidenceCalculator {
  static func metric(modes: [DataMode], now: Date) -> DiagnosticMetric {
    metric(summary: DataCoverageSummary(modes: modes), now: now)
  }

  static func metric(summary: DataCoverageSummary, now: Date) -> DiagnosticMetric {
    let livePercent = summary.livePercent
    let label: String
    let status: FindingSeverity
    let severity: Int

    if livePercent >= 80 {
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
      explanation: "\(summary.live) of \(max(summary.total, 1)) diagnostic signal families are live; \(summary.planned) planned, \(summary.unavailable) unavailable, \(summary.avoided) avoided.",
      source: "DataMode signal family coverage",
      confidence: "Live calculation / high",
      recommendedAction: "Use section-level Live badges before trusting the global score.",
      lastUpdated: now
    )
  }
}
