import Testing
@testable import Corewise

@Test func settingsPreferenceKeysAreStable() {
  #expect(CorewiseSettingsKeys.performanceDefaultFocus == "settings.performance.defaultFocus")
  #expect(CorewiseSettingsKeys.reportDefaultFormat == "settings.report.defaultFormat")
  #expect(CorewiseSettingsKeys.reportIncludeStorageScan == "settings.report.includeStorageScan")
  #expect(CorewiseSettingsKeys.reportIncludeCrashSummary == "settings.report.includeCrashSummary")
  #expect(CorewiseSettingsKeys.menuBarShowCPU == "settings.menuBar.showCPU")
  #expect(CorewiseSettingsKeys.menuBarShowMemory == "settings.menuBar.showMemory")
  #expect(CorewiseSettingsKeys.menuBarShowSwap == "settings.menuBar.showSwap")
  #expect(CorewiseSettingsKeys.menuBarShowTopCPU == "settings.menuBar.showTopCPU")
  #expect(CorewiseSettingsKeys.menuBarShowTopMemory == "settings.menuBar.showTopMemory")
}

@Test func settingsRawValuesFallbackToSafeDefaults() {
  #expect(PerformanceDefaultFocus.cpu.rawValue == "cpu")
  #expect(PerformanceDefaultFocus.memory.rawValue == "memory")
  #expect(PerformanceDefaultFocus.normalized("memory") == .memory)
  #expect(PerformanceDefaultFocus.normalized("unknown") == .cpu)

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
