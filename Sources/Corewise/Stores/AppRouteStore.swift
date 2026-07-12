import Observation

@MainActor
@Observable
final class AppRouteStore {
  private(set) var requestedRoute: DashboardRoute?

  func show(_ section: DashboardSection, performanceMode: PerformanceMode? = nil) {
    requestedRoute = DashboardRoute(section: section, performanceMode: performanceMode)
  }

  func show(_ route: DashboardRoute) {
    requestedRoute = route
  }

  func consume() {
    requestedRoute = nil
  }
}
