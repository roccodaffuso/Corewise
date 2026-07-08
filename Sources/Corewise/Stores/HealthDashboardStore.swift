import Combine
import Foundation

@MainActor
final class HealthDashboardStore: ObservableObject {
  @Published private(set) var snapshot: HealthSnapshot?
  @Published private(set) var isRefreshing = false
  @Published private(set) var errorMessage: String?

  private let collector: SystemHealthCollecting

  init(collector: SystemHealthCollecting) {
    self.collector = collector
  }

  func refresh() async {
    isRefreshing = true
    errorMessage = nil

    do {
      snapshot = try await collector.currentSnapshot()
    } catch {
      errorMessage = error.localizedDescription
    }

    isRefreshing = false
  }

  func startLiveRefresh(intervalSeconds: UInt64 = 2) async {
    await refresh()

    while !Task.isCancelled {
      try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
      await refresh()
    }
  }
}
