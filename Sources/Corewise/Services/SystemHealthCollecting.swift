@MainActor
protocol SystemHealthCollecting {
  func currentSnapshot() async throws -> HealthSnapshot
}
