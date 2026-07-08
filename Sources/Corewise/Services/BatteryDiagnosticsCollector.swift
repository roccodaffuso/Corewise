import Foundation
import IOKit
import IOKit.ps

struct BatteryDiagnosticsCollector {
  private var powerSources: () -> [BatteryPowerSourceDescription]
  private var registrySnapshot: () -> BatteryRegistrySnapshot?

  init(
    powerSources: @escaping () -> [BatteryPowerSourceDescription] = BatteryDiagnosticsCollector.readPowerSources,
    registrySnapshot: @escaping () -> BatteryRegistrySnapshot? = BatteryDiagnosticsCollector.readRegistrySnapshot
  ) {
    self.powerSources = powerSources
    self.registrySnapshot = registrySnapshot
  }

  func currentBattery(now: Date) -> BatteryHealth {
    guard let battery = powerSources().first(where: \.isInternalBattery) else {
      return noBattery(now: now)
    }

    let registry = registrySnapshot()
    let charge = chargeMetric(battery, now: now)
    let metrics = [
      charge,
      cycleCountMetric(registry, now: now),
      maximumCapacityMetric(registry, now: now),
      conditionMetric(registry, now: now),
      powerSourceMetric(battery, now: now),
      chargingStateMetric(battery, now: now),
      metric("Recent Energy Impact", "Planned", "", .planned, .info, 0, "Recent energy impact needs a separate safe process-energy source before it can be trusted.", "Energy impact collector", "Planned / medium", "Use Activity Monitor's Energy tab for now.", now),
      metric("Battery Risk", "Planned", "", .planned, .info, 0, "Battery risk remains unscored until capacity, condition, and trend signals are available from safe sources.", "Corewise scoring model", "Planned / high", "Trust the live battery basics first; do not treat this as health scoring.", now)
    ]

    return BatteryHealth(
      summary: charge,
      metrics: metrics,
      findings: [
        DiagnosticFinding(title: "Battery basics are live", detail: "Charge, power source, and charging state come from macOS power-source data when available.", status: .good, severityScore: 8),
        DiagnosticFinding(title: "Health details are opportunistic", detail: "Cycle count, maximum capacity, and condition appear only when safe registry keys are present and internally plausible.", status: .info, severityScore: 0)
      ],
      actions: [
        SafeAction(title: "Use macOS for service status", body: "For battery service decisions, rely on System Settings until Corewise can read documented health data safely.", systemImage: "battery.75percent", status: .info),
        SafeAction(title: "Watch live charge state", body: "Use the live charge and charging state as context, not as a battery-health diagnosis.", systemImage: "bolt.horizontal", status: .good)
      ],
      sourceNote: "Mixed data. Charge, power source, and charging state are live from IOKit power source APIs when an internal battery is present. Health details appear only when safe registry values are present and plausible."
    )
  }

  private static func readPowerSources() -> [BatteryPowerSourceDescription] {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
      return []
    }

    return list.compactMap { source in
      guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else {
        return nil
      }
      return BatteryPowerSourceDescription(dictionary: description)
    }
  }

  private static func readRegistrySnapshot() -> BatteryRegistrySnapshot? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    guard service != 0 else {
      return nil
    }
    defer { IOObjectRelease(service) }

    return BatteryRegistrySnapshot(
      cycleCount: intProperty("CycleCount", service: service),
      maxCapacity: intProperty("MaxCapacity", service: service),
      designCapacity: intProperty("DesignCapacity", service: service),
      condition: stringProperty("BatteryHealth", service: service) ?? stringProperty("BatteryHealthCondition", service: service)
    )
  }

  private static func intProperty(_ key: String, service: io_registry_entry_t) -> Int? {
    guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
      return nil
    }

    if let intValue = value as? Int {
      return intValue
    }
    if let number = value as? NSNumber {
      return number.intValue
    }
    return nil
  }

  private static func stringProperty(_ key: String, service: io_registry_entry_t) -> String? {
    IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
  }

  private func noBattery(now: Date) -> BatteryHealth {
    let summary = metric("Battery", "Not Detected", "", .unavailable, .info, 0, "No internal battery was found in the safe power-source snapshot.", "IOKit power source snapshot", "Unavailable / high", "No battery action is needed on Macs without an internal battery.", now)
    let metrics = [
      summary,
      metric("Charge", "Unavailable", "%", .unavailable, .info, 0, "Charge is unavailable because no internal battery was detected.", "IOKit power source snapshot", "Unavailable / high", "No action needed.", now),
      metric("Power Source", "Unavailable", "", .unavailable, .info, 0, "Battery power-source state is unavailable without an internal battery.", "IOKit power source snapshot", "Unavailable / high", "No action needed.", now),
      metric("Charging State", "Unavailable", "", .unavailable, .info, 0, "Charging state is unavailable because no internal battery was detected.", "IOKit power source snapshot", "Unavailable / high", "No action needed.", now),
      metric("Cycle Count", "Unavailable", "cycles", .unavailable, .info, 0, "Cycle count is unavailable because no internal battery was detected.", "IOKit power source snapshot", "Unavailable / high", "No action needed.", now),
      metric("Maximum Capacity", "Unavailable", "%", .unavailable, .info, 0, "Maximum capacity is unavailable because no internal battery was detected.", "IOKit power source snapshot", "Unavailable / high", "No action needed.", now),
      metric("Condition", "Unavailable", "", .unavailable, .info, 0, "Battery condition is unavailable because no internal battery was detected.", "IOKit power source snapshot", "Unavailable / high", "No action needed.", now),
      metric("Recent Energy Impact", "Planned", "", .planned, .info, 0, "Recent energy impact needs a separate safe process-energy source before it can be trusted.", "Energy impact collector", "Planned / medium", "Use Activity Monitor's Energy tab for now.", now),
      metric("Battery Risk", "Unavailable", "", .unavailable, .info, 0, "Battery risk is unavailable because there is no internal battery to score.", "Corewise scoring model", "Unavailable / high", "No action needed.", now)
    ]

    return BatteryHealth(
      summary: summary,
      metrics: metrics,
      findings: [
        DiagnosticFinding(title: "No internal battery detected", detail: "Corewise did not find a battery in macOS power-source data.", status: .info, severityScore: 0)
      ],
      actions: [
        SafeAction(title: "No battery review needed", body: "This page stays informational on Macs without an internal battery.", systemImage: "desktopcomputer", status: .good)
      ],
      sourceNote: "Unavailable data. Corewise did not find an internal battery in IOKit power source data, so it does not invent charge or health values."
    )
  }

  private func chargeMetric(_ battery: BatteryPowerSourceDescription, now: Date) -> DiagnosticMetric {
    guard let percent = battery.chargePercent else {
      return metric("Charge", "Unavailable", "%", .unavailable, .info, 0, "Charge percentage was missing from the power-source snapshot.", "IOKit power source snapshot", "Unavailable / medium", "Check macOS battery settings if you need the current charge.", now)
    }

    return metric("Charge", number(percent), "%", .live, chargeStatus(percent), chargeSeverity(percent), "Current battery charge reported by macOS power-source data.", "IOKit power source snapshot", "Live / high", "No action needed unless the charge is low for your current work.", now)
  }

  private func powerSourceMetric(_ battery: BatteryPowerSourceDescription, now: Date) -> DiagnosticMetric {
    guard let state = battery.powerSourceState else {
      return metric("Power Source", "Unavailable", "", .unavailable, .info, 0, "Power source state was missing from the power-source snapshot.", "IOKit power source snapshot", "Unavailable / medium", "Use macOS menu bar battery status for confirmation.", now)
    }

    return metric("Power Source", displayPowerSource(state), "", .live, state == "Battery Power" ? .info : .good, state == "Battery Power" ? 18 : 4, "Current power source reported by macOS.", "IOKit power source snapshot", "Live / high", "Connect power before long heavy work if running on battery.", now)
  }

  private func cycleCountMetric(_ registry: BatteryRegistrySnapshot?, now: Date) -> DiagnosticMetric {
    guard let cycleCount = registry?.cycleCount else {
      return metric("Cycle Count", "Unavailable", "cycles", .unavailable, .info, 0, "Cycle count was not present in the safe battery registry snapshot.", "IOKit battery registry", "Unavailable / medium", "Use macOS battery settings for service guidance.", now)
    }

    return metric("Cycle Count", "\(cycleCount)", "cycles", .live, cycleCount >= 900 ? .warning : .good, min(cycleCount / 10, 100), "Cycle count found in read-only battery registry data.", "IOKit battery registry", "Live / medium", "Use this as context; service decisions should still follow macOS guidance.", now)
  }

  private func maximumCapacityMetric(_ registry: BatteryRegistrySnapshot?, now: Date) -> DiagnosticMetric {
    guard let percent = registry?.maximumCapacityPercent else {
      return metric("Maximum Capacity", "Unavailable", "%", .unavailable, .info, 0, "Maximum capacity could not be derived from safe battery registry keys.", "IOKit battery registry", "Unavailable / medium", "Do not infer battery health without a documented value.", now)
    }

    return metric("Maximum Capacity", number(percent), "%", .live, percent < 80 ? .warning : .good, min(max(Int((100 - percent).rounded()), 0), 100), "Maximum capacity derived from read-only registry capacity keys.", "IOKit battery registry", "Live / medium", "Confirm service status in macOS before making battery decisions.", now)
  }

  private func conditionMetric(_ registry: BatteryRegistrySnapshot?, now: Date) -> DiagnosticMetric {
    guard let condition = registry?.condition, !condition.isEmpty else {
      return metric("Condition", "Unavailable", "", .unavailable, .info, 0, "Battery condition was not present in the safe battery registry snapshot.", "IOKit battery registry", "Unavailable / medium", "Use macOS battery settings for service status.", now)
    }

    let normalized = condition.localizedCaseInsensitiveContains("good") ? .good : FindingSeverity.info
    return metric("Condition", condition, "", .live, normalized, normalized == .good ? 6 : 28, "Battery condition string found in read-only registry data.", "IOKit battery registry", "Live / medium", "Treat this as context unless macOS explicitly recommends service.", now)
  }

  private func chargingStateMetric(_ battery: BatteryPowerSourceDescription, now: Date) -> DiagnosticMetric {
    guard let isCharging = battery.isCharging else {
      return metric("Charging State", "Unavailable", "", .unavailable, .info, 0, "Charging state was missing from the power-source snapshot.", "IOKit power source snapshot", "Unavailable / medium", "Use macOS menu bar battery status for confirmation.", now)
    }

    let value = isCharging ? "Charging" : "Not Charging"
    return metric("Charging State", value, "", .live, isCharging ? .good : .info, isCharging ? 4 : 16, "Charging state reported by macOS power-source data.", "IOKit power source snapshot", "Live / high", "No action unless this differs from what you expect.", now)
  }

  private func metric(
    _ title: String,
    _ value: String,
    _ unit: String,
    _ dataMode: DataMode,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date
  ) -> DiagnosticMetric {
    DiagnosticMetric(
      title: title,
      value: value,
      unit: unit,
      dataMode: dataMode,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func displayPowerSource(_ state: String) -> String {
    switch state {
    case "AC Power":
      return "AC Power"
    case "Battery Power":
      return "Battery Power"
    default:
      return state.localizedCaseInsensitiveContains("ups") ? "UPS Power" : "Unknown"
    }
  }

  private func chargeStatus(_ percent: Double) -> FindingSeverity {
    if percent <= 10 {
      return .critical
    }
    if percent <= 20 {
      return .warning
    }
    if percent <= 40 {
      return .info
    }
    return .good
  }

  private func chargeSeverity(_ percent: Double) -> Int {
    min(max(Int((100 - percent).rounded()), 0), 100)
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }
}

struct BatteryPowerSourceDescription {
  var isInternalBattery: Bool
  var currentCapacity: Int?
  var maxCapacity: Int?
  var powerSourceState: String?
  var isCharging: Bool?

  init(
    isInternalBattery: Bool,
    currentCapacity: Int? = nil,
    maxCapacity: Int? = nil,
    powerSourceState: String? = nil,
    isCharging: Bool? = nil
  ) {
    self.isInternalBattery = isInternalBattery
    self.currentCapacity = currentCapacity
    self.maxCapacity = maxCapacity
    self.powerSourceState = powerSourceState
    self.isCharging = isCharging
  }

  init(dictionary: [String: Any]) {
    let type = dictionary[kIOPSTypeKey as String] as? String
    isInternalBattery = type == (kIOPSInternalBatteryType as String)
    currentCapacity = dictionary[kIOPSCurrentCapacityKey as String] as? Int
    maxCapacity = dictionary[kIOPSMaxCapacityKey as String] as? Int
    powerSourceState = dictionary[kIOPSPowerSourceStateKey as String] as? String
    isCharging = dictionary[kIOPSIsChargingKey as String] as? Bool
  }

  var chargePercent: Double? {
    guard let currentCapacity, let maxCapacity, maxCapacity > 0 else {
      return nil
    }

    return min(max(Double(currentCapacity) / Double(maxCapacity) * 100, 0), 100)
  }
}

struct BatteryRegistrySnapshot {
  var cycleCount: Int? = nil
  var maxCapacity: Int? = nil
  var designCapacity: Int? = nil
  var condition: String? = nil

  var maximumCapacityPercent: Double? {
    guard let maxCapacity, let designCapacity, designCapacity > 0 else {
      return nil
    }

    let percent = Double(maxCapacity) / Double(designCapacity) * 100
    guard percent >= 50, percent <= 120 else {
      return nil
    }

    return min(percent, 100)
  }
}
