import Foundation

struct SlowHealthSnapshot {
  var battery: BatteryHealth
  var storage: StorageHealth
  var startup: StartupHealth
  var appIssues: AppIssuesHealth
}

final class SlowHealthSnapshotCache {
  private var battery: BatteryHealth?
  private var batteryUpdatedAt: Date?
  private var storage: StorageHealth?
  private var storageUpdatedAt: Date?
  private var startup: StartupHealth?
  private var startupUpdatedAt: Date?
  private var appIssues: AppIssuesHealth?

  private let batteryInterval: TimeInterval
  private let storageInterval: TimeInterval
  private let startupInterval: TimeInterval

  init(
    batteryInterval: TimeInterval = 60,
    storageInterval: TimeInterval = 30,
    startupInterval: TimeInterval = 5 * 60
  ) {
    self.batteryInterval = batteryInterval
    self.storageInterval = storageInterval
    self.startupInterval = startupInterval
  }

  func snapshot(now: Date) -> SlowHealthSnapshot {
    if Self.shouldRefresh(lastUpdated: batteryUpdatedAt, now: now, interval: batteryInterval) {
      battery = BatteryDiagnosticsCollector().currentBattery(now: now)
      batteryUpdatedAt = now
    }

    if Self.shouldRefresh(lastUpdated: storageUpdatedAt, now: now, interval: storageInterval) {
      storage = StorageDiagnosticsCollector().currentStorage(now: now)
      storageUpdatedAt = now
    }

    if Self.shouldRefresh(lastUpdated: startupUpdatedAt, now: now, interval: startupInterval) {
      startup = StartupDiagnosticsCollector().currentStartup(now: now)
      startupUpdatedAt = now
    }

    if appIssues == nil {
      appIssues = CrashReportDiagnosticsCollector().unavailableAppIssues(now: now)
    }

    return SlowHealthSnapshot(
      battery: battery ?? BatteryDiagnosticsCollector().currentBattery(now: now),
      storage: storage ?? StorageDiagnosticsCollector().currentStorage(now: now),
      startup: startup ?? StartupDiagnosticsCollector().currentStartup(now: now),
      appIssues: appIssues ?? CrashReportDiagnosticsCollector().unavailableAppIssues(now: now)
    )
  }

  static func shouldRefresh(lastUpdated: Date?, now: Date, interval: TimeInterval) -> Bool {
    guard let lastUpdated else {
      return true
    }
    return now.timeIntervalSince(lastUpdated) >= interval
  }
}
