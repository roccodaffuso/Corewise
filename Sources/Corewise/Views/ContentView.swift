import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
  case overview
  case battery
  case storage
  case performance
  case startup
  case thermal
  case issues

  var id: String { rawValue }

  var title: String {
    switch self {
    case .overview: "Overview"
    case .battery: "Battery"
    case .storage: "Storage"
    case .performance: "Performance"
    case .startup: "Startup"
    case .thermal: "Thermal"
    case .issues: "App Issues"
    }
  }

  var detail: String {
    switch self {
    case .overview: "Health status"
    case .battery: "Cycles and capacity"
    case .storage: "Space and large files"
    case .performance: "CPU and memory"
    case .startup: "Login items"
    case .thermal: "Safe signals"
    case .issues: "Crash patterns"
    }
  }

  var systemImage: String {
    switch self {
    case .overview: "gauge.with.dots.needle.bottom.50percent"
    case .battery: "battery.75percent"
    case .storage: "internaldrive"
    case .performance: "cpu"
    case .startup: "power"
    case .thermal: "thermometer.medium"
    case .issues: "app.badge"
    }
  }
}

struct ContentView: View {
  @ObservedObject var store: HealthDashboardStore
  @SceneStorage("selectedSection") private var selectedSectionID = DashboardSection.overview.rawValue

  private var selectedSection: DashboardSection {
    DashboardSection(rawValue: selectedSectionID) ?? .overview
  }

  var body: some View {
    NavigationSplitView {
      List(selection: $selectedSectionID) {
        Section {
          ForEach(DashboardSection.allCases) { section in
            HStack(spacing: 10) {
              Image(systemName: section.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

              VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                Text(section.detail)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
            }
            .tag(section.rawValue)
          }
        } header: {
          VStack(alignment: .leading, spacing: 5) {
            Text("Corewise")
              .font(.headline)
              .foregroundStyle(.primary)
            Text("Know what your Mac is really doing.")
              .font(.caption)
              .foregroundStyle(.secondary)
              .textCase(nil)
          }
        }
      }
      .listStyle(.sidebar)
      .navigationSplitViewColumnWidth(min: 230, ideal: 260)
    } detail: {
      Group {
        if let snapshot = store.snapshot {
          DetailRouter(section: selectedSection, snapshot: snapshot)
        } else {
          ProgressView("Checking your Mac...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            Task {
              await store.refresh()
            }
          } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
          .disabled(store.isRefreshing)
          .help("Refresh health snapshot")
        }
      }
    }
  }
}

private struct DetailRouter: View {
  var section: DashboardSection
  var snapshot: HealthSnapshot

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        switch section {
        case .overview:
          OverviewView(snapshot: snapshot)
        case .battery:
          BatteryView(battery: snapshot.battery)
        case .storage:
          StorageView(storage: snapshot.storage)
        case .performance:
          PerformanceView(performance: snapshot.performance)
        case .startup:
          StartupView(startup: snapshot.startup)
        case .thermal:
          ThermalView(thermal: snapshot.thermal)
        case .issues:
          IssuesView(appIssues: snapshot.appIssues)
        }
      }
      .padding(26)
      .frame(maxWidth: 1160, alignment: .leading)
    }
    .navigationTitle(section.title)
  }
}
