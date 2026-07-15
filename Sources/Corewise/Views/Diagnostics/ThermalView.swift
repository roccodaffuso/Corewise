// SPDX-License-Identifier: MPL-2.0

import SwiftUI

struct ThermalView: View {
  var thermal: ThermalHealth

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space24) {
        PageHeader(title: "Thermal", subtitle: "The safe high-level macOS pressure state, without invented temperatures.", systemImage: "thermometer.medium")

        OperationalSection(title: "Current thermal state", instrument: true) {
          MetricRow(title: thermal.summary.title, value: corewiseDisplayValue(thermal.summary), detail: thermal.summary.explanation, severity: thermal.summary.status)
        }

        if thermal.contributors.count > 2 {
          OperationalSection(title: "Related recent signal", subtitle: "Correlation only; Corewise does not assign thermal cause.") {
            ForEach(thermal.contributors.dropFirst(2)) { finding in
              MetricRow(title: finding.title, value: finding.status.rawValue, detail: finding.detail, severity: finding.status)
            }
          }
        }

        SourceDisclosure(title: "Thermal limits", detail: thermal.sourceNote)
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
  }
}

#Preview("Thermal — nominal") {
  ThermalView(thermal: PreviewFixtures.thermal)
    .frame(width: 980, height: 680)
}
