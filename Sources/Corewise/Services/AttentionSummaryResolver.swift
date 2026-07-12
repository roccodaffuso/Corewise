import Foundation

enum AttentionSummaryResolver {
  static func resolve(metrics: [DiagnosticMetric]) -> AttentionSummary {
    let signals = rankedSignals(metrics: metrics)
    guard !signals.isEmpty else {
      return AttentionSummary(
        state: .unavailable,
        headline: "Live signals unavailable",
        detail: "Corewise does not have enough supported live signals for a current summary.",
        signals: [],
        recommendedAction: "Review individual sections for available data.",
        lastUpdated: nil,
        reviewAreaCount: 0
      )
    }

    let critical = signals.filter { $0.status == .critical }
    let warnings = signals.filter { $0.status == .warning }
    let reviewAreas = Set((critical + warnings).map(\.area))
    let state: AttentionState
    let headline: String
    let detail: String

    if !critical.isEmpty {
      state = .critical
      headline = critical.count == 1 ? "Critical live signal detected" : "Critical live signals detected"
      detail = areaDetail(reviewAreas, fallback: "A supported live signal needs prompt review.")
    } else if !warnings.isEmpty {
      state = .review
      headline = reviewAreas.count == 1 ? "1 area worth reviewing" : "\(reviewAreas.count) areas worth reviewing"
      detail = areaDetail(reviewAreas, fallback: "Supported live signals suggest a closer look.")
    } else {
      state = .clear
      headline = "No urgent live signals detected"
      detail = "Available live signals do not currently show urgent pressure. This is not a complete health diagnosis."
    }

    let rankedSignals = distinctAreasFirst(signals, limit: 3)
    let primary = critical.first ?? warnings.first
    return AttentionSummary(
      state: state,
      headline: headline,
      detail: detail,
      signals: rankedSignals,
      recommendedAction: primary?.recommendedAction ?? "No action needed right now.",
      lastUpdated: signals.map(\.lastUpdated).max(),
      reviewAreaCount: reviewAreas.count
    )
  }

  static func rankedSignals(metrics: [DiagnosticMetric]) -> [AttentionSignal] {
    metrics.compactMap(signal).sorted(by: precedes)
  }

  private static func signal(_ metric: DiagnosticMetric) -> AttentionSignal? {
    guard metric.dataMode == .live, let role = metric.role else {
      return nil
    }

    return AttentionSignal(
      area: role.area,
      role: role,
      title: metric.title,
      value: metric.value,
      unit: metric.unit,
      status: metric.status,
      severityScore: metric.severityScore,
      dataMode: metric.dataMode,
      source: metric.source,
      recommendedAction: metric.recommendedAction,
      lastUpdated: metric.lastUpdated
    )
  }

  private static func precedes(_ lhs: AttentionSignal, _ rhs: AttentionSignal) -> Bool {
    let leftSeverity = severityRank(lhs.status)
    let rightSeverity = severityRank(rhs.status)
    if leftSeverity != rightSeverity {
      return leftSeverity > rightSeverity
    }
    if lhs.severityScore != rhs.severityScore {
      return lhs.severityScore > rhs.severityScore
    }
    return lhs.role.priority > rhs.role.priority
  }

  private static func severityRank(_ severity: FindingSeverity) -> Int {
    switch severity {
    case .critical: 4
    case .warning: 3
    case .info: 2
    case .good: 1
    }
  }

  private static func distinctAreasFirst(_ signals: [AttentionSignal], limit: Int) -> [AttentionSignal] {
    var seen = Set<DiagnosticArea>()
    var result: [AttentionSignal] = []

    for signal in signals where !seen.contains(signal.area) {
      seen.insert(signal.area)
      result.append(signal)
      if result.count == limit {
        return result
      }
    }

    for signal in signals where !result.contains(where: { $0.id == signal.id }) {
      result.append(signal)
      if result.count == limit {
        break
      }
    }
    return result
  }

  private static func areaDetail(_ areas: Set<DiagnosticArea>, fallback: String) -> String {
    let names = DiagnosticArea.allCases.filter(areas.contains).map(\.title)
    guard !names.isEmpty else {
      return fallback
    }
    return "Review \(names.formatted(.list(type: .and)))."
  }
}
