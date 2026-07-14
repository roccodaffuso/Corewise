import AppKit
import SwiftUI

struct ContentView: View {
  @ObservedObject var store: HealthDashboardStore
  @Environment(AppRouteStore.self) private var routeStore
  @SceneStorage("navigation.selectedSection") private var selectedSectionID = DashboardSection.overview.rawValue
  @State private var isShowingQuickActions = false
  @State private var requestedPerformanceMode: PerformanceMode?
  @State private var requestedFocus: DashboardFocus?

  private var selectedSection: DashboardSection {
    DashboardSection(rawValue: selectedSectionID) ?? .overview
  }

  var body: some View {
    NavigationSplitView {
      CorewiseSidebar(selectedSectionID: $selectedSectionID)
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 240)
    } detail: {
      ZStack(alignment: .top) {
        CorewiseBackdrop()
        WindowTransparencyConfigurator()
          .frame(width: 0, height: 0)

        if let snapshot = store.snapshot {
          DetailRouter(section: selectedSection, snapshot: snapshot, store: store, requestedPerformanceMode: requestedPerformanceMode, requestedFocus: requestedFocus)
        } else {
          LoadingDashboardView()
        }

        if let errorMessage = store.errorMessage {
          NoticeBanner(message: errorMessage, dismiss: store.clearError)
            .padding(CorewiseLayout.space16)
            .frame(maxWidth: 680)
        }
      }
      .navigationTitle(selectedSection.title)
    }
    .tint(CorewiseVisual.accent)
    .overlay {
      if isShowingQuickActions {
        QuickActionsView(store: store, isPresented: $isShowingQuickActions)
          .transition(.opacity)
      }
    }
    .focusedSceneValue(
      \.showCorewiseQuickActions,
      ShowCorewiseQuickActionsAction { isShowingQuickActions = true }
    )
    .onChange(of: routeStore.requestedRoute) { _, route in
      guard let route else { return }
      selectedSectionID = route.section.rawValue
      requestedPerformanceMode = route.performanceMode
      requestedFocus = route.focus
      routeStore.consume()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      Task { await store.applicationDidBecomeActive() }
    }
  }
}

private struct CorewiseSidebar: View {
  @Binding var selectedSectionID: String
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(spacing: 0) {
      CorewiseSidebarBrand()
        .padding(.horizontal, CorewiseLayout.space12)
        .padding(.top, 44)
        .padding(.bottom, CorewiseLayout.space12)

      List(selection: $selectedSectionID) {
        Section("Primary") {
          sectionRows(DashboardSection.primary)
        }
        Section("System") {
          sectionRows(DashboardSection.system)
        }
        Section("Utility") {
          sectionRows(DashboardSection.utility)
        }
      }
      .listStyle(.sidebar)
      .scrollContentBackground(.hidden)

      Spacer(minLength: 0)

      SettingsLink {
        SidebarDestinationRow(title: "Settings", systemImage: "gearshape", isSelected: false)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .buttonStyle(.plain)
      .padding(CorewiseLayout.space8)
    }
    .background {
      ZStack {
        Rectangle().fill(CorewiseVisual.windowBackground)
        CorewiseVisual.sidebarFill(colorScheme: colorScheme)
      }
    }
  }

  @ViewBuilder
  private func sectionRows(_ sections: [DashboardSection]) -> some View {
    ForEach(sections) { section in
      SidebarDestinationRow(
        title: section.title,
        systemImage: section.systemImage,
        isSelected: selectedSectionID == section.rawValue
      )
        .tag(section.rawValue)
        .accessibilityLabel(section.title)
        .listRowBackground(Color.clear)
    }
  }
}

private struct CorewiseSidebarBrand: View {
  var body: some View {
    HStack(spacing: CorewiseLayout.space12) {
      CorewiseBrandGlyph(size: 38)
      VStack(alignment: .leading, spacing: 2) {
        Text("COREWISE")
          .font(.headline)
          .tracking(0.7)
        Text("Signal console")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct SidebarDestinationRow: View {
  var title: String
  var systemImage: String
  var isSelected: Bool

  var body: some View {
    HStack(spacing: CorewiseLayout.space8) {
      ZStack {
        RoundedRectangle(cornerRadius: 6)
          .fill(isSelected ? CorewiseVisual.accent.opacity(0.16) : CorewiseVisual.quietSurface.opacity(0.55))
        Image(systemName: systemImage)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(isSelected ? CorewiseVisual.accent : .secondary)
      }
      .frame(width: 26, height: 26)
      Text(title)
        .fontWeight(isSelected ? .semibold : .regular)
      Spacer(minLength: 0)
      if isSelected {
        Circle()
          .fill(CorewiseVisual.accent)
          .frame(width: 5, height: 5)
          .accessibilityHidden(true)
      }
    }
    .padding(.horizontal, CorewiseLayout.space8)
    .padding(.vertical, CorewiseLayout.space4)
    .contentShape(.rect)
  }
}

private struct DetailRouter: View {
  var section: DashboardSection
  var snapshot: HealthSnapshot
  @ObservedObject var store: HealthDashboardStore
  var requestedPerformanceMode: PerformanceMode?
  var requestedFocus: DashboardFocus?

  var body: some View {
    switch section {
    case .overview:
      OverviewView(snapshot: snapshot, store: store)
    case .performance:
      PerformanceView(
        performance: snapshot.performance,
        store: store,
        focusedCheckSession: store.focusedCheckSession,
        requestedMode: requestedPerformanceMode,
        requestedFocus: requestedFocus
      )
    case .storage:
      StorageView(storage: snapshot.storage, store: store, requestedFocus: requestedFocus)
    case .battery:
      BatteryView(battery: snapshot.battery)
    case .startup:
      StartupView(startup: snapshot.startup)
    case .thermal:
      ThermalView(thermal: snapshot.thermal)
    case .issues:
      IssuesView(appIssues: snapshot.appIssues, store: store)
    case .report:
      ReportView(snapshot: snapshot, focusedCheckResult: store.lastFocusedCheckResult)
    }
  }
}

private struct LoadingDashboardView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        PageHeader(title: "Checking this Mac", subtitle: "Collecting supported local signals.", systemImage: "waveform.path.ecg")
        ForEach(0..<4, id: \.self) { _ in
          RoundedRectangle(cornerRadius: CorewiseVisual.contentRadius)
            .fill(CorewiseVisual.elevatedSurface)
            .frame(height: 92)
            .corewisePanel(instrument: true)
        }
      }
      .redacted(reason: .placeholder)
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .accessibilityLabel("Checking this Mac")
  }
}

#Preview("App — initial loading") {
  LoadingDashboardView()
    .frame(width: 1180, height: 800)
}

#Preview("App — inline error") {
  ZStack(alignment: .top) {
    CorewiseBackdrop()
    LoadingDashboardView()
    NoticeBanner(message: "The latest local refresh could not complete. The previous snapshot remains visible.", dismiss: {})
      .padding()
      .frame(maxWidth: 680)
  }
  .frame(width: 1180, height: 800)
}
