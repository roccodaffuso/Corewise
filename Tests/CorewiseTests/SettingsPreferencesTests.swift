// SPDX-License-Identifier: MPL-2.0

import Foundation
import Testing
@testable import Corewise

@Test func settingsPreferenceKeysAreStable() {
  #expect(CorewiseSettingsKeys.performanceDefaultFocus == "settings.performance.defaultFocus")
  #expect(CorewiseSettingsKeys.reportDefaultFormat == "settings.report.defaultFormat")
  #expect(CorewiseSettingsKeys.reportIncludeStorageScan == "settings.report.includeStorageScan")
  #expect(CorewiseSettingsKeys.reportIncludeCrashSummary == "settings.report.includeCrashSummary")
  #expect(CorewiseSettingsKeys.storageAutomaticClassificationBookmark == "settings.storage.automaticClassificationBookmark")
  #expect(CorewiseSettingsKeys.storageAutomaticClassificationTitle == "settings.storage.automaticClassificationTitle")
  #expect(CorewiseSettingsKeys.menuBarShowCPU == "settings.menuBar.showCPU")
  #expect(CorewiseSettingsKeys.menuBarShowMemory == "settings.menuBar.showMemory")
  #expect(CorewiseSettingsKeys.menuBarShowSwap == "settings.menuBar.showSwap")
  #expect(CorewiseSettingsKeys.menuBarShowAIWorkloads == "settings.menuBar.showAIWorkloads")
  #expect(CorewiseSettingsKeys.menuBarShowTopCPU == "settings.menuBar.showTopCPU")
  #expect(CorewiseSettingsKeys.menuBarShowTopMemory == "settings.menuBar.showTopMemory")
  #expect(CorewiseSettingsKeys.menuBarProcessRowCount == "settings.menuBar.processRowCount")
}

@MainActor
@Test func rememberedStorageScopeIsOffWithoutBookmark() {
  UserDefaults.standard.removeObject(forKey: CorewiseSettingsKeys.storageAutomaticClassificationBookmark)
  UserDefaults.standard.removeObject(forKey: CorewiseSettingsKeys.storageAutomaticClassificationTitle)

  let store = HealthDashboardStore(collector: SystemHealthCollector())

  #expect(store.rememberedStorageScopeEnabled == false)
  #expect(store.rememberedStorageScopeTitle == nil)
}

@MainActor
@Test func fullStorageAccessRequestOpensSettingsOnceAndWaitsForReturn() {
  var settingsOpenCount = 0
  let store = HealthDashboardStore(
    collector: SystemHealthCollector(),
    openFullDiskAccessSettings: { settingsOpenCount += 1 }
  )

  store.requestFullStorageAnalysisAccess()

  #expect(settingsOpenCount == 1)
  #expect(store.isAwaitingFullDiskAccess)
  #expect(store.storageAccessSummary.contains("return here"))
}

@Test func settingsRawValuesFallbackToSafeDefaults() {
  #expect(PerformanceDefaultFocus.cpu.rawValue == "cpu")
  #expect(PerformanceDefaultFocus.memory.rawValue == "memory")
  #expect(PerformanceDefaultFocus.aiWorkloads.rawValue == "aiWorkloads")
  #expect(PerformanceDefaultFocus.normalized("memory") == .memory)
  #expect(PerformanceDefaultFocus.normalized("aiWorkloads") == .aiWorkloads)
  #expect(PerformanceDefaultFocus.normalized("unknown") == .cpu)

  #expect(MenuBarPreferences.normalizedProcessRowCount(0) == 1)
  #expect(MenuBarPreferences.normalizedProcessRowCount(3) == 3)
  #expect(MenuBarPreferences.normalizedProcessRowCount(8) == 5)

  #expect(ReportFormatPreference.summary.rawValue == "summary")
  #expect(ReportFormatPreference.markdown.rawValue == "markdown")
  #expect(ReportFormatPreference.normalized("markdown") == .markdown)
  #expect(ReportFormatPreference.normalized("unknown") == .summary)
}

@Test func diagnosticReportOptionsCanExcludeOptionalSections() async throws {
  let snapshot = try await SystemHealthCollector().currentSnapshot()
  let options = DiagnosticReportOptions(
    includeStorageScan: false,
    includeCrashSummary: false
  )
  let builder = DiagnosticReportBuilder()
  let summary = builder.summary(for: snapshot, options: options)
  let markdown = builder.markdown(for: snapshot, options: options)

  #expect(summary.contains("Storage scan: Excluded by Settings"))
  #expect(summary.contains("Crash reports: Excluded by Settings"))
  #expect(markdown.contains("Selected scan:\nExcluded by Settings."))
  #expect(markdown.contains("## App Issues"))
  #expect(markdown.contains("Excluded by Settings."))
}
