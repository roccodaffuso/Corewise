enum CorewiseSettingsKeys {
  static let performanceDefaultFocus = "settings.performance.defaultFocus"
  static let reportDefaultFormat = "settings.report.defaultFormat"
  static let reportIncludeStorageScan = "settings.report.includeStorageScan"
  static let reportIncludeCrashSummary = "settings.report.includeCrashSummary"
  static let menuBarShowCPU = "settings.menuBar.showCPU"
  static let menuBarShowMemory = "settings.menuBar.showMemory"
  static let menuBarShowSwap = "settings.menuBar.showSwap"
  static let menuBarShowTopCPU = "settings.menuBar.showTopCPU"
  static let menuBarShowTopMemory = "settings.menuBar.showTopMemory"
}

enum PerformanceDefaultFocus: String, CaseIterable, Identifiable {
  case cpu
  case memory

  var id: String { rawValue }

  var title: String {
    switch self {
    case .cpu: "CPU"
    case .memory: "Memory"
    }
  }

  static func normalized(_ rawValue: String) -> PerformanceDefaultFocus {
    PerformanceDefaultFocus(rawValue: rawValue) ?? .cpu
  }
}

enum ReportFormatPreference: String, CaseIterable, Identifiable {
  case summary
  case markdown

  var id: String { rawValue }

  var title: String {
    switch self {
    case .summary: "Summary"
    case .markdown: "Markdown"
    }
  }

  static func normalized(_ rawValue: String) -> ReportFormatPreference {
    ReportFormatPreference(rawValue: rawValue) ?? .summary
  }
}

struct DiagnosticReportOptions: Equatable {
  var includeStorageScan: Bool
  var includeCrashSummary: Bool

  static let `default` = DiagnosticReportOptions(
    includeStorageScan: true,
    includeCrashSummary: true
  )
}
