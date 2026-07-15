// SPDX-License-Identifier: MPL-2.0

import SwiftUI

struct FocusedCheckProgressView: View {
  var session: FocusedCheckSession
  var cancel: () -> Void
  var finish: () -> Void

  var body: some View {
    OperationalSection(
      title: session.intent.title,
      subtitle: phaseDetail,
      instrument: true
    ) {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        HStack(alignment: .firstTextBaseline, spacing: CorewiseLayout.space16) {
          Label(phaseTitle, systemImage: phaseSymbol)
            .font(.headline)
          Spacer()
          VStack(alignment: .trailing, spacing: CorewiseLayout.space4) {
            Text(sampleSummaryWithGaps)
              .font(.callout.monospacedDigit())
            Text("Updated \(session.lastUpdatedAt.formatted(date: .omitted, time: .standard))")
              .font(.caption.monospacedDigit())
          }
          .foregroundStyle(.secondary)
          .accessibilityElement(children: .combine)
        }

        if let suggestedDuration = session.suggestedDuration {
          ProgressView(value: elapsed, total: suggestedDuration)
            .tint(CorewiseVisual.accent)
            .accessibilityLabel("Focused Check observation time")
            .accessibilityValue("\(Int(min(elapsed, suggestedDuration))) of \(Int(suggestedDuration)) seconds")
        } else if session.phase == .scanningStorage {
          ProgressView()
            .controlSize(.small)
            .accessibilityLabel("Storage scan in progress")
        }

        if !session.provisionalEvidence.isEmpty {
          VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
            Text("OBSERVED SO FAR")
              .font(.caption.weight(.semibold))
              .tracking(0.7)
              .foregroundStyle(.secondary)
            ForEach(session.provisionalEvidence.prefix(3)) { evidence in
              HStack {
                Image(systemName: evidence.severity == .critical ? "exclamationmark.octagon.fill" : "waveform.path.ecg")
                  .foregroundStyle(CorewiseVisual.color(for: evidence.severity))
                Text(evidence.title)
                Spacer()
                Text(evidence.value)
                  .monospacedDigit()
                  .foregroundStyle(.secondary)
              }
              .accessibilityElement(children: .combine)
            }
          }
        }

        HStack {
          Button("Cancel", role: .cancel, action: cancel)
          Spacer()
          Button("Finish Check", systemImage: "checkmark", action: finish)
            .buttonStyle(.borderedProminent)
            .disabled(session.phase == .awaitingAccess || session.phase == .readyForStorageScan || session.phase == .scanningStorage || elapsed < session.minimumDuration)
        }
      }
    }
  }

  private var elapsed: TimeInterval {
    max(Date().timeIntervalSince(session.startedAt), 0)
  }

  private var sampleSummary: String {
    if session.intent == .batteryDrain {
      return "\(session.distinctBatterySampleCount) battery readings"
    }
    if session.intent == .storageFull {
      return session.phase == .awaitingAccess ? "Access required" : "Read-only scan"
    }
    if session.intent == .aiWorkloads {
      return "\(session.aiWorkloads.count) tools · \(session.systemSampleCount) samples"
    }
    return "\(session.systemSampleCount) live samples"
  }

  private var sampleSummaryWithGaps: String {
    guard session.missingSampleCount > 0 else {
      return sampleSummary
    }
    return "\(sampleSummary) · \(session.missingSampleCount) missing"
  }

  private var phaseTitle: String {
    switch session.phase {
    case .observing: "Observing live signals"
    case .awaitingAccess: "Waiting for storage access"
    case .readyForStorageScan: "Limited folder ready for confirmation"
    case .scanningStorage: "Scanning approved storage scope"
    case .readyToFinish: "Enough evidence to finish"
    case .unavailable: "Required live signals are unavailable"
    case .completed: "Check completed"
    case .cancelled: "Check cancelled"
    case .idle: "Ready"
    }
  }

  private var phaseDetail: String {
    switch session.phase {
    case .awaitingAccess:
      "Enable Full Disk Access once or use the remembered folder scope from Storage."
    case .readyForStorageScan:
      "The remembered Folder Scope covers only that folder. Open Storage and choose Rescan Folder to continue."
    case .scanningStorage:
      "Corewise is reading file metadata locally. No percentage is invented when the total is unknown."
    case .unavailable:
      "The required supported signal was not present. You can finish to see the limitation."
    default:
      "Keep the symptom visible. Navigation and closing the main window do not stop this check."
    }
  }

  private var phaseSymbol: String {
    switch session.phase {
    case .awaitingAccess: "lock.shield"
    case .readyForStorageScan: "folder.badge.questionmark"
    case .scanningStorage: "internaldrive"
    case .readyToFinish: "checkmark.circle"
    case .unavailable: "questionmark.circle"
    default: "record.circle"
    }
  }
}

#Preview("Focused Check — observing") {
  FocusedCheckProgressView(session: PreviewFixtures.focusedSession, cancel: {}, finish: {})
    .padding()
    .frame(width: 980)
}

#Preview("Slow — insufficient observation") {
  FocusedCheckProgressView(
    session: PreviewFixtures.makeFocusedSession(intent: .slow, phase: .observing, elapsed: 8, systemSamples: 3),
    cancel: {},
    finish: {}
  )
  .padding()
  .frame(width: 980)
}

#Preview("Battery — collecting") {
  FocusedCheckProgressView(
    session: PreviewFixtures.makeFocusedSession(intent: .batteryDrain, phase: .observing, elapsed: 360, batterySamples: 5),
    cancel: {},
    finish: {}
  )
  .padding()
  .frame(width: 980)
}

#Preview("Storage — access required") {
  FocusedCheckProgressView(
    session: PreviewFixtures.makeFocusedSession(intent: .storageFull, phase: .awaitingAccess, elapsed: 0),
    cancel: {},
    finish: {}
  )
  .padding()
  .frame(width: 980)
}

#Preview("Storage — limited scope confirmation") {
  FocusedCheckProgressView(
    session: PreviewFixtures.makeFocusedSession(intent: .storageFull, phase: .readyForStorageScan, elapsed: 0),
    cancel: {},
    finish: {}
  )
  .padding()
  .frame(width: 980)
}

#Preview("Storage — scanning") {
  FocusedCheckProgressView(
    session: PreviewFixtures.makeFocusedSession(intent: .storageFull, phase: .scanningStorage, elapsed: 42),
    cancel: {},
    finish: {}
  )
  .padding()
  .frame(width: 980)
}
