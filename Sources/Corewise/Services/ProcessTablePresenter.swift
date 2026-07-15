// SPDX-License-Identifier: MPL-2.0

import Foundation

enum ProcessTablePresenter {
  enum Sort: String, CaseIterable, Identifiable {
    case cpu = "CPU Now"
    case cpuTime = "CPU Time"
    case memory = "Observed Memory"
    case footprint = "Footprint"
    case resident = "RSS"
    case pageIns = "Page-ins"
    case name = "Name"
    case threads = "Threads"

    var id: String { rawValue }
  }

  static func availableSorts(for mode: PerformanceMode) -> [Sort] {
    switch mode {
    case .cpu:
      [.cpu, .cpuTime, .threads, .name]
    case .memory:
      [.memory, .footprint, .resident, .pageIns, .name]
    case .aiWorkloads:
      []
    }
  }

  static func defaultSort(for mode: PerformanceMode) -> Sort {
    mode == .cpu ? .cpu : .memory
  }

  static func presented(
    _ processes: [ProcessObservation],
    mode: PerformanceMode,
    query: String,
    sort: Sort
  ) -> [ProcessObservation] {
    let eligible = processes.filter { process in
      switch mode {
      case .cpu:
        process.cpuPercent >= 0.05
      case .memory:
        process.observedMemoryBytes >= 20 * 1024 * 1024
      case .aiWorkloads:
        false
      }
    }
    return sorted(filtered(eligible, query: query), by: sort)
  }

  static func filtered(_ processes: [ProcessObservation], query: String) -> [ProcessObservation] {
    guard !query.isEmpty else { return processes }
    return processes.filter {
      $0.displayName.localizedStandardContains(query)
        || $0.user.localizedStandardContains(query)
        || ($0.path?.localizedStandardContains(query) ?? false)
        || String($0.pid).localizedStandardContains(query)
    }
  }

  static func sorted(_ processes: [ProcessObservation], by sort: Sort) -> [ProcessObservation] {
    processes.sorted { lhs, rhs in
      switch sort {
      case .cpu where lhs.cpuPercent != rhs.cpuPercent:
        return lhs.cpuPercent > rhs.cpuPercent
      case .cpuTime where lhs.cpuTimeSeconds != rhs.cpuTimeSeconds:
        return lhs.cpuTimeSeconds > rhs.cpuTimeSeconds
      case .memory where lhs.observedMemoryBytes != rhs.observedMemoryBytes:
        return lhs.observedMemoryBytes > rhs.observedMemoryBytes
      case .footprint where lhs.physicalFootprintBytes != rhs.physicalFootprintBytes:
        return (lhs.physicalFootprintBytes ?? 0) > (rhs.physicalFootprintBytes ?? 0)
      case .resident where lhs.residentMemoryBytes != rhs.residentMemoryBytes:
        return lhs.residentMemoryBytes > rhs.residentMemoryBytes
      case .pageIns where lhs.pageIns != rhs.pageIns:
        return lhs.pageIns > rhs.pageIns
      case .threads where lhs.threadCount != rhs.threadCount:
        return lhs.threadCount > rhs.threadCount
      default:
        let nameOrder = lhs.displayName.localizedStandardCompare(rhs.displayName)
        if nameOrder != .orderedSame {
          return nameOrder == .orderedAscending
        }
        return lhs.pid < rhs.pid
      }
    }
  }
}
