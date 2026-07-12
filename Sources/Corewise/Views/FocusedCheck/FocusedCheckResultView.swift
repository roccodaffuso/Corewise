import SwiftUI

struct FocusedCheckResultView: View {
  var result: FocusedCheckResult
  var open: (DashboardRoute) -> Void
  var copy: () -> Void
  var copyMarkdown: (() -> Void)? = nil
  var startAnother: () -> Void
  @State private var copied = false

  var body: some View {
    OperationalSection(
      title: result.intent.title,
      subtitle: "Focused Check completed \(result.generatedAt.formatted(date: .omitted, time: .shortened))",
      instrument: true
    ) {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        HStack(alignment: .top, spacing: CorewiseLayout.space12) {
          Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(color)
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
            Text(result.headline)
              .font(.title3.weight(.semibold))
            Text(result.detail)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .accessibilityElement(children: .combine)

        Label(observationSummary, systemImage: "clock")
          .font(.callout.monospacedDigit())
          .foregroundStyle(.secondary)
          .accessibilityLabel("\(observationSummary). Result generated \(result.generatedAt.formatted(date: .abbreviated, time: .standard))")

        if !result.evidence.isEmpty {
          VStack(spacing: 0) {
            ForEach(Array(result.evidence.enumerated()), id: \.element.id) { index, evidence in
              FocusedCheckEvidenceRow(evidence: evidence) {
                if let destination = evidence.destination {
                  open(destination)
                }
              }
              if index < result.evidence.count - 1 {
                Divider()
              }
            }
          }
        }

        HStack(alignment: .top, spacing: CorewiseLayout.space12) {
          Image(systemName: "arrow.right.circle.fill")
            .foregroundStyle(CorewiseVisual.accent)
          VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
            Text(result.primaryAction.title)
              .font(.headline)
            Text(result.primaryAction.detail)
              .foregroundStyle(.secondary)
          }
          Spacer()
          if let destination = result.primaryAction.destination {
            Button("Open", systemImage: "arrow.up.forward") {
              open(destination)
            }
            .buttonStyle(.borderedProminent)
          }
        }
        .padding(CorewiseLayout.space12)
        .background(CorewiseVisual.accent.opacity(0.08), in: .rect(cornerRadius: CorewiseVisual.controlRadius))

        DisclosureGroup("Coverage and limitations") {
          Text(result.coverage)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.top, CorewiseLayout.space8)
        }

        HStack {
          Button(copied ? "Copied" : "Copy check summary", systemImage: copied ? "checkmark" : "doc.on.clipboard") {
            copy()
            copied = true
            AccessibilityNotification.Announcement("Copied").post()
            Task {
              try? await Task.sleep(for: .seconds(1.5))
              copied = false
            }
          }
          .accessibilityHint("Copies the local Focused Check summary without uploading it")

          if let copyMarkdown {
            Button("Copy Markdown", systemImage: "text.page", action: copyMarkdown)
              .accessibilityHint("Copies a privacy-safe Markdown result without uploading it")
          }

          Spacer()

          Button("Start another check", systemImage: "arrow.counterclockwise", action: startAnother)
        }
      }
    }
  }

  private var observationSummary: String {
    let elapsed = max(result.observationEndedAt.timeIntervalSince(result.observationStartedAt), 0)
    let duration = Duration.seconds(elapsed).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated))
    return "Observed for \(duration) · updated \(result.generatedAt.formatted(date: .omitted, time: .shortened))"
  }

  private var color: Color {
    switch result.state {
    case .clear: CorewiseVisual.good
    case .review: CorewiseVisual.warning
    case .critical: CorewiseVisual.critical
    case .unavailable, .insufficientEvidence: CorewiseVisual.info
    }
  }

  private var symbol: String {
    switch result.state {
    case .clear: "checkmark.circle.fill"
    case .review: "exclamationmark.triangle.fill"
    case .critical: "exclamationmark.octagon.fill"
    case .unavailable, .insufficientEvidence: "questionmark.circle.fill"
    }
  }
}

#Preview("Focused Check — result") {
  FocusedCheckResultView(result: PreviewFixtures.focusedResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Slow — insufficient result") {
  FocusedCheckResultView(result: PreviewFixtures.focusedInsufficientResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Slow — no persistent signal") {
  FocusedCheckResultView(result: PreviewFixtures.focusedClearResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Hot — nominal") {
  FocusedCheckResultView(result: PreviewFixtures.focusedHotNominalResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Hot — elevated") {
  FocusedCheckResultView(result: PreviewFixtures.focusedHotElevatedResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Battery — external power") {
  FocusedCheckResultView(result: PreviewFixtures.focusedBatteryACResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Battery — completed") {
  FocusedCheckResultView(result: PreviewFixtures.focusedBatteryResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Focused Check — three evidence rows") {
  FocusedCheckResultView(result: PreviewFixtures.focusedThreeEvidenceResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
}

#Preview("Focused Check — dark") {
  FocusedCheckResultView(result: PreviewFixtures.focusedThreeEvidenceResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
    .preferredColorScheme(.dark)
}

#Preview("Focused Check — long localized copy") {
  FocusedCheckResultView(result: PreviewFixtures.focusedLongCopyResult, open: { _ in }, copy: {}, startAnother: {})
    .padding()
    .frame(width: 980)
    .environment(\.locale, Locale(identifier: "de"))
}

private struct FocusedCheckEvidenceRow: View {
  var evidence: FocusedCheckEvidence
  var open: () -> Void

  var body: some View {
    if evidence.destination != nil {
      Button(action: open) {
        rowContent
      }
      .buttonStyle(.plain)
      .accessibilityHint("Opens the related Corewise section")
    } else {
      rowContent
        .accessibilityElement(children: .combine)
    }
  }

  private var rowContent: some View {
    HStack(alignment: .top, spacing: CorewiseLayout.space12) {
        Image(systemName: evidence.severity == .critical ? "exclamationmark.octagon.fill" : "waveform.path.ecg")
          .foregroundStyle(CorewiseVisual.color(for: evidence.severity))
          .frame(width: 18)
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          HStack {
            Text(evidence.title)
              .fontWeight(.medium)
            Spacer()
            Text(evidence.value)
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
          Text(evidence.detail)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          Text("\(evidence.confidence.title) confidence · \(evidence.sampleCount) samples · \(evidence.source)")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        if evidence.destination != nil {
          Image(systemName: "chevron.right")
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
        }
    }
    .padding(.vertical, CorewiseLayout.space12)
    .contentShape(.rect)
  }
}
