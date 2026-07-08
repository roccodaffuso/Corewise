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
    .menuBarExtraStyle(.menu)
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
    if let snapshot {
      Text("Corewise")
        .font(.headline)
      Divider()
      MenuMetricRow(title: "CPU", value: percent(snapshot.performance.cpu.totalPercent))
      MenuMetricRow(title: "Memory", value: menuBytes(snapshot.performance.memory.usedBytes))
      MenuMetricRow(title: "Swap", value: snapshot.performance.memory.swapUsedBytes.map(menuBytes) ?? "N/A")
      MenuMetricRow(title: "Top CPU", value: processValue(topCPUProcess, metric: .cpu))
      MenuMetricRow(title: "Top Memory", value: processValue(topMemoryProcess, metric: .memory))
      Divider()
    } else {
      Text("Checking your Mac...")
      Divider()
    }

    Button {
      openWindow(id: "main")
      NSApp.activate(ignoringOtherApps: true)
    } label: {
      Label("Open Corewise", systemImage: "arrow.up.forward.app")
    }

    Button {
      Task {
        await store.refresh()
      }
    } label: {
      Label("Refresh", systemImage: "arrow.clockwise")
    }
  }

  private enum ProcessMetric {
    case cpu
    case memory
  }

  private func processValue(_ process: ProcessObservation?, metric: ProcessMetric) -> String {
    guard let process else {
      return "N/A"
    }

    switch metric {
    case .cpu:
      return "\(process.displayName) \(number(process.cpuPercent))%"
    case .memory:
      return "\(process.displayName) \(menuBytes(process.observedMemoryBytes))"
    }
  }
}

private struct MenuMetricRow: View {
  var title: String
  var value: String

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .monospacedDigit()
        .foregroundStyle(.secondary)
    }
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
