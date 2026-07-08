import Foundation
import IOKit.ps
import Testing
@testable import Corewise

@Test func noBatteryProducesUnavailableMetricsWithoutFakeValues() {
  let battery = BatteryDiagnosticsCollector(powerSources: { [] }).currentBattery(now: Date())

  #expect(battery.summary.dataMode == .unavailable)
  #expect(battery.summary.value == "Not Detected")
  #expect(battery.metrics.first { $0.title == "Charge" }?.dataMode == .unavailable)
  #expect(battery.metrics.first { $0.title == "Power Source" }?.dataMode == .unavailable)
  #expect(battery.metrics.first { $0.title == "Charging State" }?.dataMode == .unavailable)
  #expect(battery.metrics.first { $0.title == "Battery Risk" }?.dataMode == .unavailable)
}

@Test func batteryRegistrySnapshotProducesLiveHealthContext() throws {
  let dictionary: [String: Any] = [
    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
    kIOPSCurrentCapacityKey as String: 80,
    kIOPSMaxCapacityKey as String: 100,
    kIOPSPowerSourceStateKey as String: kIOPSBatteryPowerValue as String,
    kIOPSIsChargingKey as String: false
  ]

  let battery = BatteryDiagnosticsCollector(
    powerSources: { [BatteryPowerSourceDescription(dictionary: dictionary)] },
    registrySnapshot: {
      BatteryRegistrySnapshot(cycleCount: 120, maxCapacity: 4500, designCapacity: 5000, condition: "Good")
    }
  ).currentBattery(now: Date())

  let cycles = try #require(battery.metrics.first { $0.title == "Cycle Count" })
  let capacity = try #require(battery.metrics.first { $0.title == "Maximum Capacity" })
  let condition = try #require(battery.metrics.first { $0.title == "Condition" })

  #expect(cycles.dataMode == .live)
  #expect(cycles.value == "120")
  #expect(capacity.dataMode == .live)
  #expect(capacity.value == "90")
  #expect(condition.dataMode == .live)
  #expect(condition.value == "Good")
}

@Test func missingBatteryRegistryKeysRemainUnavailable() throws {
  let dictionary: [String: Any] = [
    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
    kIOPSCurrentCapacityKey as String: 80,
    kIOPSMaxCapacityKey as String: 100
  ]

  let battery = BatteryDiagnosticsCollector(
    powerSources: { [BatteryPowerSourceDescription(dictionary: dictionary)] },
    registrySnapshot: { BatteryRegistrySnapshot() }
  ).currentBattery(now: Date())

  #expect(battery.metrics.first { $0.title == "Cycle Count" }?.dataMode == .unavailable)
  #expect(battery.metrics.first { $0.title == "Maximum Capacity" }?.dataMode == .unavailable)
  #expect(battery.metrics.first { $0.title == "Condition" }?.dataMode == .unavailable)
}

@Test func implausibleBatteryCapacityRatioRemainsUnavailable() throws {
  let dictionary: [String: Any] = [
    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
    kIOPSCurrentCapacityKey as String: 80,
    kIOPSMaxCapacityKey as String: 100
  ]

  let battery = BatteryDiagnosticsCollector(
    powerSources: { [BatteryPowerSourceDescription(dictionary: dictionary)] },
    registrySnapshot: {
      BatteryRegistrySnapshot(cycleCount: 120, maxCapacity: 110, designCapacity: 5000, condition: "Good")
    }
  ).currentBattery(now: Date())

  let capacity = try #require(battery.metrics.first { $0.title == "Maximum Capacity" })

  #expect(capacity.dataMode == .unavailable)
  #expect(capacity.value == "Unavailable")
}

@Test func batteryDictionaryProducesLiveChargeSourceAndChargingState() throws {
  let dictionary: [String: Any] = [
    kIOPSTypeKey as String: kIOPSInternalBatteryType as String,
    kIOPSCurrentCapacityKey as String: 48,
    kIOPSMaxCapacityKey as String: 96,
    kIOPSPowerSourceStateKey as String: kIOPSACPowerValue as String,
    kIOPSIsChargingKey as String: true
  ]

  let battery = BatteryDiagnosticsCollector(powerSources: {
    [BatteryPowerSourceDescription(dictionary: dictionary)]
  }).currentBattery(now: Date())

  let charge = try #require(battery.metrics.first { $0.title == "Charge" })
  let source = try #require(battery.metrics.first { $0.title == "Power Source" })
  let charging = try #require(battery.metrics.first { $0.title == "Charging State" })

  #expect(charge.dataMode == .live)
  #expect(charge.value == "50")
  #expect(source.dataMode == .live)
  #expect(source.value == "AC Power")
  #expect(charging.dataMode == .live)
  #expect(charging.value == "Charging")
}

@Test func batteryMissingKeysUseUnavailableInsteadOfFallbackValues() throws {
  let dictionary: [String: Any] = [
    kIOPSTypeKey as String: kIOPSInternalBatteryType as String
  ]

  let battery = BatteryDiagnosticsCollector(powerSources: {
    [BatteryPowerSourceDescription(dictionary: dictionary)]
  }).currentBattery(now: Date())

  let charge = try #require(battery.metrics.first { $0.title == "Charge" })
  let source = try #require(battery.metrics.first { $0.title == "Power Source" })
  let charging = try #require(battery.metrics.first { $0.title == "Charging State" })

  #expect(charge.dataMode == .unavailable)
  #expect(source.dataMode == .unavailable)
  #expect(charging.dataMode == .unavailable)
  #expect(charge.value == "Unavailable")
  #expect(source.value == "Unavailable")
  #expect(charging.value == "Unavailable")
}
