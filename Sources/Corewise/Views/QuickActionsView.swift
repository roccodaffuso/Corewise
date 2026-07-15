// SPDX-License-Identifier: MPL-2.0

import AppKit
import SwiftUI

struct ShowCorewiseQuickActionsAction {
  var action: () -> Void

  func callAsFunction() {
    action()
  }
}

private struct ShowCorewiseQuickActionsKey: FocusedValueKey {
  typealias Value = ShowCorewiseQuickActionsAction
}

extension FocusedValues {
  var showCorewiseQuickActions: ShowCorewiseQuickActionsAction? {
    get { self[ShowCorewiseQuickActionsKey.self] }
    set { self[ShowCorewiseQuickActionsKey.self] = newValue }
  }
}

struct CorewiseCommands: Commands {
  @FocusedValue(\.showCorewiseQuickActions) private var showQuickActions

  var body: some Commands {
    CommandMenu("Corewise") {
      Button("Quick Actions") {
        showQuickActions?()
      }
      .keyboardShortcut("k", modifiers: .command)
      .disabled(showQuickActions == nil)
    }
  }
}

struct QuickActionsView: View {
  @ObservedObject var store: HealthDashboardStore
  @Binding var isPresented: Bool
  @Environment(AppRouteStore.self) private var routeStore
  @Environment(\.openSettings) private var openSettings
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @State private var query = ""
  @State private var selectedIndex = 0
  @FocusState private var isSearchFocused: Bool

  private var actions: [QuickActionDescriptor] {
    QuickActionDescriptor.available(session: store.focusedCheckSession, result: store.lastFocusedCheckResult).filter { $0.matches(query) }
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.28)
        .ignoresSafeArea()
        .accessibilityHidden(true)

      VStack(spacing: 0) {
        HStack(spacing: CorewiseLayout.space12) {
          CorewiseBrandGlyph(size: 38)
          VStack(alignment: .leading, spacing: 2) {
            Text("QUICK ACTIONS")
              .font(.caption.weight(.semibold))
              .tracking(0.8)
              .foregroundStyle(.secondary)
            TextField(String(localized: "quickActions.search", defaultValue: "Search actions", bundle: .main), text: $query)
              .textFieldStyle(.plain)
              .font(.title3)
              .focused($isSearchFocused)
              .accessibilityLabel("Search Corewise Quick Actions")
          }
          Image(systemName: "command")
            .font(.title3)
            .foregroundStyle(CorewiseVisual.accent)
            .accessibilityHidden(true)
        }
          .padding(CorewiseLayout.space16)

        Divider()

        if actions.isEmpty {
          ContentUnavailableView.search(text: query)
            .frame(minHeight: 220)
        } else {
          ScrollView {
            LazyVStack(spacing: CorewiseLayout.space4) {
              ForEach(Array(actions.enumerated()), id: \.element.id) { index, descriptor in
                QuickActionRow(descriptor: descriptor, isSelected: index == selectedIndex) {
                  perform(descriptor.id)
                }
              }
            }
            .padding(CorewiseLayout.space8)
          }
          .frame(maxHeight: 360)
        }

        Divider()
        HStack {
          Text("↑↓ Navigate")
          Text("↩ Run")
          Spacer()
          Text("esc Close")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(CorewiseLayout.space12)
      }
      .frame(width: 560)
      .background(reduceTransparency ? AnyShapeStyle(CorewiseVisual.windowBackground) : AnyShapeStyle(.regularMaterial), in: .rect(cornerRadius: 14))
      .overlay {
        RoundedRectangle(cornerRadius: CorewiseVisual.contentRadius)
          .stroke(CorewiseVisual.surfaceHighlight, lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.28), radius: 8, y: 5)
    }
    .onAppear { isSearchFocused = true }
    .onChange(of: query) { _, _ in selectedIndex = 0 }
    .onExitCommand { isPresented = false }
    .onMoveCommand { direction in
      guard !actions.isEmpty else { return }
      switch direction {
      case .down: selectedIndex = min(selectedIndex + 1, actions.count - 1)
      case .up: selectedIndex = max(selectedIndex - 1, 0)
      default: break
      }
    }
    .onSubmit {
      guard actions.indices.contains(selectedIndex) else { return }
      perform(actions[selectedIndex].id)
    }
  }

  private func perform(_ id: QuickActionID) {
    switch id {
    case let .navigate(section):
      routeStore.show(section)
    case .openAIWorkloads:
      routeStore.show(.performance, performanceMode: .aiWorkloads)
    case .refresh:
      Task { await store.refresh() }
    case .openSettings:
      openSettings()
    case .enableFullStorageAnalysis:
      routeStore.show(.storage)
      store.requestFullStorageAnalysisAccess()
    case let .startFocusedCheck(intent):
      routeStore.show(intent.launchRoute)
      store.startFocusedCheck(intent)
    case .finishFocusedCheck:
      routeStore.show(.overview)
      store.finishFocusedCheck()
    case .cancelFocusedCheck:
      store.cancelFocusedCheck()
    case .copyFocusedCheck:
      copy(store.lastFocusedCheckResult.map { DiagnosticReportBuilder().focusedCheckSummary(for: $0) })
    case .copySummary:
      copy(DiagnosticReportBuilder().summary(for: store.snapshot))
    case .copyMarkdown:
      copy(DiagnosticReportBuilder().markdown(for: store.snapshot))
    }
    isPresented = false
  }

  private func copy(_ text: String?) {
    guard let text else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
}

private struct QuickActionRow: View {
  var descriptor: QuickActionDescriptor
  var isSelected: Bool
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: CorewiseLayout.space12) {
        Image(systemName: descriptor.systemImage)
          .frame(width: 24)
          .foregroundStyle(isSelected ? CorewiseVisual.accent : .secondary)
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text(descriptor.title)
          Text(descriptor.subtitle)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if isSelected {
          Image(systemName: "return")
            .foregroundStyle(.secondary)
        }
      }
      .padding(CorewiseLayout.space8)
      .background(isSelected ? CorewiseVisual.accent.opacity(0.12) : .clear, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private extension DiagnosticReportBuilder {
  func summary(for snapshot: HealthSnapshot?) -> String? {
    snapshot.map { summary(for: $0) }
  }

  func markdown(for snapshot: HealthSnapshot?) -> String? {
    snapshot.map { markdown(for: $0) }
  }
}
