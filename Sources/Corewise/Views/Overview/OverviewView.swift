import AppKit
import SwiftUI

struct OverviewView: View {
  var snapshot: HealthSnapshot
  @ObservedObject var store: HealthDashboardStore
  @Environment(AppRouteStore.self) private var routeStore

  private var signals: [AttentionSignal] {
    OverviewSignalBuilder.signals(from: snapshot.overviewMetrics)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space24) {
        PageHeader(
          title: "This Mac, right now",
          subtitle: "A calm summary of supported local signals. Details stay one layer deeper.",
          systemImage: "waveform.path.ecg"
        )

        focusedCheckSurface

        StatusRail(summary: snapshot.attentionSummary, coverage: snapshot.coverageSummary)

        OperationalSection(title: "Signal focus", subtitle: "The three live groups that matter most right now.") {
          ForEach(signals) { signal in
            SignalRow(signal: signal, action: { navigate(to: signal.area) }) {
              SignalMicrovisual(signal: signal, snapshot: snapshot)
            }
            if signal.id != signals.last?.id {
              Divider()
            }
          }
        }

        ResourceConsumersSection(performance: snapshot.performance) {
          routeStore.show(.performance)
        }

        SourceDisclosure(
          detail: "Corewise reads supported diagnostics locally. Coverage describes available data, not the health of this Mac.",
          sources: snapshot.dataAccess
        )
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .scrollContentBackground(.visible)
  }

  @ViewBuilder
  private var focusedCheckSurface: some View {
    if let session = store.focusedCheckSession, session.phase != .completed {
      FocusedCheckProgressView(
        session: session,
        cancel: { store.cancelFocusedCheck() },
        finish: { store.finishFocusedCheck() }
      )
    } else if let result = store.lastFocusedCheckResult {
      FocusedCheckResultView(
        result: result,
        open: routeStore.show,
        copy: { copyFocusedCheck(result) },
        startAnother: { store.dismissFocusedCheckResult() }
      )
    } else {
      FocusedCheckLauncher { intent in
        store.startFocusedCheck(intent)
        routeStore.show(intent.launchRoute)
      }
    }
  }

  private func copyFocusedCheck(_ result: FocusedCheckResult) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(DiagnosticReportBuilder().focusedCheckSummary(for: result), forType: .string)
  }

  private func navigate(to area: DiagnosticArea) {
    switch area {
    case .performance: routeStore.show(.performance)
    case .storage: routeStore.show(.storage)
    case .battery: routeStore.show(.battery)
    case .thermal: routeStore.show(.thermal)
    case .startup: routeStore.show(.startup)
    case .appIssues: routeStore.show(.issues)
    }
  }
}

private struct SignalMicrovisual: View {
  var signal: AttentionSignal
  var snapshot: HealthSnapshot

  var body: some View {
    switch signal.area {
    case .performance:
      PerformanceSparkline(history: snapshot.performance.history)
      .frame(height: 28)
      .accessibilityLabel(performanceChartLabel)
    case .storage:
      ProgressView(value: snapshot.storage.usedGB, total: max(snapshot.storage.totalGB, 1))
        .progressViewStyle(.linear)
        .tint(CorewiseVisual.color(for: signal.status))
        .accessibilityLabel("Storage used")
        .accessibilityValue("\(corewiseNumber(snapshot.storage.usedGB)) of \(corewiseNumber(snapshot.storage.totalGB)) gigabytes")
    default:
      HStack {
        Spacer()
        Image(systemName: signal.status == .good ? "checkmark.circle" : "exclamationmark.triangle")
          .foregroundStyle(CorewiseVisual.color(for: signal.status))
        Text(signal.status.rawValue)
          .font(.callout)
      }
    }
  }

  private var performanceChartLabel: String {
    let values = snapshot.performance.history.compactMap(\.cpuPercent)
    guard let first = values.first, let last = values.last, let maximum = values.max() else {
      return "CPU history is collecting"
    }
    return "Recent CPU history, from \(corewiseNumber(first)) to \(corewiseNumber(last)) percent, maximum \(corewiseNumber(maximum)) percent"
  }
}

private struct PerformanceSparkline: View {
  var history: [PerformanceTimePoint]

  var body: some View {
    let values = history.compactMap(\.cpuPercent)

    GeometryReader { geometry in
      Path { path in
        guard let minimum = values.min(), let maximum = values.max(), !values.isEmpty else {
          return
        }

        let width = geometry.size.width
        let height = geometry.size.height
        let valueRange = max(maximum - minimum, 1)
        let step = values.count > 1 ? width / Double(values.count - 1) : 0

        for (index, value) in values.enumerated() {
          let x = Double(index) * step
          let y = height - ((value - minimum) / valueRange * height)
          let point = CGPoint(x: x, y: y)
          if index == 0 {
            path.move(to: point)
          } else {
            path.addLine(to: point)
          }
        }
      }
      .stroke(CorewiseVisual.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
    .accessibilityHidden(true)
  }
}

private struct ResourceConsumersSection: View {
  var performance: PerformanceHealth
  var showAll: () -> Void

  var body: some View {
    OperationalSection(title: "Resource field", subtitle: "The processes shaping CPU and memory pressure.", instrument: true) {
      ViewThatFits(in: .horizontal) {
        HStack(alignment: .top, spacing: CorewiseLayout.space24) {
          ProcessMiniList(title: "Top CPU", processes: Array(performance.processes.prefix(3)), mode: .cpu)
          Divider()
          ProcessMiniList(
            title: "Top Memory",
            processes: Array(performance.processes.sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }.prefix(3)),
            mode: .memory
          )
        }

        VStack(spacing: CorewiseLayout.space16) {
          ProcessMiniList(title: "Top CPU", processes: Array(performance.processes.prefix(3)), mode: .cpu)
          Divider()
          ProcessMiniList(
            title: "Top Memory",
            processes: Array(performance.processes.sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }.prefix(3)),
            mode: .memory
          )
        }
      }

      Button("Open Performance", systemImage: "arrow.right", action: showAll)
        .buttonStyle(.link)
    }
  }
}

private struct ProcessMiniList: View {
  var title: String
  var processes: [ProcessObservation]
  var mode: PerformanceMode

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
      HStack {
        Text(title.uppercased())
          .font(.caption.weight(.semibold))
          .tracking(0.7)
          .foregroundStyle(.secondary)
        Spacer()
        Image(systemName: mode == .cpu ? "cpu" : "memorychip")
          .foregroundStyle(mode == .cpu ? CorewiseVisual.accent : CorewiseVisual.good)
          .accessibilityHidden(true)
      }
      if processes.isEmpty {
        Text("No readable process rows")
          .foregroundStyle(.secondary)
      } else {
        ForEach(Array(processes.enumerated()), id: \.element.id) { index, process in
          ProcessMiniRow(
            rank: index + 1,
            process: process,
            mode: mode,
            maximum: maximum
          )
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var maximum: Double {
    switch mode {
    case .cpu:
      return max(processes.compactMap(\.cpuPercent).max() ?? 1, 1)
    case .memory:
      return max(Double(processes.map(\.observedMemoryBytes).max() ?? 1), 1)
    }
  }
}

private struct ProcessMiniRow: View {
  var rank: Int
  var process: ProcessObservation
  var mode: PerformanceMode
  var maximum: Double

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
      HStack(spacing: CorewiseLayout.space8) {
        Text(String(format: "%02d", rank))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.tertiary)
          .frame(width: 20, alignment: .leading)
        Text(process.displayName)
          .lineLimit(1)
        Spacer(minLength: CorewiseLayout.space12)
        Text(displayValue)
          .font(.callout.monospacedDigit())
          .fontWeight(.medium)
      }
      ProgressView(value: measuredValue, total: maximum)
        .tint(mode == .cpu ? CorewiseVisual.accent : CorewiseVisual.good)
        .controlSize(.mini)
    }
    .accessibilityElement(children: .combine)
  }

  private var displayValue: String {
    mode == .cpu ? corewisePercent(process.cpuPercent) : corewiseBytes(process.observedMemoryBytes)
  }

  private var measuredValue: Double {
    mode == .cpu ? process.cpuPercent : Double(process.observedMemoryBytes)
  }
}

#Preview("Overview — clear") {
  OverviewView(snapshot: PreviewFixtures.snapshot, store: PreviewFixtures.store)
    .environment(AppRouteStore())
    .frame(width: 1180, height: 800)
}


#Preview("Overview — dark") {
  OverviewView(snapshot: PreviewFixtures.snapshot, store: PreviewFixtures.store)
    .environment(AppRouteStore())
    .frame(width: 1180, height: 800)
    .preferredColorScheme(.dark)
}
