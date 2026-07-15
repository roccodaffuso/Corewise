// SPDX-License-Identifier: MPL-2.0

import Foundation

enum DiagnosticArea: String, CaseIterable, Hashable, Sendable {
  case performance
  case storage
  case battery
  case thermal
  case startup
  case appIssues

  var title: String {
    switch self {
    case .performance: "Performance"
    case .storage: "Storage"
    case .battery: "Battery"
    case .thermal: "Thermal"
    case .startup: "Startup"
    case .appIssues: "App Issues"
    }
  }
}

enum DiagnosticMetricRole: String, CaseIterable, Hashable, Sendable {
  case cpuNow
  case memoryNow
  case sustainedCPU
  case swapTrend
  case storageHeadroom
  case batteryState
  case thermalState
  case startupLoad
  case appIssuePattern

  var area: DiagnosticArea {
    switch self {
    case .cpuNow, .memoryNow, .sustainedCPU, .swapTrend:
      .performance
    case .storageHeadroom:
      .storage
    case .batteryState:
      .battery
    case .thermalState:
      .thermal
    case .startupLoad:
      .startup
    case .appIssuePattern:
      .appIssues
    }
  }

  var priority: Int {
    switch self {
    case .sustainedCPU: 90
    case .swapTrend: 80
    case .storageHeadroom: 70
    case .thermalState: 60
    case .batteryState: 50
    case .appIssuePattern: 40
    case .startupLoad: 30
    case .cpuNow: 20
    case .memoryNow: 10
    }
  }
}

enum AttentionState: String, CaseIterable, Sendable {
  case clear
  case review
  case critical
  case unavailable

  var systemImage: String {
    switch self {
    case .clear: "checkmark.circle.fill"
    case .review: "exclamationmark.triangle.fill"
    case .critical: "exclamationmark.octagon.fill"
    case .unavailable: "questionmark.circle"
    }
  }
}

struct AttentionSignal: Identifiable, Equatable, Sendable {
  var id: DiagnosticMetricRole { role }
  var area: DiagnosticArea
  var role: DiagnosticMetricRole
  var title: String
  var value: String
  var unit: String
  var status: FindingSeverity
  var severityScore: Int
  var dataMode: DataMode
  var source: String
  var recommendedAction: String
  var lastUpdated: Date
}

struct AttentionSummary: Equatable, Sendable {
  var state: AttentionState
  var headline: String
  var detail: String
  var signals: [AttentionSignal]
  var recommendedAction: String
  var lastUpdated: Date?
  var reviewAreaCount: Int
}
