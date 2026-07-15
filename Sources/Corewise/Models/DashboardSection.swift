// SPDX-License-Identifier: MPL-2.0

import Foundation

enum DashboardSection: String, CaseIterable, Identifiable, Hashable, Sendable {
  case overview
  case performance
  case storage
  case battery
  case startup
  case thermal
  case issues
  case report

  var id: String { rawValue }

  static let primary: [DashboardSection] = [.overview, .performance, .storage]
  static let system: [DashboardSection] = [.battery, .startup, .thermal, .issues]
  static let utility: [DashboardSection] = [.report]

  var title: String {
    switch self {
    case .overview: "Overview"
    case .performance: "Performance"
    case .storage: "Storage"
    case .battery: "Battery"
    case .startup: "Startup"
    case .thermal: "Thermal"
    case .issues: "App Issues"
    case .report: "Report"
    }
  }

  var systemImage: String {
    switch self {
    case .overview: "waveform.path.ecg"
    case .performance: "cpu"
    case .storage: "internaldrive"
    case .battery: "battery.75percent"
    case .startup: "power"
    case .thermal: "thermometer.medium"
    case .issues: "app.badge"
    case .report: "doc.text.magnifyingglass"
    }
  }
}

enum DashboardFocus: Equatable, Sendable {
  case process(pid: Int32, mode: PerformanceMode)
  case appGroup(id: String, mode: PerformanceMode)
  case storageCategory(StorageCategory)
  case storagePath(String)
}

struct DashboardRoute: Equatable, Sendable {
  var section: DashboardSection
  var performanceMode: PerformanceMode?
  var focus: DashboardFocus?

  init(section: DashboardSection, performanceMode: PerformanceMode? = nil, focus: DashboardFocus? = nil) {
    self.section = section
    self.performanceMode = performanceMode
    self.focus = focus
  }
}
