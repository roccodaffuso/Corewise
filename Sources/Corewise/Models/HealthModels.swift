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
  var dataAccess: [DataAccessCapability]
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

struct DataAccessCapability: Identifiable {
  let id = UUID()
  var title: String
  var dataMode: DataMode
  var source: String
  var reason: String
  var actionLabel: String?
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

struct StorageScanResult {
  var rootTitle: String
  var rootPath: String
  var totalSizeGB: Double
  var scannedItemCount: Int
  var inaccessibleItemCount: Int
  var scanDuration: TimeInterval
  var largestItems: [StorageItem]
  var largestFiles: [StorageItem]
  var largestFolders: [StorageItem]
  var chartData: [ChartDatum]
  var lastUpdated: Date
}

struct PerformanceHealth {
  var summary: DiagnosticMetric
  var cpu: SystemCPUReading
  var memory: SystemMemoryReading
  var metrics: [DiagnosticMetric]
  var processes: [ProcessObservation]
  var appGroups: [AppProcessGroup]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct SystemCPUReading {
  var totalPercent: Double?
  var userPercent: Double?
  var systemPercent: Double?
  var idlePercent: Double?
  var nicePercent: Double?
  var dataMode: DataMode = .unavailable
  var source: String
  var confidence: String
  var lastUpdated: Date
}

struct SystemMemoryReading {
  var physicalBytes: UInt64
  var usedBytes: UInt64
  var freeBytes: UInt64
  var appMemoryBytes: UInt64
  var cachedFilesBytes: UInt64
  var wiredBytes: UInt64
  var compressedBytes: UInt64
  var swapUsedBytes: UInt64?
  var dataMode: DataMode = .unavailable
  var source: String
  var confidence: String
  var lastUpdated: Date
}

struct ProcessObservation: Identifiable {
  var id: Int32 { pid }
  var pid: Int32
  var processName: String
  var displayName: String
  var appName: String?
  var path: String?
  var user: String
  var cpuPercent: Double
  var cpuTimeSeconds: Double
  var threadCount: Int32
  var residentMemoryBytes: UInt64
  var physicalFootprintBytes: UInt64?
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var explanation: String
  var source: String
  var confidence: String
  var recommendedAction: String
  var lastUpdated: Date
}

extension ProcessObservation {
  var observedMemoryBytes: UInt64 {
    max(physicalFootprintBytes ?? 0, residentMemoryBytes)
  }
}

struct AppProcessGroup: Identifiable {
  var id: String { name }
  var name: String
  var processCount: Int
  var cpuPercent: Double
  var residentMemoryBytes: UInt64
  var physicalFootprintBytes: UInt64?
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var severityScore: Int
  var source: String
  var confidence: String
  var lastUpdated: Date
}

extension AppProcessGroup {
  var observedMemoryBytes: UInt64 {
    max(physicalFootprintBytes ?? 0, residentMemoryBytes)
  }
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
