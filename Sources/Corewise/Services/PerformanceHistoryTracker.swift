import Foundation

final class PerformanceHistoryTracker {
  private var samples: [PerformanceHistorySample] = []
  private let retentionSeconds: TimeInterval
  private let sustainedWindowSeconds: TimeInterval
  private let sustainedCPUThreshold: Double
  private let requiredSustainedSamples: Int

  init(
    retentionSeconds: TimeInterval = 120,
    sustainedWindowSeconds: TimeInterval = 60,
    sustainedCPUThreshold: Double = 25,
    requiredSustainedSamples: Int = 3
  ) {
    self.retentionSeconds = retentionSeconds
    self.sustainedWindowSeconds = sustainedWindowSeconds
    self.sustainedCPUThreshold = sustainedCPUThreshold
    self.requiredSustainedSamples = requiredSustainedSamples
  }

  func record(instant: InstantSystemMetrics, now: Date) -> PerformanceHistorySummary {
    samples.append(
      PerformanceHistorySample(
        timestamp: now,
        cpuPercent: instant.cpuPercent,
        memoryPercent: instant.memoryPercent,
        cpuProcesses: instant.topCPUProcesses,
        memoryProcesses: instant.topMemoryProcesses
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
      for process in sample.cpuProcesses where process.value >= sustainedCPUThreshold {
        highProcessCounts[process.name, default: 0] += 1
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
      sustainedCPUThreshold: sustainedCPUThreshold
    )
  }

  private func prune(now: Date) {
    let cutoff = now.addingTimeInterval(-retentionSeconds)
    samples.removeAll { $0.timestamp < cutoff }
  }
}

struct PerformanceHistorySummary {
  var retainedSampleCount: Int
  var recentSampleCount: Int
  var requiredSampleCount: Int
  var repeatedHighCPUProcesses: [String]
  var sustainedCPUThreshold: Double

  var hasEnoughSamples: Bool {
    recentSampleCount >= requiredSampleCount
  }

  var hasSustainedHighCPU: Bool {
    hasEnoughSamples && !repeatedHighCPUProcesses.isEmpty
  }
}

private struct PerformanceHistorySample {
  var timestamp: Date
  var cpuPercent: Double?
  var memoryPercent: Double
  var cpuProcesses: [ProcessSample]
  var memoryProcesses: [ProcessSample]
}
