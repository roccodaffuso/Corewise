import Foundation

final class PerformanceHistoryTracker {
  private var samples: [PerformanceHistorySample] = []
  private let retentionSeconds: TimeInterval
  private let sustainedWindowSeconds: TimeInterval
  private let sustainedCPUThreshold: Double
  private let requiredSustainedSamples: Int
  private let maximumVisiblePoints: Int
  private let maximumRetainedSamples: Int

  init(
    retentionSeconds: TimeInterval = 120,
    sustainedWindowSeconds: TimeInterval = 60,
    sustainedCPUThreshold: Double = 25,
    requiredSustainedSamples: Int = 3,
    maximumVisiblePoints: Int = 60,
    maximumRetainedSamples: Int = 60
  ) {
    self.retentionSeconds = retentionSeconds
    self.sustainedWindowSeconds = sustainedWindowSeconds
    self.sustainedCPUThreshold = sustainedCPUThreshold
    self.requiredSustainedSamples = requiredSustainedSamples
    self.maximumVisiblePoints = maximumVisiblePoints
    self.maximumRetainedSamples = maximumRetainedSamples
  }

  func record(instant: InstantSystemMetrics, now: Date) -> PerformanceHistorySummary {
    samples.append(
      PerformanceHistorySample(
        timestamp: now,
        cpuPercent: instant.cpu.totalPercent,
        memoryUsedPercent: instant.memory.usedPercent,
        swap: instant.memory.swap,
        processes: instant.processes
      )
    )
    prune(now: now)
    return summary(now: now)
  }

  func summary(now: Date) -> PerformanceHistorySummary {
    prune(now: now)

    let recentCutoff = now.addingTimeInterval(-sustainedWindowSeconds)
    let recentSamples = samples.filter { $0.timestamp >= recentCutoff }
    var highProcessCounts: [String: Int] = [:]

    for sample in recentSamples {
      for process in sample.processes where process.cpuPercent >= sustainedCPUThreshold {
        highProcessCounts[process.displayName, default: 0] += 1
      }
    }

    let repeated = highProcessCounts
      .filter { $0.value >= requiredSustainedSamples }
      .map(\.key)
      .sorted()

    return PerformanceHistorySummary(
      retainedSampleCount: samples.count,
      recentSampleCount: recentSamples.count,
      requiredSampleCount: requiredSustainedSamples,
      repeatedHighCPUProcesses: repeated,
      sustainedCPUThreshold: sustainedCPUThreshold,
      recentPoints: samples.suffix(maximumVisiblePoints).map {
        PerformanceTimePoint(
          timestamp: $0.timestamp,
          cpuPercent: $0.cpuPercent,
          memoryUsedPercent: $0.memoryUsedPercent,
          swapUsedBytes: $0.swap?.usedBytes
        )
      },
      swapInsight: SwapInsightCalculator.insight(samples: recentSamples, now: now)
    )
  }

  private func prune(now: Date) {
    let cutoff = now.addingTimeInterval(-retentionSeconds)
    samples.removeAll { $0.timestamp < cutoff }
    if samples.count > maximumRetainedSamples {
      samples.removeFirst(samples.count - maximumRetainedSamples)
    }
  }
}

struct PerformanceHistorySummary {
  var retainedSampleCount: Int
  var recentSampleCount: Int
  var requiredSampleCount: Int
  var repeatedHighCPUProcesses: [String]
  var sustainedCPUThreshold: Double
  var recentPoints: [PerformanceTimePoint]
  var swapInsight: SwapInsight

  var hasEnoughSamples: Bool {
    recentSampleCount >= requiredSampleCount
  }

  var hasSustainedHighCPU: Bool {
    hasEnoughSamples && !repeatedHighCPUProcesses.isEmpty
  }
}

struct PerformanceHistorySample {
  var timestamp: Date
  var cpuPercent: Double?
  var memoryUsedPercent: Double
  var swap: SwapReading?
  var processes: [PerformanceHistoryProcessSample]

  init(
    timestamp: Date,
    cpuPercent: Double?,
    memoryUsedPercent: Double,
    swap: SwapReading?,
    processes: [ProcessObservation]
  ) {
    self.timestamp = timestamp
    self.cpuPercent = cpuPercent
    self.memoryUsedPercent = memoryUsedPercent
    self.swap = swap
    self.processes = processes.map(PerformanceHistoryProcessSample.init)
  }
}

struct PerformanceHistoryProcessSample {
  var pid: Int32
  var displayName: String
  var cpuPercent: Double
  var observedMemoryBytes: UInt64
  var residentMemoryBytes: UInt64
  var physicalFootprintBytes: UInt64?
  var pageIns: UInt64
  var dataMode: DataMode

  init(_ process: ProcessObservation) {
    pid = process.pid
    displayName = process.displayName
    cpuPercent = process.cpuPercent
    observedMemoryBytes = process.observedMemoryBytes
    residentMemoryBytes = process.residentMemoryBytes
    physicalFootprintBytes = process.physicalFootprintBytes
    pageIns = process.pageIns
    dataMode = process.dataMode
  }
}

enum SwapInsightCalculator {
  static let risingBytesThreshold = UInt64(256 * 1024 * 1024)
  static let swapOutRateThresholdBytesPerSecond = 8.0 * 1024.0 * 1024.0 / 60.0

  static func insight(samples: [PerformanceHistorySample], now: Date) -> SwapInsight {
    let valid = samples.filter { $0.swap != nil }.sorted { $0.timestamp < $1.timestamp }
    guard let latest = valid.last, let latestSwap = latest.swap else {
      return unavailable(now: now)
    }

    let previous = valid.dropLast().last
    let elapsed = previous.map { max(latest.timestamp.timeIntervalSince($0.timestamp), 1) }
    let swapInRate = rate(latest: latestSwap.swapIns, previous: previous?.swap?.swapIns, elapsed: elapsed, pageSize: latestSwap.pageSize)
    let swapOutRate = rate(latest: latestSwap.swapOuts, previous: previous?.swap?.swapOuts, elapsed: elapsed, pageSize: latestSwap.pageSize)
    let trend = trend(latest: latestSwap, previous: previous?.swap, swapOutRate: swapOutRate)
    let contributors = contributors(latest: latest, previous: previous)

    return SwapInsight(
      reading: latestSwap,
      trend: trend,
      swapInRateBytesPerSecond: swapInRate,
      swapOutRateBytesPerSecond: swapOutRate,
      contributors: contributors,
      explanation: "macOS does not expose exact per-process swap ownership through public APIs. These rows show likely contributors based on live memory signals.",
      source: latestSwap.source,
      confidence: contributors.isEmpty ? "Live / medium" : "Live / inferred",
      dataMode: latestSwap.dataMode,
      lastUpdated: now
    )
  }

  private static func unavailable(now: Date) -> SwapInsight {
    SwapInsight(
      reading: nil,
      trend: .unavailable,
      swapInRateBytesPerSecond: nil,
      swapOutRateBytesPerSecond: nil,
      contributors: [],
      explanation: "Swap insight is unavailable until macOS returns swap data.",
      source: "sysctl vm.swapusage + host_statistics64 HOST_VM_INFO64",
      confidence: "Unavailable / medium",
      dataMode: .unavailable,
      lastUpdated: now
    )
  }

  private static func trend(latest: SwapReading, previous: SwapReading?, swapOutRate: Double?) -> SwapTrend {
    guard let previous else {
      return .unavailable
    }

    if latest.usedBytes >= previous.usedBytes + risingBytesThreshold {
      return .rising
    }
    if previous.usedBytes >= latest.usedBytes + risingBytesThreshold {
      return .falling
    }
    if (swapOutRate ?? 0) > swapOutRateThresholdBytesPerSecond {
      return .rising
    }
    return .stable
  }

  private static func rate(latest: UInt64, previous: UInt64?, elapsed: TimeInterval?, pageSize: UInt64) -> Double? {
    guard let previous, let elapsed, latest >= previous else {
      return nil
    }

    return Double(latest - previous) * Double(pageSize) / elapsed
  }

  private static func contributors(latest: PerformanceHistorySample, previous: PerformanceHistorySample?) -> [SwapContributor] {
    let previousByPID = Dictionary(uniqueKeysWithValues: (previous?.processes ?? []).map { ($0.pid, $0) })

    return latest.processes
      .filter { $0.observedMemoryBytes >= 100 * 1024 * 1024 || $0.pageIns > 0 }
      .map { process in
        let previousMemory = previousByPID[process.pid]?.observedMemoryBytes ?? process.observedMemoryBytes
        let growth = Int64(process.observedMemoryBytes) - Int64(previousMemory)
        return SwapContributor(
          pid: process.pid,
          processName: process.displayName,
          observedMemoryBytes: process.observedMemoryBytes,
          residentMemoryBytes: process.residentMemoryBytes,
          physicalFootprintBytes: process.physicalFootprintBytes,
          pageIns: process.pageIns,
          memoryGrowthBytes: growth,
          confidence: "Live / inferred",
          dataMode: process.dataMode
        )
      }
      .sorted { lhs, rhs in
        contributorScore(lhs) > contributorScore(rhs)
      }
      .prefix(8)
      .map { $0 }
  }

  private static func contributorScore(_ contributor: SwapContributor) -> Double {
    let memoryGB = Double(contributor.observedMemoryBytes) / SystemMetricsSampler.bytesPerGB
    let growthGB = max(Double(contributor.memoryGrowthBytes), 0) / SystemMetricsSampler.bytesPerGB
    let pageInWeight = min(Double(contributor.pageIns) / 10_000.0, 10)
    return memoryGB * 10 + growthGB * 18 + pageInWeight
  }
}

extension SystemMemoryReading {
  var usedPercent: Double {
    guard physicalBytes > 0 else {
      return 0
    }
    return Double(usedBytes) / Double(physicalBytes) * 100
  }

  var usedGB: Double {
    Double(usedBytes) / SystemMetricsSampler.bytesPerGB
  }

  var physicalGB: Double {
    Double(physicalBytes) / SystemMetricsSampler.bytesPerGB
  }

  var freeGB: Double {
    Double(freeBytes) / SystemMetricsSampler.bytesPerGB
  }

  var appMemoryGB: Double {
    Double(appMemoryBytes) / SystemMetricsSampler.bytesPerGB
  }

  var cachedFilesGB: Double {
    Double(cachedFilesBytes) / SystemMetricsSampler.bytesPerGB
  }

  var wiredGB: Double {
    Double(wiredBytes) / SystemMetricsSampler.bytesPerGB
  }

  var compressedGB: Double {
    Double(compressedBytes) / SystemMetricsSampler.bytesPerGB
  }

  var swapUsedGB: Double? {
    swapUsedBytes.map { Double($0) / SystemMetricsSampler.bytesPerGB }
  }

  var swapTotalGB: Double? {
    swap?.totalBytes.mapGB
  }

  var swapAvailableGB: Double? {
    swap?.availableBytes.mapGB
  }
}

private extension UInt64 {
  var mapGB: Double {
    Double(self) / SystemMetricsSampler.bytesPerGB
  }
}
