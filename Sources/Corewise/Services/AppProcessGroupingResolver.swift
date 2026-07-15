// SPDX-License-Identifier: MPL-2.0

import Foundation

enum AppProcessGroupingResolver {
  static func groups(processes: [ProcessObservation], now: Date) -> [AppProcessGroup] {
    let grouped = Dictionary(grouping: processes) { process in
      identity(for: process).id
    }

    return grouped.compactMap { _, rows in
      guard let representative = rows.first else { return nil }
      let identity = identity(for: representative)
      let cpu = rows.reduce(0) { $0 + $1.cpuPercent }
      let resident = rows.reduce(UInt64(0)) { $0 + $1.residentMemoryBytes }
      let footprints = rows.compactMap(\.physicalFootprintBytes)
      let footprint = footprints.isEmpty ? nil : footprints.reduce(UInt64(0), +)
      let observedMemory = max(footprint ?? 0, resident)

      return AppProcessGroup(
        stableID: identity.id,
        name: identity.name,
        bundlePath: identity.bundlePath,
        user: representative.user,
        kind: identity.kind,
        memberPIDs: rows.map(\.pid).sorted(),
        processCount: rows.count,
        cpuPercent: cpu,
        residentMemoryBytes: resident,
        physicalFootprintBytes: footprint,
        dataMode: .live,
        status: SystemMetricsSampler.processStatus(cpuPercent: cpu, memoryBytes: observedMemory),
        severityScore: SystemMetricsSampler.processSeverity(cpuPercent: cpu, memoryBytes: observedMemory),
        source: "Derived from live process rows grouped by normalized bundle path and user when available",
        confidence: footprint == nil ? "Live / medium" : "Live / high",
        lastUpdated: now
      )
    }
    .sorted {
      if ($0.cpuPercent, $0.observedMemoryBytes) != ($1.cpuPercent, $1.observedMemoryBytes) {
        return ($0.cpuPercent, $0.observedMemoryBytes) > ($1.cpuPercent, $1.observedMemoryBytes)
      }
      return $0.id < $1.id
    }
  }

  static func bundlePath(from executablePath: String?) -> String? {
    guard let executablePath else { return nil }
    let components = executablePath.split(separator: "/", omittingEmptySubsequences: true)
    guard let appIndex = components.firstIndex(where: { $0.hasSuffix(".app") }) else {
      return nil
    }
    return "/" + components[...appIndex].joined(separator: "/")
  }

  private static func identity(for process: ProcessObservation) -> GroupIdentity {
    if let bundlePath = bundlePath(from: process.path) {
      let normalized = URL(fileURLWithPath: bundlePath).standardizedFileURL.path.lowercased()
      return GroupIdentity(
        id: "\(process.user.lowercased())|app|\(normalized)",
        name: process.appName ?? URL(fileURLWithPath: bundlePath).deletingPathExtension().lastPathComponent,
        bundlePath: bundlePath,
        kind: .app
      )
    }

    let normalizedName = (process.appName ?? process.displayName).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let isSystem = process.path?.hasPrefix("/System/") == true || process.path?.hasPrefix("/usr/libexec/") == true
    let kind: AppProcessGroupKind = isSystem ? .systemService : (process.path == nil ? .unknown : .standaloneProcess)
    return GroupIdentity(
      id: "\(process.user.lowercased())|\(kind.rawValue)|\(normalizedName)",
      name: process.appName ?? process.displayName,
      bundlePath: nil,
      kind: kind
    )
  }
}

private struct GroupIdentity {
  var id: String
  var name: String
  var bundlePath: String?
  var kind: AppProcessGroupKind
}
