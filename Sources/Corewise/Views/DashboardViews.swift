import SwiftUI

struct OverviewView: View {
  var snapshot: HealthSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      StatusHeader(status: snapshot.overallStatus, generatedAt: snapshot.generatedAt)

      SectionCard("Suggestions", systemImage: "lightbulb") {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(snapshot.suggestions) { suggestion in
            FindingRow(
              title: suggestion.title,
              detail: suggestion.body,
              value: suggestion.severity.rawValue,
              severity: suggestion.severity
            )
          }
        }
      }

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
        SnapshotTile(title: "Battery", value: "\(snapshot.battery.maximumCapacityPercent)%", detail: snapshot.battery.condition, systemImage: "battery.75percent")
        SnapshotTile(title: "Storage", value: snapshot.storage.freeSpaceDescription, detail: "Read-only review", systemImage: "internaldrive")
        SnapshotTile(title: "Thermal", value: snapshot.thermal.state, detail: snapshot.thermal.detail, systemImage: "thermometer.medium")
      }
    }
  }
}

struct BatteryView: View {
  var battery: BatteryHealth

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      SectionCard("Battery Health", systemImage: "battery.75percent") {
        VStack(alignment: .leading, spacing: 12) {
          MetricRow(title: "Cycle count", value: "\(battery.cycleCount)")
          MetricRow(title: "Maximum capacity", value: "\(battery.maximumCapacityPercent)%")
          MetricRow(title: "Condition", value: battery.condition)
          MetricRow(title: "Recent energy impact", value: battery.recentEnergyImpact)
        }
      }
      SourceNote(text: battery.sourceNote)
    }
  }
}

struct StorageView: View {
  var storage: StorageHealth

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      SectionCard("Storage", systemImage: "internaldrive") {
        MetricRow(title: "Free space", value: storage.freeSpaceDescription)
      }
      StorageList(title: "Large folders", items: storage.largeFolders)
      StorageList(title: "Large caches", items: storage.largeCaches)
      StorageList(title: "Huge files", items: storage.hugeFiles)
      SourceNote(text: storage.sourceNote)
    }
  }
}

struct PerformanceView: View {
  var performance: PerformanceHealth

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      ProcessList(title: "Highest CPU", items: performance.cpuProcesses)
      ProcessList(title: "Highest Memory", items: performance.memoryProcesses)
      SourceNote(text: performance.sourceNote)
    }
  }
}

struct StartupView: View {
  var items: [StartupItem]

  var body: some View {
    SectionCard("Startup and Login Items", systemImage: "power") {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(items) { item in
          FindingRow(
            title: item.name,
            detail: item.location,
            value: "\(item.probableImpact) impact",
            severity: item.severity
          )
        }
      }
    }
  }
}

struct ThermalView: View {
  var thermal: ThermalHealth

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      SectionCard("Thermal", systemImage: "thermometer.medium") {
        FindingRow(title: thermal.state, detail: thermal.detail, value: thermal.severity.rawValue, severity: thermal.severity)
      }
      SourceNote(text: thermal.sourceNote)
    }
  }
}

struct IssuesView: View {
  var issues: [CrashIssue]

  var body: some View {
    SectionCard("Crash and App Issues", systemImage: "app.badge") {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(issues) { issue in
          FindingRow(
            title: issue.appName,
            detail: issue.detail,
            value: issue.countDescription,
            severity: issue.severity
          )
        }
      }
    }
  }
}

struct SettingsView: View {
  var body: some View {
    Form {
      Text("Corewise is local-first. This MVP does not use accounts, backend services, tracking, or automatic cleanup.")
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(width: 460)
  }
}

private struct StatusHeader: View {
  var status: OverallStatus
  var generatedAt: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Image(systemName: status.systemImage)
          .font(.system(size: 34))
          .foregroundStyle(color(for: status))
        Text(status.rawValue)
          .font(.largeTitle.weight(.semibold))
        Spacer()
      }

      Text("Know what your Mac is really doing.")
        .font(.title3)
        .foregroundStyle(.primary)

      Text(status.summary)
        .foregroundStyle(.secondary)

      Text("Updated \(generatedAt.formatted(date: .abbreviated, time: .shortened))")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(22)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct SectionCard<Content: View>: View {
  private var title: String
  private var systemImage: String
  private var content: Content

  init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.systemImage = systemImage
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      content
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct SnapshotTile: View {
  var title: String
  var value: String
  var detail: String
  var systemImage: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: systemImage)
        .font(.headline)
      Text(value)
        .font(.title3.weight(.semibold))
        .lineLimit(2)
      Text(detail)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .padding(16)
    .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct StorageList: View {
  var title: String
  var items: [StorageItem]

  var body: some View {
    SectionCard(title, systemImage: "folder") {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(items) { item in
          FindingRow(title: item.name, detail: item.detail, value: item.sizeDescription, severity: item.severity)
        }
      }
    }
  }
}

private struct ProcessList: View {
  var title: String
  var items: [ProcessSample]

  var body: some View {
    SectionCard(title, systemImage: "waveform.path.ecg") {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(items) { item in
          FindingRow(title: item.name, detail: item.detail, value: item.metric, severity: item.severity)
        }
      }
    }
  }
}

private struct FindingRow: View {
  var title: String
  var detail: String
  var value: String
  var severity: FindingSeverity

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Circle()
        .fill(color(for: severity))
        .frame(width: 8, height: 8)
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.body.weight(.medium))
        Text(detail)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 18)
      Text(value)
        .font(.callout.weight(.medium))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.trailing)
    }
  }
}

private struct MetricRow: View {
  var title: String
  var value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .foregroundStyle(.secondary)
      Spacer(minLength: 16)
      Text(value)
        .fontWeight(.medium)
        .multilineTextAlignment(.trailing)
    }
  }
}

private struct SourceNote: View {
  var text: String

  var body: some View {
    Text(text)
      .font(.callout)
      .foregroundStyle(.secondary)
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private func color(for status: OverallStatus) -> Color {
  switch status {
  case .good:
    .green
  case .needsAttention:
    .orange
  case .critical:
    .red
  }
}

private func color(for severity: FindingSeverity) -> Color {
  switch severity {
  case .good:
    .green
  case .info:
    .blue
  case .warning:
    .orange
  case .critical:
    .red
  }
}
