import Foundation

enum FindingSeverity: String, CaseIterable, Sendable {
  case good = "Good"
  case info = "Info"
  case warning = "Warning"
  case critical = "Critical"
}

enum DataMode: String, CaseIterable, Sendable {
  case live = "Live"
  case planned = "Planned"
  case unavailable = "Unavailable"
  case avoided = "Avoided"
}

struct HealthSnapshot {
  var generatedAt: Date
  var attentionSummary: AttentionSummary
  var coverageSummary: DataCoverageSummary
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

struct DataCoverageSummary {
  var live: Int
  var planned: Int
  var unavailable: Int
  var avoided: Int

  var total: Int {
    live + planned + unavailable + avoided
  }

  var livePercent: Double {
    guard total > 0 else {
      return 0
    }

    return Double(live) / Double(total) * 100
  }

  init(modes: [DataMode]) {
    live = modes.filter { $0 == .live }.count
    planned = modes.filter { $0 == .planned }.count
    unavailable = modes.filter { $0 == .unavailable }.count
    avoided = modes.filter { $0 == .avoided }.count
  }
}

struct DiagnosticMetric: Identifiable {
  var id: String { title }
  var title: String
  var value: String
  var unit: String
  var role: DiagnosticMetricRole? = nil
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
  var id: String { "\(title)\u{0}\(detail)" }
  var title: String
  var detail: String
  var status: FindingSeverity
  var severityScore: Int
}

struct SafeAction: Identifiable {
  var id: String { "\(title)\u{0}\(body)" }
  var title: String
  var body: String
  var systemImage: String
  var status: FindingSeverity
}

struct ChartDatum: Identifiable {
  var id: String { title }
  var title: String
  var value: Double
  var unit: String
  var dataMode: DataMode = .unavailable
  var status: FindingSeverity
  var detail: String
}

struct DataAccessCapability: Identifiable {
  var id: String { title }
  var title: String
  var dataMode: DataMode
  var source: String
  var reason: String
  var actionLabel: String?
}

enum StorageCategory: String, CaseIterable, Hashable, Sendable {
  case applications
  case development
  case documents
  case photos
  case video
  case music
  case archivesInstallers
  case cacheTemporary
  case systemLike
  case other
  case unreadable

  var title: String {
    switch self {
    case .applications:
      "Applications"
    case .development:
      "Development"
    case .documents:
      "Documents"
    case .photos:
      "Photos"
    case .video:
      "Video"
    case .music:
      "Music"
    case .archivesInstallers:
      "Archives & Installers"
    case .cacheTemporary:
      "Cache & Temporary"
    case .systemLike:
      "System-like"
    case .other:
      "Other"
    case .unreadable:
      "Unreadable"
    }
  }
}

enum StorageAccessStatus: String, CaseIterable {
  case notRequested = "Not Requested"
  case needsFullDiskAccess = "Needs Full Disk Access"
  case fullDiskAccessLikelyGranted = "Full Disk Access"
  case folderScopeGranted = "Folder Scope"
  case unavailable = "Unavailable"
}

struct BatteryHealth {
  var summary: DiagnosticMetric
  var metrics: [DiagnosticMetric]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
  var liveReading: BatteryLiveReading? = nil
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

struct StorageItem: Identifiable, Equatable {
  var id: String { path }
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

struct StorageCategorySummary: Identifiable {
  var id: String { category.rawValue }
  var category: StorageCategory
  var title: String
  var sizeGB: Double
  var fileCount: Int
  var folderCount: Int
  var largestExamples: [StorageItem]
  var dataMode: DataMode = .live
  var status: FindingSeverity
  var source: String
  var confidence: String
}

struct StorageScanResult {
  var rootTitle: String
  var rootPath: String
  var totalSizeGB: Double
  var scannedItemCount: Int
  var scannedFileCount: Int
  var scannedFolderCount: Int
  var inaccessibleItemCount: Int
  var scanDuration: TimeInterval
  var largestItems: [StorageItem]
  var largestFiles: [StorageItem]
  var largestFolders: [StorageItem]
  var categoryBreakdown: [StorageCategorySummary]
  var chartData: [ChartDatum]
  var lastUpdated: Date
}

struct StorageAccessProbeResult {
  var status: StorageAccessStatus
  var accessibleScopeCount: Int
  var totalScopeCount: Int
  var accessibleScopes: [String]
  var inaccessibleScopes: [String]
  var lastUpdated: Date
}

struct StorageBreadcrumb: Identifiable {
  var id: String { url.path }
  var title: String
  var url: URL
}

struct StorageScanSession {
  var rootURL: URL
  var currentURL: URL
  var breadcrumbs: [StorageBreadcrumb]
  var result: StorageScanResult
}

struct PerformanceHealth {
  var summary: DiagnosticMetric
  var cpu: SystemCPUReading
  var memory: SystemMemoryReading
  var swapInsight: SwapInsight
  var memoryContext: MemoryPressureContext
  var history: [PerformanceTimePoint]
  var metrics: [DiagnosticMetric]
  var processes: [ProcessObservation]
  var appGroups: [AppProcessGroup]
  var aiWorkloads: [AIWorkloadObservation] = []
  var insights: [ProcessInsight]
  var findings: [DiagnosticFinding]
  var actions: [SafeAction]
  var sourceNote: String
}

struct ProcessInsight: Identifiable {
  var id: String { title }
  var title: String
  var detail: String
  var matchedProcessNames: [String]
  var interpretation: String = "Normal"
  var status: FindingSeverity
  var dataMode: DataMode = .live
}

enum MemoryContextState: String {
  case quiet = "Quiet"
  case usingCompression = "Using compression"
  case usingSwap = "Using swap"
  case swapGrowing = "Swap growing"
  case reviewTopProcesses = "Review top memory processes"
  case unavailable = "Unavailable"
}

struct MemoryPressureContext {
  var state: MemoryContextState
  var title: String
  var detail: String
  var memoryUsedPercent: Double
  var physicalBytes: UInt64
  var usedBytes: UInt64
  var appMemoryBytes: UInt64
  var cachedFilesBytes: UInt64
  var wiredBytes: UInt64
  var compressedBytes: UInt64
  var swapUsedBytes: UInt64?
  var swapTrend: SwapTrend
  var swapInRateBytesPerSecond: Double?
  var swapOutRateBytesPerSecond: Double?
  var dataMode: DataMode
  var source: String
  var confidence: String
  var lastUpdated: Date

  init(memory: SystemMemoryReading, swapInsight: SwapInsight) {
    let usedPercent = memory.usedPercent
    let swapUsed = memory.swapUsedBytes
    let hasSwap = (swapUsed ?? 0) > 0
    let hasCompression = memory.compressedBytes > 0
    let state: MemoryContextState

    if memory.dataMode != .live {
      state = .unavailable
    } else if swapInsight.trend == .rising {
      state = .swapGrowing
    } else if hasSwap && usedPercent >= 80 {
      state = .reviewTopProcesses
    } else if hasSwap {
      state = .usingSwap
    } else if hasCompression {
      state = .usingCompression
    } else {
      state = .quiet
    }

    self.state = state
    title = state.rawValue
    switch state {
    case .quiet:
      detail = "Memory signals are quiet in Corewise's public VM view."
    case .usingCompression:
      detail = "macOS is compressing memory, which can be normal. Interpret it with swap and process memory."
    case .usingSwap:
      detail = "macOS is using swap. Check whether swap is stable and which processes hold the most observed memory."
    case .swapGrowing:
      detail = "Swap is growing in the recent sample window. Review top memory processes and recent workload changes."
    case .reviewTopProcesses:
      detail = "Memory use and swap are both elevated enough to review top memory processes."
    case .unavailable:
      detail = "Memory context is unavailable because the current VM reading is not live."
    }

    memoryUsedPercent = usedPercent
    physicalBytes = memory.physicalBytes
    usedBytes = memory.usedBytes
    appMemoryBytes = memory.appMemoryBytes
    cachedFilesBytes = memory.cachedFilesBytes
    wiredBytes = memory.wiredBytes
    compressedBytes = memory.compressedBytes
    swapUsedBytes = swapUsed
    swapTrend = swapInsight.trend
    swapInRateBytesPerSecond = swapInsight.swapInRateBytesPerSecond
    swapOutRateBytesPerSecond = swapInsight.swapOutRateBytesPerSecond
    dataMode = memory.dataMode == .live ? .live : .unavailable
    source = "Corewise VM context derived from public memory and swap signals"
    confidence = "Live / medium"
    lastUpdated = memory.lastUpdated
  }
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

enum SwapTrend: String {
  case rising
  case stable
  case falling
  case unavailable

  var title: String {
    switch self {
    case .rising: "Rising"
    case .stable: "Stable"
    case .falling: "Falling"
    case .unavailable: "Unavailable"
    }
  }
}

struct SwapReading {
  var usedBytes: UInt64
  var totalBytes: UInt64
  var availableBytes: UInt64
  var pageSize: UInt64
  var isEncrypted: Bool
  var swappedBytes: UInt64
  var swapIns: UInt64
  var swapOuts: UInt64
  var dataMode: DataMode = .live
  var source: String
  var confidence: String
  var lastUpdated: Date
}

struct SwapInsight {
  var reading: SwapReading?
  var trend: SwapTrend
  var swapInRateBytesPerSecond: Double?
  var swapOutRateBytesPerSecond: Double?
  var contributors: [SwapContributor]
  var explanation: String
  var source: String
  var confidence: String
  var dataMode: DataMode
  var lastUpdated: Date
}

struct SwapContributor: Identifiable {
  var id: Int32 { pid }
  var pid: Int32
  var processName: String
  var observedMemoryBytes: UInt64
  var residentMemoryBytes: UInt64
  var physicalFootprintBytes: UInt64?
  var pageIns: UInt64
  var memoryGrowthBytes: Int64
  var confidence: String
  var dataMode: DataMode = .live
}

struct SystemMemoryReading {
  var physicalBytes: UInt64
  var usedBytes: UInt64
  var freeBytes: UInt64
  var appMemoryBytes: UInt64
  var cachedFilesBytes: UInt64
  var wiredBytes: UInt64
  var compressedBytes: UInt64
  var swap: SwapReading?
  var dataMode: DataMode = .unavailable
  var source: String
  var confidence: String
  var lastUpdated: Date
}

extension SystemMemoryReading {
  var swapUsedBytes: UInt64? {
    swap?.usedBytes
  }
}

struct ProcessObservation: Identifiable {
  var id: Int32 { pid }
  var pid: Int32
  var processName: String
  var displayName: String
  var appName: String?
  var path: String?
  var user: String
  var parentPID: Int32 = 0
  var cpuSampleAvailable: Bool = true
  var signingIdentifier: String? = nil
  var cpuPercent: Double
  var cpuTimeSeconds: Double
  var threadCount: Int32
  var residentMemoryBytes: UInt64
  var physicalFootprintBytes: UInt64?
  var pageIns: UInt64
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

enum AppProcessGroupKind: String, Sendable {
  case app
  case systemService
  case standaloneProcess
  case unknown
}

struct AppProcessGroup: Identifiable {
  var id: String { stableID.isEmpty ? name : stableID }
  var stableID: String = ""
  var name: String
  var bundlePath: String? = nil
  var user: String = ""
  var kind: AppProcessGroupKind = .unknown
  var memberPIDs: [Int32] = []
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
  var id: String { path }
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
  var level: ThermalLevel = .unavailable
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
  var id: String { appName }
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
  var id: String { title }
  var title: String
  var body: String
  var severity: FindingSeverity
}
