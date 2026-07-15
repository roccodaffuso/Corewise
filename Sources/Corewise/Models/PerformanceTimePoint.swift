// SPDX-License-Identifier: MPL-2.0

import Foundation

struct PerformanceTimePoint: Identifiable, Equatable, Sendable {
  var id: Date { timestamp }
  var timestamp: Date
  var cpuPercent: Double?
  var memoryUsedPercent: Double
  var swapUsedBytes: UInt64?
}
