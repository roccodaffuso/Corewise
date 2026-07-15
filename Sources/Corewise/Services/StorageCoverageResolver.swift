// SPDX-License-Identifier: MPL-2.0

import Foundation

enum StorageCoverageResolver {
  static func resolve(
    volume: StorageHealth,
    result: StorageScanResult,
    accessStatus: StorageAccessStatus,
    source: String
  ) -> StorageCoverageSummary {
    let classified = min(max(result.totalSizeGB, 0), max(volume.usedGB, 0))
    let outside = max(volume.usedGB - classified, 0)
    let ratio = volume.usedGB > 0 ? min(max(classified / volume.usedGB, 0), 1) : 0
    let scopeDescription: String
    switch accessStatus {
    case .fullDiskAccessLikelyGranted:
      scopeDescription = "Curated standard scopes available through Full Disk Access"
    case .folderScopeGranted:
      scopeDescription = "One remembered folder scope"
    case .notRequested, .needsFullDiskAccess, .unavailable:
      scopeDescription = "Limited approved scope"
    }

    return StorageCoverageSummary(
      volumeUsedGB: volume.usedGB,
      classifiedApprovedScopeGB: classified,
      outsideApprovedScopeGB: outside,
      coverageRatio: ratio,
      inaccessibleItemCount: result.inaccessibleItemCount,
      scopeDescription: scopeDescription,
      source: source
    )
  }
}
