import Foundation

enum FocusedCheckIntent: String, CaseIterable, Identifiable, Hashable, Sendable {
  case slow
  case hot
  case batteryDrain
  case storageFull
  case general
  case aiWorkloads

  var id: String { rawValue }

  var title: String {
    switch self {
    case .slow: String(localized: "focusedCheck.intent.slow", defaultValue: "My Mac feels slow", bundle: .main)
    case .hot: String(localized: "focusedCheck.intent.hot", defaultValue: "My Mac feels hot", bundle: .main)
    case .batteryDrain: String(localized: "focusedCheck.intent.batteryDrain", defaultValue: "Battery drains quickly", bundle: .main)
    case .storageFull: String(localized: "focusedCheck.intent.storageFull", defaultValue: "Storage is full", bundle: .main)
    case .general: String(localized: "focusedCheck.intent.general", defaultValue: "Just checking", bundle: .main)
    case .aiWorkloads: String(localized: "focusedCheck.intent.aiWorkloads", defaultValue: "Observe AI Session", bundle: .main)
    }
  }

  var minimumDuration: TimeInterval {
    switch self {
    case .slow, .hot: 15
    case .batteryDrain: 5 * 60
    case .storageFull, .general: 0
    case .aiWorkloads: 60
    }
  }

  var suggestedDuration: TimeInterval? {
    switch self {
    case .slow, .hot: 60
    case .batteryDrain: 10 * 60
    case .storageFull, .general: nil
    case .aiWorkloads: 10 * 60
    }
  }

  var launchRoute: DashboardRoute {
    if self == .storageFull { return DashboardRoute(section: .storage) }
    if self == .aiWorkloads { return DashboardRoute(section: .performance, performanceMode: .aiWorkloads) }
    return DashboardRoute(section: .overview)
  }
}

enum FocusedCheckPhase: Equatable, Sendable {
  case idle
  case observing
  case awaitingAccess
  case readyForStorageScan
  case scanningStorage
  case readyToFinish
  case completed
  case cancelled
  case unavailable
}

enum FocusedCheckEvidenceKind: String, CaseIterable, Hashable, Sendable {
  case sustainedCPU
  case elevatedSystemCPU
  case memoryLoad
  case swapGrowth
  case appGroupActivity
  case processActivity
  case thermalPressure
  case batteryState
  case batteryChargeChange
  case lowStorageHeadroom
  case storageCoverage
  case storageAttribution
  case unavailable
  case aiWorkloadActivity

  var family: FocusedCheckEvidenceFamily {
    switch self {
    case .sustainedCPU, .elevatedSystemCPU:
      .cpu
    case .memoryLoad, .swapGrowth:
      .memory
    case .appGroupActivity, .processActivity, .aiWorkloadActivity:
      .activity
    case .thermalPressure:
      .thermal
    case .batteryState, .batteryChargeChange:
      .battery
    case .lowStorageHeadroom:
      .storageHeadroom
    case .storageCoverage:
      .storageCoverage
    case .storageAttribution:
      .storageAttribution
    case .unavailable:
      .availability
    }
  }
}

enum FocusedCheckEvidenceFamily: String, Hashable, Sendable {
  case cpu
  case memory
  case activity
  case thermal
  case battery
  case storageHeadroom
  case storageCoverage
  case storageAttribution
  case availability
}

enum EvidenceConfidence: Int, CaseIterable, Comparable, Sendable {
  case low = 1
  case medium = 2
  case high = 3

  static func < (lhs: EvidenceConfidence, rhs: EvidenceConfidence) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  var title: String {
    switch self {
    case .low: corewiseText("Low", comment: "Focused Check evidence confidence")
    case .medium: corewiseText("Medium", comment: "Focused Check evidence confidence")
    case .high: corewiseText("High", comment: "Focused Check evidence confidence")
    }
  }
}

struct FocusedCheckEvidence: Identifiable, Equatable, Sendable {
  var id: String
  var kind: FocusedCheckEvidenceKind
  var area: DiagnosticArea
  var title: String
  var value: String
  var detail: String
  var severity: FindingSeverity
  var confidence: EvidenceConfidence
  var source: String
  var firstObservedAt: Date
  var lastObservedAt: Date
  var sampleCount: Int
  var destination: DashboardRoute?

  init(
    id: String? = nil,
    kind: FocusedCheckEvidenceKind,
    area: DiagnosticArea,
    title: String,
    value: String,
    detail: String,
    severity: FindingSeverity,
    confidence: EvidenceConfidence,
    source: String,
    firstObservedAt: Date,
    lastObservedAt: Date,
    sampleCount: Int,
    destination: DashboardRoute? = nil
  ) {
    self.id = id ?? "\(kind.rawValue):\(title)"
    self.kind = kind
    self.area = area
    self.title = title
    self.value = value
    self.detail = detail
    self.severity = severity
    self.confidence = confidence
    self.source = source
    self.firstObservedAt = firstObservedAt
    self.lastObservedAt = lastObservedAt
    self.sampleCount = sampleCount
    self.destination = destination
  }
}

enum FocusedCheckResultState: String, CaseIterable, Sendable {
  case clear
  case review
  case critical
  case unavailable
  case insufficientEvidence
}

struct FocusedCheckAction: Equatable, Sendable {
  var title: String
  var detail: String
  var destination: DashboardRoute?
}

struct FocusedCheckResult: Equatable, Sendable {
  var intent: FocusedCheckIntent
  var state: FocusedCheckResultState
  var headline: String
  var detail: String
  var evidence: [FocusedCheckEvidence]
  var primaryAction: FocusedCheckAction
  var observationStartedAt: Date
  var observationEndedAt: Date
  var coverage: String
  var generatedAt: Date
  var aiWorkloads: [AIWorkloadSessionSummary] = []
}

struct FocusedCheckActivitySummary: Identifiable, Equatable, Sendable {
  var id: String
  var title: String
  var firstObservedAt: Date
  var lastObservedAt: Date
  var sampleCount: Int
  var activeCPUSampleCount: Int
  var maximumCPUPercent: Double
  var peakMemoryBytes: UInt64
  var memberPIDs: [Int32]
}

struct FocusedCheckSession: Identifiable, Equatable, Sendable {
  var id: UUID
  var intent: FocusedCheckIntent
  var phase: FocusedCheckPhase
  var startedAt: Date
  var completedAt: Date?
  var lastUpdatedAt: Date
  var minimumDuration: TimeInterval
  var suggestedDuration: TimeInterval?
  var systemSampleCount: Int
  var distinctBatterySampleCount: Int
  var missingSampleCount: Int
  var provisionalEvidence: [FocusedCheckEvidence]
  var activityGroups: [FocusedCheckActivitySummary]
  var result: FocusedCheckResult?
  var aiWorkloads: [AIWorkloadSessionSummary]

  init(intent: FocusedCheckIntent, now: Date, id: UUID = UUID()) {
    self.id = id
    self.intent = intent
    phase = .observing
    startedAt = now
    completedAt = nil
    lastUpdatedAt = now
    minimumDuration = intent.minimumDuration
    suggestedDuration = intent.suggestedDuration
    systemSampleCount = 0
    distinctBatterySampleCount = 0
    missingSampleCount = 0
    provisionalEvidence = []
    activityGroups = []
    result = nil
    aiWorkloads = []
  }
}

enum BatteryPowerSource: String, Sendable {
  case battery
  case ac
  case ups
  case unknown
}

struct BatteryLiveReading: Equatable, Sendable {
  var chargePercent: Double?
  var powerSource: BatteryPowerSource
  var isCharging: Bool?
  var timestamp: Date
}

enum ThermalLevel: Int, CaseIterable, Comparable, Sendable {
  case unavailable = -1
  case nominal = 0
  case fair = 1
  case serious = 2
  case critical = 3

  static func < (lhs: ThermalLevel, rhs: ThermalLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  var title: String {
    switch self {
    case .unavailable: corewiseText("Unavailable", comment: "Thermal level")
    case .nominal: corewiseText("Nominal", comment: "Thermal level")
    case .fair: corewiseText("Fair", comment: "Thermal level")
    case .serious: corewiseText("Serious", comment: "Thermal level")
    case .critical: corewiseText("Critical", comment: "Thermal level")
    }
  }
}
