// SPDX-License-Identifier: MPL-2.0

import SwiftUI

struct PageHeader: View {
  var title: String
  var subtitle: String
  var systemImage: String
  var compact: Bool = false

  var body: some View {
    HStack(alignment: .center, spacing: CorewiseLayout.space16) {
      ZStack {
        RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
          .fill(CorewiseVisual.elevatedSurface)
        RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
          .stroke(CorewiseVisual.surfaceHighlight, lineWidth: 0.75)
        Image(systemName: systemImage)
          .font(.system(size: 19, weight: .semibold))
          .foregroundStyle(CorewiseVisual.accent)
      }
      .frame(width: compact ? 38 : 46, height: compact ? 38 : 46)
      .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
        Text(title)
          .font(compact ? .title2 : .largeTitle)
          .fontWeight(.semibold)
          .tracking(compact ? -0.2 : -0.6)
        Text(subtitle)
          .font(.body)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      if !compact {
        Spacer(minLength: CorewiseLayout.space16)

        HStack(spacing: CorewiseLayout.space8) {
          Circle()
            .fill(CorewiseVisual.accent)
            .frame(width: 6, height: 6)
          Text("LOCAL SIGNALS")
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
        }
        .accessibilityLabel("Local signals")
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct StatusRail: View {
  var summary: AttentionSummary
  var coverage: DataCoverageSummary

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: .center, spacing: CorewiseLayout.space24) {
        summaryContent
        Spacer(minLength: CorewiseLayout.space16)
        statusMetadata
          .frame(width: 190, alignment: .leading)
      }

      VStack(alignment: .leading, spacing: CorewiseLayout.space20) {
        summaryContent
        Divider()
        statusMetadata
      }
    }
    .padding(CorewiseLayout.space24)
    .background {
      ZStack {
        CorewiseGridTexture(spacing: 24, dotSize: 1)
          .opacity(0.24)
        LinearGradient(
          colors: [CorewiseVisual.color(for: summary.state).opacity(0.10), .clear],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
    .corewisePanel(instrument: true)
    .accessibilityElement(children: .combine)
  }

  private var summaryContent: some View {
    HStack(alignment: .center, spacing: CorewiseLayout.space20) {
      CorewiseBrandGlyph(size: 72, stateColor: CorewiseVisual.color(for: summary.state))

      VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
        Text(summary.headline)
          .font(.title)
          .fontWeight(.semibold)
          .tracking(-0.35)
        Text(summary.detail)
          .font(.body)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        Label(summary.recommendedAction, systemImage: "arrow.right.circle.fill")
          .font(.callout.weight(.medium))
          .foregroundStyle(CorewiseVisual.color(for: summary.state))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var statusMetadata: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
      StatusBadge(state: summary.state)
      VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
        if let lastUpdated = summary.lastUpdated {
          Label(lastUpdated.formatted(date: .omitted, time: .shortened), systemImage: "clock")
        }
        Label("\(coverage.live) of \(coverage.total) live", systemImage: "dot.radiowaves.left.and.right")
      }
      .font(.callout)
      .foregroundStyle(.secondary)
    }
  }
}

struct CorewiseSectionHeader: View {
  var title: String
  var subtitle: String?

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: CorewiseLayout.space12) {
      HStack(spacing: CorewiseLayout.space8) {
        Circle()
          .fill(CorewiseVisual.accent)
          .frame(width: 5, height: 5)
        Text(title)
          .font(.headline)
      }
      if let subtitle {
        Text(subtitle)
          .font(.callout)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      Spacer(minLength: 0)
    }
  }
}

struct StatusBadge: View {
  var state: AttentionState

  var body: some View {
    Label(title, systemImage: state.systemImage)
      .font(.callout)
      .bold()
      .foregroundStyle(CorewiseVisual.color(for: state))
      .padding(.horizontal, CorewiseLayout.space8)
      .padding(.vertical, CorewiseLayout.space4)
      .background(CorewiseVisual.color(for: state).opacity(0.12), in: .capsule)
  }

  private var title: String {
    switch state {
    case .clear: "Clear"
    case .review: "Review"
    case .critical: "Critical"
    case .unavailable: "Unavailable"
    }
  }
}

struct SeverityBadge: View {
  var severity: FindingSeverity

  var body: some View {
    Label(severity.rawValue, systemImage: systemImage)
      .font(.callout)
      .foregroundStyle(CorewiseVisual.color(for: severity))
      .labelStyle(.titleAndIcon)
      .accessibilityLabel("Status: \(severity.rawValue)")
  }

  private var systemImage: String {
    switch severity {
    case .good: "checkmark.circle"
    case .info: "info.circle"
    case .warning: "exclamationmark.triangle"
    case .critical: "exclamationmark.octagon"
    }
  }
}

struct OperationalSection<Content: View>: View {
  var title: String
  var subtitle: String?
  var instrument: Bool
  @ViewBuilder var content: Content

  init(title: String, subtitle: String? = nil, instrument: Bool = false, @ViewBuilder content: () -> Content) {
    self.title = title
    self.subtitle = subtitle
    self.instrument = instrument
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
      CorewiseSectionHeader(title: title, subtitle: subtitle)
      VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
        content
      }
      .padding(CorewiseLayout.space16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .corewisePanel(instrument: instrument)
    }
  }
}

struct MetricRow: View {
  var title: String
  var value: String
  var detail: String?
  var severity: FindingSeverity? = nil

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: CorewiseLayout.space12) {
      VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
        Text(title)
          .font(.body)
        if let detail {
          Text(detail)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: CorewiseLayout.space16)
      if let severity {
        Image(systemName: severitySystemImage(severity))
          .foregroundStyle(CorewiseVisual.color(for: severity))
          .accessibilityHidden(true)
      }
      Text(value)
        .font(.body.monospacedDigit())
        .bold()
        .multilineTextAlignment(.trailing)
    }
    .accessibilityElement(children: .combine)
  }
}

struct SignalRow<Visual: View>: View {
  var signal: AttentionSignal
  var action: () -> Void
  @ViewBuilder var visual: Visual
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isHovered = false

  init(signal: AttentionSignal, action: @escaping () -> Void, @ViewBuilder visual: () -> Visual) {
    self.signal = signal
    self.action = action
    self.visual = visual()
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: CorewiseLayout.space12) {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(CorewiseVisual.color(for: signal.status).opacity(0.11))
          Image(systemName: areaImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(CorewiseVisual.color(for: signal.status))
        }
        .frame(width: 36, height: 36)

        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          HStack {
            Text(signal.area.title)
              .font(.headline)
            SeverityBadge(severity: signal.status)
          }
          Text(signal.title)
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: CorewiseLayout.space12)
        visual
          .frame(width: 120)
        Text(corewiseDisplayValue(value: signal.value, unit: signal.unit))
          .font(.title3.monospacedDigit())
          .fontWeight(.semibold)
          .frame(minWidth: 88, alignment: .trailing)
        Image(systemName: "chevron.right")
          .font(.callout)
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, CorewiseLayout.space8)
      .padding(.vertical, CorewiseLayout.space12)
      .background(isHovered ? CorewiseVisual.elevatedSurface.opacity(0.72) : .clear, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
      .offset(x: isHovered && !reduceMotion ? 2 : 0)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(reduceMotion ? nil : CorewiseVisual.quickTransition) {
        isHovered = hovering
      }
    }
    .accessibilityLabel("\(signal.area.title), \(signal.title), \(corewiseDisplayValue(value: signal.value, unit: signal.unit)), \(signal.status.rawValue)")
  }

  private var areaImage: String {
    switch signal.area {
    case .performance: "cpu"
    case .storage: "internaldrive"
    case .battery: "battery.75percent"
    case .thermal: "thermometer.medium"
    case .startup: "power"
    case .appIssues: "app.badge"
    }
  }
}

struct SourceDisclosure: View {
  var title: String = "Data & privacy"
  var detail: String
  var sources: [DataAccessCapability] = []

  var body: some View {
    DisclosureGroup(title) {
      VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
        Text(detail)
          .foregroundStyle(.secondary)
        ForEach(sources) { source in
          VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
            HStack {
              Text(source.title)
                .bold()
              Spacer()
              Text(source.dataMode.rawValue)
                .foregroundStyle(.secondary)
            }
            Text("\(source.source) — \(source.reason)")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(.top, CorewiseLayout.space8)
    }
    .padding(CorewiseLayout.space16)
    .background(CorewiseVisual.quietSurface)
    .clipShape(.rect(cornerRadius: CorewiseVisual.contentRadius))
    .overlay {
      RoundedRectangle(cornerRadius: CorewiseVisual.contentRadius)
        .stroke(CorewiseVisual.separator, lineWidth: 1)
    }
  }
}

struct NoticeBanner: View {
  var message: String
  var dismiss: () -> Void

  var body: some View {
    HStack(spacing: CorewiseLayout.space12) {
      Label(message, systemImage: "exclamationmark.triangle")
        .foregroundStyle(CorewiseVisual.warning)
      Spacer(minLength: 0)
      Button("Dismiss", systemImage: "xmark", action: dismiss)
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
    }
    .padding(CorewiseLayout.space12)
    .background(CorewiseVisual.warning.opacity(0.12), in: .rect(cornerRadius: CorewiseVisual.controlRadius))
    .overlay {
      RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
        .stroke(CorewiseVisual.warning.opacity(0.28), lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
  }
}

func corewiseDisplayValue(_ metric: DiagnosticMetric) -> String {
  corewiseDisplayValue(value: metric.value, unit: metric.unit)
}

func corewiseDisplayValue(value: String, unit: String) -> String {
  unit.isEmpty ? value : "\(value) \(unit)"
}

func corewiseNumber(_ value: Double) -> String {
  value.formatted(.number.precision(.fractionLength(value.rounded() == value ? 0 : 1)))
}

func corewisePercent(_ value: Double?) -> String {
  guard let value else { return "N/A" }
  return "\(corewiseNumber(value))%"
}

func corewiseBytes(_ value: UInt64) -> String {
  ByteCountFormatter.string(fromByteCount: Int64(clamping: value), countStyle: .memory)
}

private func severitySystemImage(_ severity: FindingSeverity) -> String {
  switch severity {
  case .good: "checkmark.circle.fill"
  case .info: "info.circle.fill"
  case .warning: "exclamationmark.triangle.fill"
  case .critical: "exclamationmark.octagon.fill"
  }
}
