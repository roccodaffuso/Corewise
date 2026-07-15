// SPDX-License-Identifier: MPL-2.0

enum CorewiseSettingsKeys {
  static let performanceDefaultFocus = "settings.performance.defaultFocus"
  static let reportDefaultFormat = "settings.report.defaultFormat"
  static let reportIncludeStorageScan = "settings.report.includeStorageScan"
  static let reportIncludeCrashSummary = "settings.report.includeCrashSummary"
  static let storageAutomaticClassificationBookmark = "settings.storage.automaticClassificationBookmark"
  static let storageAutomaticClassificationTitle = "settings.storage.automaticClassificationTitle"
  static let menuBarShowCPU = "settings.menuBar.showCPU"
  static let menuBarShowMemory = "settings.menuBar.showMemory"
  static let menuBarShowSwap = "settings.menuBar.showSwap"
  static let menuBarShowAIWorkloads = "settings.menuBar.showAIWorkloads"
  static let menuBarShowTopCPU = "settings.menuBar.showTopCPU"
  static let menuBarShowTopMemory = "settings.menuBar.showTopMemory"
  static let menuBarProcessRowCount = "settings.menuBar.processRowCount"
}

enum PerformanceDefaultFocus: String, CaseIterable, Identifiable {
  case cpu
  case memory
  case aiWorkloads

  var id: String { rawValue }

  var title: String {
    switch self {
    case .cpu: "CPU"
    case .memory: "Memory"
    case .aiWorkloads: "AI Workloads"
    }
  }

  static func normalized(_ rawValue: String) -> PerformanceDefaultFocus {
    PerformanceDefaultFocus(rawValue: rawValue) ?? .cpu
  }
}

enum MenuBarPreferences {
  static let defaultProcessRowCount = 3
  static let allowedProcessRowCount = 1...5

  static func normalizedProcessRowCount(_ value: Int) -> Int {
    min(max(value, allowedProcessRowCount.lowerBound), allowedProcessRowCount.upperBound)
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
