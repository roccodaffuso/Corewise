import SwiftUI

struct FocusedCheckLauncher: View {
  var start: (FocusedCheckIntent) -> Void

  var body: some View {
    OperationalSection(
      title: "Focused Check",
      subtitle: "Choose what you are noticing. Corewise will observe supported signals without claiming a cause.",
      instrument: true
    ) {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: CorewiseLayout.space8) {
          ForEach(FocusedCheckIntent.allCases) { intent in
            intentButton(intent)
          }
        }

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: CorewiseLayout.space8)], spacing: CorewiseLayout.space8) {
          ForEach(FocusedCheckIntent.allCases) { intent in
            intentButton(intent)
          }
        }
      }
    }
  }

  private func intentButton(_ intent: FocusedCheckIntent) -> some View {
    Button {
      start(intent)
    } label: {
      HStack(spacing: CorewiseLayout.space8) {
        Image(systemName: symbol(for: intent))
          .foregroundStyle(CorewiseVisual.accent)
        Text(intent.title)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
    }
    .buttonStyle(.bordered)
    .controlSize(.large)
    .accessibilityHint(hint(for: intent))
  }

  private func symbol(for intent: FocusedCheckIntent) -> String {
    switch intent {
    case .slow: "gauge.with.dots.needle.33percent"
    case .hot: "thermometer.medium"
    case .batteryDrain: "battery.25percent"
    case .storageFull: "internaldrive"
    case .general: "waveform.path.ecg"
    }
  }

  private func hint(for intent: FocusedCheckIntent) -> String {
    switch intent {
    case .slow, .hot: "Starts a local observation using the existing live refresh."
    case .batteryDrain: "Starts a longer observation that requires Battery Power."
    case .storageFull: "Uses a completed read-only storage scan."
    case .general: "Explains the current supported Overview signals immediately."
    }
  }
}

#Preview("Focused Check — idle") {
  FocusedCheckLauncher { _ in }
    .padding()
    .frame(width: 980)
}
