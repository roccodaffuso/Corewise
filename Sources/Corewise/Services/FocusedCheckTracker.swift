import Foundation

struct FocusedCheckSample {
  var timestamp: Date
  var cpuPercent: Double?
  var memoryUsedPercent: Double?
  var swapUsedBytes: UInt64?
  var swapTrend: SwapTrend
  var thermalLevel: ThermalLevel
  var batteryReading: BatteryLiveReading?
  var appGroups: [AppProcessGroup]
  var processes: [ProcessObservation]

  init(snapshot: HealthSnapshot) {
    timestamp = snapshot.generatedAt
    cpuPercent = snapshot.performance.cpu.dataMode == .live ? snapshot.performance.cpu.totalPercent : nil
    memoryUsedPercent = snapshot.performance.memory.dataMode == .live ? snapshot.performance.memory.usedPercent : nil
    swapUsedBytes = snapshot.performance.memory.dataMode == .live ? snapshot.performance.memory.swapUsedBytes : nil
    swapTrend = snapshot.performance.swapInsight.dataMode == .live ? snapshot.performance.swapInsight.trend : .unavailable
    thermalLevel = snapshot.thermal.level
    batteryReading = snapshot.battery.liveReading
    appGroups = snapshot.performance.appGroups.filter { $0.dataMode == .live }
    processes = snapshot.performance.processes.filter { $0.dataMode == .live }
  }

  init(
    timestamp: Date,
    cpuPercent: Double? = nil,
    memoryUsedPercent: Double? = nil,
    swapUsedBytes: UInt64? = nil,
    swapTrend: SwapTrend = .unavailable,
    thermalLevel: ThermalLevel = .unavailable,
    batteryReading: BatteryLiveReading? = nil,
    appGroups: [AppProcessGroup] = [],
    processes: [ProcessObservation] = []
  ) {
    self.timestamp = timestamp
    self.cpuPercent = cpuPercent
    self.memoryUsedPercent = memoryUsedPercent
    self.swapUsedBytes = swapUsedBytes
    self.swapTrend = swapTrend
    self.thermalLevel = thermalLevel
    self.batteryReading = batteryReading
    self.appGroups = appGroups
    self.processes = processes
  }
}

struct FocusedCheckSystemPoint: Equatable, Sendable {
  var timestamp: Date
  var cpuPercent: Double?
  var memoryUsedPercent: Double?
  var swapUsedBytes: UInt64?
  var swapTrend: SwapTrend
  var thermalLevel: ThermalLevel
}

struct FocusedCheckActivityAggregate: Equatable, Sendable {
  var id: String
  var title: String
  var firstObservedAt: Date
  var lastObservedAt: Date
  var sampleCount: Int
  var activeCPUSampleCount: Int
  var maximumCPUPercent: Double
  var peakMemoryBytes: UInt64
  var memberPIDs: Set<Int32>

  var hasSustainedCPU: Bool {
    activeCPUSampleCount >= 3 && maximumCPUPercent >= FocusedCheckTracker.activeCPUThreshold
  }
}

struct FocusedCheckStorageAggregate: Equatable, Sendable {
  var volumeUsedGB: Double
  var volumeAvailableGB: Double
  var scanRootTitle: String
  var classifiedGB: Double
  var inaccessibleItemCount: Int
  var largestCategory: StorageCategory?
  var largestCategoryTitle: String?
  var largestCategoryGB: Double?
  var largestFolder: StorageItem?
  var largestFile: StorageItem?
  var completedAt: Date
}

struct FocusedCheckAggregateSummary: Equatable, Sendable {
  var intent: FocusedCheckIntent
  var startedAt: Date
  var endedAt: Date
  var systemPoints: [FocusedCheckSystemPoint]
  var batteryReadings: [BatteryLiveReading]
  var missingSampleCount: Int
  var appGroups: [FocusedCheckActivityAggregate]
  var processes: [FocusedCheckActivityAggregate]
  var storage: FocusedCheckStorageAggregate?

  init(
    intent: FocusedCheckIntent,
    startedAt: Date,
    endedAt: Date,
    systemPoints: [FocusedCheckSystemPoint] = [],
    batteryReadings: [BatteryLiveReading] = [],
    missingSampleCount: Int = 0,
    appGroups: [FocusedCheckActivityAggregate] = [],
    processes: [FocusedCheckActivityAggregate] = [],
    storage: FocusedCheckStorageAggregate? = nil
  ) {
    self.intent = intent
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.systemPoints = systemPoints
    self.batteryReadings = batteryReadings
    self.missingSampleCount = missingSampleCount
    self.appGroups = appGroups
    self.processes = processes
    self.storage = storage
  }

  var elapsed: TimeInterval {
    max(endedAt.timeIntervalSince(startedAt), 0)
  }

  var systemSampleCount: Int { systemPoints.count }
  var distinctBatterySampleCount: Int { batteryReadings.count }
  var cpuValues: [Double] { systemPoints.compactMap(\.cpuPercent) }
  var memoryValues: [Double] { systemPoints.compactMap(\.memoryUsedPercent) }
  var averageCPUPercent: Double? { cpuValues.average }
  var maximumCPUPercent: Double? { cpuValues.max() }
  var maximumMemoryUsedPercent: Double? { memoryValues.max() }
  var hasRisingSwap: Bool { systemPoints.contains { $0.swapTrend == .rising } }
  var highestThermalLevel: ThermalLevel { systemPoints.map(\.thermalLevel).max() ?? .unavailable }

  var topAppGroupSummaries: [FocusedCheckActivitySummary] {
    appGroups.prefix(3).map {
      FocusedCheckActivitySummary(
        id: $0.id,
        title: $0.title,
        firstObservedAt: $0.firstObservedAt,
        lastObservedAt: $0.lastObservedAt,
        sampleCount: $0.sampleCount,
        activeCPUSampleCount: $0.activeCPUSampleCount,
        maximumCPUPercent: $0.maximumCPUPercent,
        peakMemoryBytes: $0.peakMemoryBytes,
        memberPIDs: $0.memberPIDs.sorted()
      )
    }
  }
}

final class FocusedCheckTracker {
  static let maximumSystemPointCount = 300
  static let maximumActivityCount = 50
  static let activeCPUThreshold = 25.0

  private(set) var intent: FocusedCheckIntent?
  private(set) var startedAt: Date?
  private var systemPoints: [FocusedCheckSystemPoint] = []
  private var batteryReadingsByDate: [Date: BatteryLiveReading] = [:]
  private var missingSampleCount = 0
  private var appGroupAggregates: [String: FocusedCheckActivityAggregate] = [:]
  private var processAggregates: [String: FocusedCheckActivityAggregate] = [:]
  private var storageAggregate: FocusedCheckStorageAggregate?

  func start(intent: FocusedCheckIntent, now: Date) {
    reset()
    self.intent = intent
    startedAt = now
  }

  func ingest(snapshot: HealthSnapshot) {
    ingest(FocusedCheckSample(snapshot: snapshot))
  }

  func ingest(_ sample: FocusedCheckSample) {
    guard intent != nil, let startedAt, sample.timestamp >= startedAt else {
      return
    }

    if sample.cpuPercent != nil || sample.memoryUsedPercent != nil || sample.thermalLevel != .unavailable {
      insertSystemPoint(
        FocusedCheckSystemPoint(
          timestamp: sample.timestamp,
          cpuPercent: sample.cpuPercent,
          memoryUsedPercent: sample.memoryUsedPercent,
          swapUsedBytes: sample.swapUsedBytes,
          swapTrend: sample.swapTrend,
          thermalLevel: sample.thermalLevel
        )
      )
      if systemPoints.count > Self.maximumSystemPointCount {
        systemPoints.removeFirst(systemPoints.count - Self.maximumSystemPointCount)
      }
    }

    if let batteryReading = sample.batteryReading {
      batteryReadingsByDate[batteryReading.timestamp] = batteryReading
    }

    for group in sample.appGroups {
      let key = group.id
      appGroupAggregates[key] = updatedAggregate(
        appGroupAggregates[key],
        id: key,
        title: group.name,
        cpu: group.cpuPercent,
        memory: group.observedMemoryBytes,
        pids: Set(group.memberPIDs),
        at: sample.timestamp
      )
    }

    for process in sample.processes {
      let key = String(process.pid)
      processAggregates[key] = updatedAggregate(
        processAggregates[key],
        id: key,
        title: process.displayName,
        cpu: process.cpuPercent,
        memory: process.observedMemoryBytes,
        pids: [process.pid],
        at: sample.timestamp
      )
    }

    appGroupAggregates = capped(appGroupAggregates)
    processAggregates = capped(processAggregates)
  }

  func recordStorage(result: StorageScanResult, volume: StorageHealth) {
    guard intent == .storageFull else {
      return
    }
    let largestCategory = result.categoryBreakdown.max(by: { $0.sizeGB < $1.sizeGB })
    storageAggregate = FocusedCheckStorageAggregate(
      volumeUsedGB: volume.usedGB,
      volumeAvailableGB: volume.availableGB,
      scanRootTitle: result.rootTitle,
      classifiedGB: result.totalSizeGB,
      inaccessibleItemCount: result.inaccessibleItemCount,
      largestCategory: largestCategory?.category,
      largestCategoryTitle: largestCategory?.title,
      largestCategoryGB: largestCategory?.sizeGB,
      largestFolder: result.largestFolders.first,
      largestFile: result.largestFiles.first,
      completedAt: result.lastUpdated
    )
  }

  func recordMissingInterval(at date: Date) {
    guard intent != nil, let startedAt, date >= startedAt else {
      return
    }
    missingSampleCount = min(missingSampleCount + 1, Self.maximumSystemPointCount)
  }

  func summary(now: Date) -> FocusedCheckAggregateSummary? {
    guard let intent, let startedAt else {
      return nil
    }

    return FocusedCheckAggregateSummary(
      intent: intent,
      startedAt: startedAt,
      endedAt: max(now, startedAt),
      systemPoints: systemPoints,
      batteryReadings: batteryReadingsByDate.values.sorted { $0.timestamp < $1.timestamp },
      missingSampleCount: missingSampleCount,
      appGroups: appGroupAggregates.values.sorted(by: aggregateSort),
      processes: processAggregates.values.sorted(by: aggregateSort),
      storage: storageAggregate
    )
  }

  func reset() {
    intent = nil
    startedAt = nil
    systemPoints.removeAll(keepingCapacity: true)
    batteryReadingsByDate.removeAll(keepingCapacity: true)
    missingSampleCount = 0
    appGroupAggregates.removeAll(keepingCapacity: true)
    processAggregates.removeAll(keepingCapacity: true)
    storageAggregate = nil
  }

  private func updatedAggregate(
    _ existing: FocusedCheckActivityAggregate?,
    id: String,
    title: String,
    cpu: Double,
    memory: UInt64,
    pids: Set<Int32>,
    at date: Date
  ) -> FocusedCheckActivityAggregate {
    guard var existing else {
      return FocusedCheckActivityAggregate(
        id: id,
        title: title,
        firstObservedAt: date,
        lastObservedAt: date,
        sampleCount: 1,
        activeCPUSampleCount: cpu >= Self.activeCPUThreshold ? 1 : 0,
        maximumCPUPercent: cpu,
        peakMemoryBytes: memory,
        memberPIDs: pids
      )
    }

    existing.firstObservedAt = min(existing.firstObservedAt, date)
    existing.lastObservedAt = max(existing.lastObservedAt, date)
    existing.sampleCount += 1
    if cpu >= Self.activeCPUThreshold {
      existing.activeCPUSampleCount += 1
    }
    existing.maximumCPUPercent = max(existing.maximumCPUPercent, cpu)
    existing.peakMemoryBytes = max(existing.peakMemoryBytes, memory)
    existing.memberPIDs.formUnion(pids)
    return existing
  }

  private func insertSystemPoint(_ point: FocusedCheckSystemPoint) {
    guard let last = systemPoints.last, point.timestamp < last.timestamp else {
      systemPoints.append(point)
      return
    }
    let index = systemPoints.firstIndex { $0.timestamp > point.timestamp } ?? systemPoints.endIndex
    systemPoints.insert(point, at: index)
  }

  private func capped(_ aggregates: [String: FocusedCheckActivityAggregate]) -> [String: FocusedCheckActivityAggregate] {
    guard aggregates.count > Self.maximumActivityCount else {
      return aggregates
    }
    return Dictionary(uniqueKeysWithValues: aggregates.values.sorted(by: aggregateSort).prefix(Self.maximumActivityCount).map { ($0.id, $0) })
  }

  private func aggregateSort(_ lhs: FocusedCheckActivityAggregate, _ rhs: FocusedCheckActivityAggregate) -> Bool {
    let lhsScore = Double(lhs.activeCPUSampleCount) * 100 + lhs.maximumCPUPercent + Double(lhs.peakMemoryBytes) / SystemMetricsSampler.bytesPerGB
    let rhsScore = Double(rhs.activeCPUSampleCount) * 100 + rhs.maximumCPUPercent + Double(rhs.peakMemoryBytes) / SystemMetricsSampler.bytesPerGB
    if lhsScore != rhsScore {
      return lhsScore > rhsScore
    }
    return lhs.id < rhs.id
  }
}

private extension Array where Element == Double {
  var average: Double? {
    isEmpty ? nil : reduce(0, +) / Double(count)
  }
}
