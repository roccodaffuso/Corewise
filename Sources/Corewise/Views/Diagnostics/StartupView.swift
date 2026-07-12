import AppKit
import SwiftUI

private enum StartupFilter: String, CaseIterable, Identifiable {
  case all = "All"
  case agents = "Agents"
  case daemons = "Daemons"

  var id: String { rawValue }
}

struct StartupView: View {
  var startup: StartupHealth
  @State private var filter: StartupFilter = .all
  @State private var query = ""
  @State private var selectedPath: String?
  @State private var selectedItem: StartupItem?
  @State private var isInspectorPresented = false

  private var items: [StartupItem] {
    let base: [StartupItem]
    switch filter {
    case .all: base = startup.launchAgents + startup.launchDaemons
    case .agents: base = startup.launchAgents
    case .daemons: base = startup.launchDaemons
    }
    guard !query.isEmpty else { return base }
    return base.filter {
      $0.title.localizedStandardContains(query)
        || $0.kind.localizedStandardContains(query)
        || $0.path.localizedStandardContains(query)
    }
  }

  private var tableHeight: Double {
    min(max(Double(max(items.count, 1)) * 30 + 50, 190), 360)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space20) {
        PageHeader(title: "Startup", subtitle: "Readable launch metadata for manual review. Nothing is disabled automatically.", systemImage: "power")

        HStack {
          Picker("Startup filter", selection: $filter) {
            ForEach(StartupFilter.allCases) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 280)

          HStack(spacing: CorewiseLayout.space8) {
            Image(systemName: "magnifyingglass")
              .foregroundStyle(.secondary)
            TextField("Filter label, kind, or path", text: $query)
              .textFieldStyle(.plain)
          }
          .padding(.horizontal, CorewiseLayout.space8)
          .padding(.vertical, 6)
          .background(CorewiseVisual.contentSurface, in: .rect(cornerRadius: 8))

          Spacer()
          Text("\(items.count) rows")
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(CorewiseLayout.space12)
        .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
        .overlay {
          RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
            .stroke(CorewiseVisual.separator, lineWidth: 1)
        }

        if items.isEmpty {
          ContentUnavailableView.search(text: query)
            .frame(maxWidth: .infinity, minHeight: 260)
        } else {
          Table(items, selection: $selectedPath) {
            TableColumn("Label", value: \.title)
            TableColumn("Kind") { item in
              Text(item.kind)
            }
              .width(min: 90, ideal: 120)
            TableColumn("Impact") { item in
              Text(item.startupImpact)
            }
              .width(min: 80, ideal: 100)
            TableColumn("Trust") { item in
              Text(item.signedState)
            }
              .width(min: 90, ideal: 120)
            TableColumn("Recent") { item in
              StartupRecentCell(isRecent: item.recentlyAdded)
            }
            .width(64)
          }
          .accessibilityLabel("Startup items")
          .frame(height: tableHeight)
          .corewiseTableSurface()
        }
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .inspector(isPresented: $isInspectorPresented) {
      if let selectedItem {
        StartupInspector(item: selectedItem)
          .inspectorColumnWidth(min: 260, ideal: 320, max: 380)
      } else {
        ContentUnavailableView("Select a startup item", systemImage: "cursorarrow.click")
          .inspectorColumnWidth(min: 260, ideal: 320, max: 380)
      }
    }
    .onChange(of: selectedPath) { _, path in
      guard let path, let item = items.first(where: { $0.path == path }) else { return }
      selectedItem = item
      isInspectorPresented = true
    }
  }
}

private struct StartupRecentCell: View {
  var isRecent: Bool

  var body: some View {
    Image(systemName: isRecent ? "clock.badge.exclamationmark" : "minus")
      .foregroundStyle(isRecent ? CorewiseVisual.warning : Color.secondary)
      .accessibilityLabel(isRecent ? "Recently added" : "Not recently added")
  }
}

private struct StartupInspector: View {
  var item: StartupItem

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        PageHeader(title: item.title, subtitle: item.kind, systemImage: "power", compact: true)
        OperationalSection(title: "Metadata") {
          MetricRow(title: "Impact", value: item.startupImpact, severity: item.status)
          Divider()
          MetricRow(title: "Trust", value: item.signedState)
          Divider()
          MetricRow(title: "Recently added", value: item.recentlyAdded ? "Yes" : "No")
        }
        OperationalSection(title: "Path") {
          Text(item.path)
            .font(.body.monospaced())
            .textSelection(.enabled)
          Button("Reveal in Finder", systemImage: "folder") {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
          }
        }
        SourceDisclosure(title: "Interpretation", detail: "\(item.explanation) Source: \(item.source). \(item.confidence).")
      }
      .padding(CorewiseLayout.space16)
    }
  }
}

#Preview("Startup — empty") {
  StartupView(startup: PreviewFixtures.startup)
    .frame(width: 1180, height: 800)
}
