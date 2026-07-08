import SwiftUI

@main
struct CorewiseApp: App {
  @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appDelegate
  @StateObject private var store = HealthDashboardStore(collector: SystemHealthCollector())

  var body: some Scene {
    WindowGroup("Corewise", id: "main") {
      ContentView(store: store)
        .frame(minWidth: 980, minHeight: 680)
        .task {
          await store.startLiveRefresh()
        }
    }
    .windowStyle(.hiddenTitleBar)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }

    Settings {
      SettingsView()
    }

    MenuBarExtra("Corewise", systemImage: "waveform.path.ecg") {
      MenuBarMonitorView(store: store)
    }
    .menuBarExtraStyle(.window)
  }
}

private struct MenuBarMonitorView: View {
  @ObservedObject var store: HealthDashboardStore
  @Environment(\.openWindow) private var openWindow

  private var snapshot: HealthSnapshot? {
    store.snapshot
  }

  private var topCPUProcess: ProcessObservation? {
    snapshot?.performance.processes.max { $0.cpuPercent < $1.cpuPercent }
  }

  private var topMemoryProcess: ProcessObservation? {
    snapshot?.performance.processes.max { $0.observedMemoryBytes < $1.observedMemoryBytes }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .center, spacing: 10) {
        Image(systemName: "waveform.path.ecg")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(CorewiseVisual.moss)
          .frame(width: 30, height: 30)
          .background(CorewiseVisual.moss.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

        VStack(alignment: .leading, spacing: 1) {
          Text("Corewise")
            .font(.headline.weight(.semibold))
          Text(snapshot == nil ? "Checking your Mac" : "Live local signals")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 0)
      }

      if let snapshot {
        HStack(spacing: 8) {
          MenuMetricCard(title: "CPU", value: percent(snapshot.performance.cpu.totalPercent), tint: CorewiseVisual.accent)
          MenuMetricCard(title: "Memory", value: menuBytes(snapshot.performance.memory.usedBytes), tint: CorewiseVisual.moss)
          MenuMetricCard(title: "Swap", value: snapshot.performance.memory.swapUsedBytes.map(menuBytes) ?? "N/A", tint: CorewiseVisual.amber)
        }

        VStack(spacing: 8) {
          MenuProcessRow(title: "Top CPU", name: topCPUProcess?.displayName ?? "N/A", value: topCPUProcess.map { "\(number($0.cpuPercent))%" } ?? "N/A")
          MenuProcessRow(title: "Top Memory", name: topMemoryProcess?.displayName ?? "N/A", value: topMemoryProcess.map { menuBytes($0.observedMemoryBytes) } ?? "N/A")
        }
      } else {
        ProgressView()
          .frame(maxWidth: .infinity, minHeight: 92)
      }

      Divider()

      Button {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
      } label: {
        Label("Open Corewise", systemImage: "arrow.up.forward.app")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(16)
    .frame(width: 320)
  }

}

private struct MenuMetricCard: View {
  var title: String
  var value: String
  var tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

private struct MenuProcessRow: View {
  var title: String
  var name: String
  var value: String

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(shortName(name))
          .font(.callout.weight(.semibold))
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      Text(value)
        .font(.callout.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 9)
    .background(.quinary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private func shortName(_ value: String) -> String {
    if value.count <= 24 {
      return value
    }

    return String(value.prefix(21)) + "..."
  }
}

private func percent(_ value: Double?) -> String {
  guard let value else {
    return "N/A"
  }

  return "\(number(value))%"
}

private func menuBytes(_ value: UInt64) -> String {
  let gb = Double(value) / SystemMetricsSampler.bytesPerGB
  if gb >= 1 {
    return "\(number(gb)) GB"
  }

  let mb = Double(value) / (1024.0 * 1024.0)
  return "\(number(mb)) MB"
}

private func number(_ value: Double) -> String {
  if value.rounded() == value {
    return String(Int(value))
  }

  return String(format: "%.1f", value)
}
