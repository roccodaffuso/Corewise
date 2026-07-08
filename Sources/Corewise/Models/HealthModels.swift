import Foundation

enum OverallStatus: String, CaseIterable {
  case notScored = "Not Scored Yet"
  case good = "Good"
  case needsAttention = "Needs Attention"
  case critical = "Critical"

  var summary: String {
    switch self {
    case .notScored:
      "Corewise has not calculated a health score yet."
    case .good:
      "Your Mac looks healthy."
    case .needsAttention:
      "A few areas deserve attention."
    case .critical:
      "Important issues need review."
    }
  }

  var systemImage: String {
    switch self {
    case .notScored:
      "gauge.with.dots.needle.bottom.0percent"
    case .good:
      "checkmark.seal.fill"
    case .needsAttention:
      "exclamationmark.triangle.fill"
    case .critical:
      "xmark.octagon.fill"
    }
  }
}

enum FindingSeverity: String, CaseIterable {
  case good = "Good"
  case info = "Info"
  case warning = "Warning"
  case critical = "Critical"
}

enum DataMode: String, CaseIterable {
  case live = "Live"
  case planned = "Planned"
  case unavailable = "Unavailable"
  case avoided = "Avoided"
}

struct HealthSnapshot {
  var generatedAt: Date
  var healthScore: Int
  var overallStatus: OverallStatus
  var overviewMetrics: [DiagnosticMetric]
  var battery: BatteryHealth
  var storage: StorageHealth
  var performance: PerformanceHealth
  var startup: StartupHealth
  var thermal: ThermalHealth
  var appIssues: AppIssuesHealth
  var suggestions: [Suggestion]
}

struct DiagnosticMetric: Identifiable {
  let id = UUID()
  var title: String
  var value: String
  var unit: String
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var source: String
  var confidence: String
  var recommendedAction: String
  var lastUpdated: Date
}

struct DiagnosticFinding: Identifiable {
  let id = UUID()
  var title: String
  var detail: String
  var status: FindingSeverity
  var severityScore: Int
}

struct SafeAction: Identifiable {
  let id = UUID()
  var title: String
  var body: String
  var systemImage: String
  var status: FindingSeverity
}

struct ChartDatum: Identifiable {
  let id = UUID()
  var title: String
  var value: Double
  var unit: String
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var detail: String
}

struct BatteryHealth {
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct StorageHealth {
  var summary: DiagnosticMetric
  var totalGB: Double
  var availableGB: Double
  var usedGB: Double
  var availablePercent: Double
  var metrics: [DiagnosticMetric]
  var breakdown: [ChartDatum]
  var largeFolders: [StorageItem]
  var largeFiles: [StorageItem]
  var developerCaches: [StorageItem]
  var browserCaches: [StorageItem]
  var spaceOffenders: [ChartDatum]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct StorageItem: Identifiable {
  let id = UUID()
  var title: String
  var path: String
  var sizeGB: Double
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var source: String
  var confidence: String
  var recommendedAction: String
  var lastUpdated: Date
}

struct PerformanceHealth {
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var cpuProcesses: [ProcessSample]
  var memoryProcesses: [ProcessSample]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct ProcessSample: Identifiable {
  let id = UUID()
  var name: String
  var value: Double
  var unit: String
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var source: String
  var confidence: String
  var recommendedAction: String
  var lastUpdated: Date
}

struct StartupHealth {
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var loginItems: [StartupItem]
  var launchAgents: [StartupItem]
  var launchDaemons: [StartupItem]
  var backgroundItems: [StartupItem]
  var privilegedHelpers: [StartupItem]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct StartupItem: Identifiable {
  let id = UUID()
  var title: String
  var kind: String
  var path: String
  var startupImpact: String
  var signedState: String
  var recentlyAdded: Bool
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var source: String
  var confidence: String
  var recommendedAction: String
  var lastUpdated: Date
}

struct ThermalHealth {
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var contributors: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct AppIssuesHealth {
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var crashes: [CrashIssue]
  var crashesByApp: [ChartDatum]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct CrashIssue: Identifiable {
  let id = UUID()
  var appName: String
  var bundleID: String
  var appVersion: String
  var crashesLast7Days: Int
  var crashesLast30Days: Int
  var lastCrashDate: Date
  var repeatedCrash: Bool
  var diagnosticPermissionState: String
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var source: String
  var confidence: String
  var recommendedAction: String
}

struct Suggestion: Identifiable {
  let id = UUID()
  var title: String
  var body: String
  var severity: FindingSeverity
}
