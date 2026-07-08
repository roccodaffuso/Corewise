import Foundation

enum OverallStatus: String, CaseIterable {
  case good = "Good"
  case needsAttention = "Needs Attention"
  case critical = "Critical"

  var summary: String {
    switch self {
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
    case .good:
      "checkmark.seal.fill"
    case .needsAttention:
      "exclamationmark.triangle.fill"
    case .critical:
      "xmark.octagon.fill"
    }
  }
}

enum FindingSeverity: String {
  case good = "Good"
  case info = "Info"
  case warning = "Warning"
  case critical = "Critical"
}

struct HealthSnapshot {
  var generatedAt: Date
  var overallStatus: OverallStatus
  var battery: BatteryHealth
  var storage: StorageHealth
  var performance: PerformanceHealth
  var startupItems: [StartupItem]
  var thermal: ThermalHealth
  var crashIssues: [CrashIssue]
  var suggestions: [Suggestion]
}

struct BatteryHealth {
  var cycleCount: Int
  var maximumCapacityPercent: Int
  var condition: String
  var recentEnergyImpact: String
  var sourceNote: String
}

struct StorageHealth {
  var freeSpaceDescription: String
  var largeFolders: [StorageItem]
  var largeCaches: [StorageItem]
  var hugeFiles: [StorageItem]
  var sourceNote: String
}

struct StorageItem: Identifiable {
  let id = UUID()
  var name: String
  var detail: String
  var sizeDescription: String
  var severity: FindingSeverity
}

struct PerformanceHealth {
  var cpuProcesses: [ProcessSample]
  var memoryProcesses: [ProcessSample]
  var sourceNote: String
}

struct ProcessSample: Identifiable {
  let id = UUID()
  var name: String
  var metric: String
  var detail: String
  var severity: FindingSeverity
}

struct StartupItem: Identifiable {
  let id = UUID()
  var name: String
  var location: String
  var probableImpact: String
  var severity: FindingSeverity
}

struct ThermalHealth {
  var state: String
  var detail: String
  var sourceNote: String
  var severity: FindingSeverity
}

struct CrashIssue: Identifiable {
  let id = UUID()
  var appName: String
  var countDescription: String
  var detail: String
  var severity: FindingSeverity
}

struct Suggestion: Identifiable {
  let id = UUID()
  var title: String
  var body: String
  var severity: FindingSeverity
}
