import SwiftUI

struct BatteryView: View {
  var battery: BatteryHealth

  private var liveMetrics: [DiagnosticMetric] {
    battery.metrics.filter { $0.dataMode == .live }
  }

  private var deferredMetrics: [DiagnosticMetric] {
    battery.metrics.filter { $0.dataMode != .live }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space24) {
        PageHeader(title: "Battery", subtitle: "Power state first, battery detail only when macOS exposes it.", systemImage: "battery.75percent")

        if battery.summary.dataMode == .unavailable {
          ContentUnavailableView(
            "No internal battery",
            systemImage: "battery.0percent",
            description: Text("This Mac did not expose an internal battery through the supported power-source APIs.")
          )
          .frame(maxWidth: .infinity, minHeight: 260)
        } else {
          OperationalSection(title: "Current power", instrument: true) {
            MetricRow(title: battery.summary.title, value: corewiseDisplayValue(battery.summary), detail: battery.summary.explanation, severity: battery.summary.status)
            ForEach(liveMetrics.filter { $0.id != battery.summary.id }) { metric in
              Divider()
              MetricRow(title: metric.title, value: corewiseDisplayValue(metric), detail: metric.explanation, severity: metric.status)
            }
          }
        }

        if !deferredMetrics.isEmpty {
          DisclosureGroup("Unavailable or planned battery detail") {
            VStack(spacing: CorewiseLayout.space12) {
              ForEach(deferredMetrics) { metric in
                MetricRow(title: metric.title, value: corewiseDisplayValue(metric), detail: metric.explanation)
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

        SourceDisclosure(title: "Battery source", detail: battery.sourceNote)
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
  }
}

#Preview("Battery — unavailable") {
  BatteryView(battery: PreviewFixtures.battery)
    .frame(width: 980, height: 680)
}
