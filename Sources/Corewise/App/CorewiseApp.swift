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
  @AppStorage(CorewiseSettingsKeys.menuBarShowCPU) private var showCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowMemory) private var showMemory = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowSwap) private var showSwap = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopCPU) private var showTopCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopMemory) private var showTopMemory = true

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
        if showCPU || showMemory || showSwap {
          HStack(spacing: 8) {
            if showCPU {
              MenuMetricCard(
                title: "CPU",
                value: percent(snapshot.performance.cpu.totalPercent),
                detail: "total load",
                progress: normalized(snapshot.performance.cpu.totalPercent, max: 100),
                tint: CorewiseVisual.accent
              )
            }
            if showMemory {
              MenuMetricCard(
                title: "Memory",
                value: menuBytes(snapshot.performance.memory.usedBytes),
                detail: "\(number(snapshot.performance.memory.usedPercent))% used",
                progress: fraction(snapshot.performance.memory.usedBytes, of: snapshot.performance.memory.physicalBytes),
                tint: CorewiseVisual.moss
              )
            }
            if showSwap {
              let swap = snapshot.performance.memory.swap
              MenuMetricCard(
                title: "Swap",
                value: swap.map { menuBytes($0.usedBytes) } ?? "N/A",
                detail: swap.map { "of \(menuBytes($0.totalBytes))" } ?? "unavailable",
                progress: swap.map { fraction($0.usedBytes, of: $0.totalBytes) } ?? 0,
                tint: CorewiseVisual.amber
              )
            }
          }
        }

        if showTopCPU || showTopMemory {
          VStack(spacing: 8) {
            if showTopCPU {
              MenuProcessRow(
                title: "Top CPU",
                name: topCPUProcess?.displayName ?? "N/A",
                value: topCPUProcess.map { "\(number($0.cpuPercent))%" } ?? "N/A",
                progress: topCPUProcess.map { normalized($0.cpuPercent, max: 100) } ?? 0,
                tint: CorewiseVisual.accent
              )
            }
            if showTopMemory {
              MenuProcessRow(
                title: "Top Memory",
                name: topMemoryProcess?.displayName ?? "N/A",
                value: topMemoryProcess.map { menuBytes($0.observedMemoryBytes) } ?? "N/A",
                progress: topMemoryProcess.map { fraction($0.observedMemoryBytes, of: snapshot.performance.memory.physicalBytes) } ?? 0,
                tint: CorewiseVisual.moss
              )
            }
          }
        }

        if !showCPU && !showMemory && !showSwap && !showTopCPU && !showTopMemory {
          Text("Menu bar signals are hidden in Settings.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 70)
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

  private func normalized(_ value: Double?, max: Double) -> Double {
    guard let value, max > 0 else {
      return 0
    }
    return min(Swift.max(value / max, 0), 1)
  }

  private func fraction(_ value: UInt64, of total: UInt64) -> Double {
    guard total > 0 else {
      return 0
    }
    return min(Swift.max(Double(value) / Double(total), 0), 1)
  }
}

private struct MenuMetricCard: View {
  var title: String
  var value: String
  var detail: String
  var progress: Double
  var tint: Color
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(value)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
      MenuUsageBar(progress: progress, tint: tint)
      Text(detail)
        .font(.system(size: 9, weight: .medium, design: .rounded))
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(.regularMaterial)
        .overlay(tint.opacity(colorScheme == .dark ? 0.16 : 0.11))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .stroke(tint.opacity(colorScheme == .dark ? 0.18 : 0.14), lineWidth: 1)
    }
  }
}

private struct MenuProcessRow: View {
  var title: String
  var name: String
  var value: String
  var progress: Double
  var tint: Color
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
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

      MenuUsageBar(progress: progress, tint: tint)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
    .background {
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .fill(.regularMaterial)
        .overlay(Color.primary.opacity(colorScheme == .dark ? 0.04 : 0.02))
    }
    .overlay {
      RoundedRectangle(cornerRadius: 11, style: .continuous)
        .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.06), lineWidth: 1)
    }
  }

  private func shortName(_ value: String) -> String {
    if value.count <= 24 {
      return value
    }

    return String(value.prefix(21)) + "..."
  }
}

private struct MenuUsageBar: View {
  var progress: Double
  var tint: Color

  var body: some View {
    GeometryReader { proxy in
      let width = max(proxy.size.width * min(max(progress, 0), 1), 4)
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.primary.opacity(0.10))
        Capsule()
          .fill(
            LinearGradient(
              colors: [tint.opacity(0.72), tint],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: width)
      }
    }
    .frame(height: 5)
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
