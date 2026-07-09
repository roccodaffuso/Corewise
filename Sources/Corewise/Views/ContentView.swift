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
      SidebarView(selectedSectionID: $selectedSectionID)
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

private struct SidebarView: View {
  @Binding var selectedSectionID: DashboardSection.RawValue

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      SidebarHeader()
        .padding(.horizontal, 14)

      VStack(spacing: 4) {
        ForEach(DashboardSection.allCases) { section in
          SidebarSectionRow(
            section: section,
            isSelected: section.rawValue == selectedSectionID
          ) {
            selectedSectionID = section.rawValue
          }
        }
      }
      .padding(.horizontal, 10)

      Spacer(minLength: 0)

      SidebarSettingsLink()
        .padding(.horizontal, 10)
    }
    .padding(.top, 14)
    .padding(.bottom, 12)
  }
}

private struct SidebarSettingsLink: View {
  @State private var isHovering = false
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    SettingsLink {
      HStack(spacing: 11) {
        Capsule()
          .fill(Color.clear)
          .frame(width: 3, height: 24)

        Image(systemName: "gearshape")
          .font(.system(size: 13, weight: .semibold))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(.secondary)
          .frame(width: 23, height: 23)

        VStack(alignment: .leading, spacing: 1) {
          Text("Settings")
            .font(.callout.weight(.medium))
            .foregroundStyle(.primary)
          Text("Preferences")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
      .background(rowFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
    .help("Open Corewise Settings")
  }

  private var rowFill: Color {
    isHovering ? CorewiseVisual.tileFill(colorScheme: colorScheme).opacity(0.72) : .clear
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
  var select: () -> Void
  @State private var isHovering = false
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Button(action: select) {
      HStack(spacing: 11) {
        Capsule()
          .fill(isSelected ? CorewiseVisual.accentSoft : Color.clear)
          .frame(width: 3, height: 24)

        Image(systemName: section.systemImage)
          .font(.system(size: 13, weight: .semibold))
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(isSelected ? CorewiseVisual.accentSoft : .secondary)
          .frame(width: 23, height: 23)

        VStack(alignment: .leading, spacing: 1) {
          Text(section.title)
            .font(.callout.weight(isSelected ? .semibold : .medium))
            .foregroundStyle(.primary)
          Text(section.detail)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
      .background(rowFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .stroke(rowStroke, lineWidth: 0.7)
      }
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
    .accessibilityLabel(section.title)
    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
  }

  private var rowFill: Color {
    if isSelected {
      return CorewiseVisual.tileFill(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.72 : 0.88)
    }
    if isHovering {
      return CorewiseVisual.tileFill(colorScheme: colorScheme).opacity(0.72)
    }
    return .clear
  }

  private var rowStroke: Color {
    isSelected ? CorewiseVisual.hairline(colorScheme: colorScheme) : .clear
  }
}

private struct DetailRouter: View {
  var section: DashboardSection
  var snapshot: HealthSnapshot
  @ObservedObject var store: HealthDashboardStore

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.pageSpacing) {
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
      .padding(CorewiseLayout.contentPadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .navigationTitle(section.title)
  }
}
