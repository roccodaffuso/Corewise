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
