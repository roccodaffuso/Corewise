import SwiftUI

struct AppGroupEvidenceView: View {
  var activityGroups: [FocusedCheckActivitySummary]
  var liveGroups: [AppProcessGroup]
  var mode: PerformanceMode
  var selectedGroupID: String?
  var select: (String?) -> Void

  var body: some View {
    OperationalSection(
      title: "Most active apps during this check",
      subtitle: "Up to three aggregated app groups. Helpers remain available as raw process rows below.",
      instrument: true
    ) {
      if activityGroups.isEmpty {
        Text("No app group accumulated enough readable activity in this check.")
          .foregroundStyle(.secondary)
      } else {
        VStack(spacing: 0) {
          ForEach(Array(activityGroups.prefix(3).enumerated()), id: \.element.id) { index, activity in
            AppGroupEvidenceRow(
              activity: activity,
              liveGroup: liveGroups.first { $0.id == activity.id },
              mode: mode,
              isSelected: selectedGroupID == activity.id
            ) {
              select(selectedGroupID == activity.id ? nil : activity.id)
            }
            if index < min(activityGroups.count, 3) - 1 {
              Divider()
            }
          }
        }
      }
    }
  }
}

private struct AppGroupEvidenceRow: View {
  var activity: FocusedCheckActivitySummary
  var liveGroup: AppProcessGroup?
  var mode: PerformanceMode
  var isSelected: Bool
  var select: () -> Void

  var body: some View {
    Button(action: select) {
      HStack(spacing: CorewiseLayout.space12) {
        Image(systemName: symbol)
          .foregroundStyle(isSelected ? CorewiseVisual.accent : .secondary)
          .frame(width: 22)
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          HStack {
            Text(activity.title)
              .fontWeight(.medium)
            Text("\(activity.memberPIDs.count) observed processes")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Text("\(kindLabel) · \(activity.sampleCount) samples · \(observationDuration)")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: CorewiseLayout.space4) {
          Text(mode == .cpu ? corewisePercent(activity.maximumCPUPercent) : corewiseBytes(activity.peakMemoryBytes))
            .font(.headline.monospacedDigit())
          Text(mode == .cpu ? "peak CPU" : "peak observed memory")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        Image(systemName: isSelected ? "line.3.horizontal.decrease.circle.fill" : "chevron.right")
          .foregroundStyle(isSelected ? CorewiseVisual.accent : Color.secondary.opacity(0.55))
          .accessibilityHidden(true)
      }
      .padding(.vertical, CorewiseLayout.space8)
      .padding(.horizontal, CorewiseLayout.space8)
      .background(isSelected ? CorewiseVisual.accent.opacity(0.09) : .clear, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(activity.title), \(activity.memberPIDs.count) observed processes, peak \(corewisePercent(activity.maximumCPUPercent)) CPU, peak \(corewiseBytes(activity.peakMemoryBytes)) observed memory, \(activity.sampleCount) samples")
    .accessibilityHint(isSelected ? "Clears the app group filter" : "Filters the raw process table to this app group")
  }

  private var symbol: String {
    switch liveGroup?.kind ?? .unknown {
    case .app: "app.dashed"
    case .systemService: "gearshape.2"
    case .standaloneProcess: "terminal"
    case .unknown: "questionmark.app"
    }
  }

  private var kindLabel: String {
    switch liveGroup?.kind ?? .unknown {
    case .app: "App group"
    case .systemService: "System service"
    case .standaloneProcess: "Standalone process"
    case .unknown: "Unresolved owner"
    }
  }

  private var observationDuration: String {
    Duration.seconds(max(activity.lastObservedAt.timeIntervalSince(activity.firstObservedAt), 0))
      .formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated))
  }
}
