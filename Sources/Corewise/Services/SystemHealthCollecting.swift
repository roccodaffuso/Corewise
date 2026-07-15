// SPDX-License-Identifier: MPL-2.0

@MainActor
protocol SystemHealthCollecting {
  func currentSnapshot() async throws -> HealthSnapshot
}
