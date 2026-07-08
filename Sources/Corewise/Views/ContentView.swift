import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
  case overview
  case battery
  case storage
  case performance
  case startup
  case thermal
  case issues
  case report

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
    case .report: "Report"
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
    case .report: "Read-only summary"
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
    case .report: "doc.text.magnifyingglass"
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
            SidebarSectionRow(section: section, isSelected: section.rawValue == selectedSectionID)
            .tag(section.rawValue)
          }
        } header: {
          SidebarHeader()
        }
      }
      .listStyle(.sidebar)
      .tint(CorewiseVisual.accent)
      .navigationSplitViewColumnWidth(min: 240, ideal: 268)
    } detail: {
      ZStack {
        MacWindowMaterialView()
          .ignoresSafeArea()
        Rectangle()
          .fill(CorewiseVisual.appBackground)
          .ignoresSafeArea()
          .allowsHitTesting(false)
        WindowTransparencyConfigurator()
          .frame(width: 0, height: 0)

        Group {
          if let snapshot = store.snapshot {
            DetailRouter(section: selectedSection, snapshot: snapshot, store: store)
          } else {
            ProgressView("Checking your Mac...")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
      }
    }
  }
}

private struct SidebarHeader: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Image(systemName: "waveform.path.ecg")
          .font(.caption.weight(.bold))
          .foregroundStyle(CorewiseVisual.accent)
        Text("Corewise")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)
      }

      Text("Know what your Mac is really doing.")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .textCase(nil)
        .lineLimit(2)
    }
    .padding(.top, 8)
    .padding(.bottom, 4)
  }
}

private struct SidebarSectionRow: View {
  var section: DashboardSection
  var isSelected: Bool

  var body: some View {
    HStack(spacing: 11) {
      Image(systemName: section.systemImage)
        .font(.system(size: 13, weight: .semibold))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(isSelected ? CorewiseVisual.accent : .secondary)
        .frame(width: 23, height: 23)
        .background(
          RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(isSelected ? CorewiseVisual.accent.opacity(0.13) : Color.clear)
        )

      VStack(alignment: .leading, spacing: 1) {
        Text(section.title)
          .font(.callout.weight(isSelected ? .semibold : .medium))
        Text(section.detail)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .padding(.vertical, 3)
  }
}

private struct DetailRouter: View {
  var section: DashboardSection
  var snapshot: HealthSnapshot
  @ObservedObject var store: HealthDashboardStore

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        switch section {
        case .overview:
          OverviewView(snapshot: snapshot)
        case .battery:
          BatteryView(battery: snapshot.battery)
        case .storage:
          StorageView(
            storage: snapshot.storage,
            scanSession: store.storageScanSession,
            isScanning: store.isScanningStorage,
            scanFolder: { Task { await store.scanStorageFolder() } },
            scanDownloads: { Task { await store.scanDownloadsFolder() } },
            scanDeveloperData: { Task { await store.scanDeveloperFolder() } },
            scanFolderAt: { url in Task { await store.scanStorageSessionFolder(url) } },
            scanParent: { Task { await store.scanStorageParentFolder() } }
          )
        case .performance:
          PerformanceView(performance: snapshot.performance)
        case .startup:
          StartupView(startup: snapshot.startup)
        case .thermal:
          ThermalView(thermal: snapshot.thermal)
        case .issues:
          IssuesView(
            appIssues: snapshot.appIssues,
            isScanningReports: store.isScanningReports,
            scanReports: { Task { await store.scanCrashReportsFolder() } }
          )
        case .report:
          ReportView(snapshot: snapshot)
        }
      }
      .padding(28)
      .frame(maxWidth: 1160, alignment: .leading)
    }
    .navigationTitle(section.title)
  }
}
