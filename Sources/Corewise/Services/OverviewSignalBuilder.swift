// SPDX-License-Identifier: MPL-2.0

import Foundation

enum OverviewSignalBuilder {
  static func signals(from metrics: [DiagnosticMetric]) -> [AttentionSignal] {
    let ranked = AttentionSummaryResolver.rankedSignals(metrics: metrics)
    let performance = ranked.first { $0.area == .performance }
    let storage = ranked.first { $0.area == .storage }
    let system = ranked.first { ![DiagnosticArea.performance, .storage].contains($0.area) }
    return [performance, storage, system].compactMap { $0 }
  }
}
