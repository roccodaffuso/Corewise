import SwiftUI

struct SettingsView: View {
  var body: some View {
    TabView {
      GeneralSettingsPane()
        .tabItem {
          Label("General", systemImage: "gearshape")
        }

      PrivacySettingsPane()
        .tabItem {
          Label("Privacy", systemImage: "lock.shield")
        }

      PerformanceSettingsPane()
        .tabItem {
          Label("Performance", systemImage: "cpu")
        }

      ReportSettingsPane()
        .tabItem {
          Label("Report", systemImage: "doc.text")
        }

      MenuBarSettingsPane()
        .tabItem {
          Label("Menu Bar", systemImage: "menubar.rectangle")
        }
    }
    .frame(width: 540, height: 390)
    .scenePadding()
  }
}

private struct GeneralSettingsPane: View {
  var body: some View {
    Form {
      Section("Corewise") {
        SettingsInfoRow(title: "Local only", detail: "Corewise runs on this Mac. There is no account, backend, tracking, or telemetry.")
        SettingsInfoRow(title: "MVP status", detail: "Some diagnostics are live, while unavailable or planned signals stay clearly labeled.")
        SettingsInfoRow(title: "Manual control", detail: "Corewise explains what it can see and leaves changes to macOS, Finder, or vendor tools.")
      }
    }
  }
}

private struct PrivacySettingsPane: View {
  var body: some View {
    Form {
      Section("Automatic reads") {
        SettingsInfoRow(title: "Local system signals", detail: "CPU, memory, process rows, storage volume, battery basics, thermal state, and readable launch plist metadata.")
      }

      Section("User-selected reads") {
        SettingsInfoRow(title: "Folder scans", detail: "Storage details are read only after you choose a folder.")
        SettingsInfoRow(title: "Crash reports", detail: "Crash report metadata is read only after you choose a reports folder.")
      }

      Section("Avoided") {
        SettingsInfoRow(title: "Manual review only", detail: "Corewise does not delete files, empty Trash, kill processes, use elevated tools, or read private hardware paths.")
      }
    }
  }
}

private struct PerformanceSettingsPane: View {
  @AppStorage(CorewiseSettingsKeys.performanceDefaultFocus) private var defaultFocus = PerformanceDefaultFocus.cpu.rawValue

  var body: some View {
    Form {
      Section("Display") {
        Picker("Default focus", selection: $defaultFocus) {
          ForEach(PerformanceDefaultFocus.allCases) { focus in
            Text(focus.title).tag(focus.rawValue)
          }
        }
        .pickerStyle(.segmented)

        Text("This only chooses the initial Performance view. It does not change collection or hide real process rows.")
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct ReportSettingsPane: View {
  @AppStorage(CorewiseSettingsKeys.reportDefaultFormat) private var defaultFormat = ReportFormatPreference.summary.rawValue
  @AppStorage(CorewiseSettingsKeys.reportIncludeStorageScan) private var includeStorageScan = true
  @AppStorage(CorewiseSettingsKeys.reportIncludeCrashSummary) private var includeCrashSummary = true

  var body: some View {
    Form {
      Section("Default format") {
        Picker("Report view", selection: $defaultFormat) {
          ForEach(ReportFormatPreference.allCases) { format in
            Text(format.title).tag(format.rawValue)
          }
        }
        .pickerStyle(.segmented)
      }

      Section("Included summaries") {
        Toggle("Include selected storage scan", isOn: $includeStorageScan)
        Toggle("Include crash report summary", isOn: $includeCrashSummary)
        Text("Reports never include raw crash bodies, stack traces, uploads, or file contents.")
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct MenuBarSettingsPane: View {
  @AppStorage(CorewiseSettingsKeys.menuBarShowCPU) private var showCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowMemory) private var showMemory = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowSwap) private var showSwap = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopCPU) private var showTopCPU = true
  @AppStorage(CorewiseSettingsKeys.menuBarShowTopMemory) private var showTopMemory = true

  var body: some View {
    Form {
      Section("Metrics") {
        Toggle("Show CPU", isOn: $showCPU)
        Toggle("Show Memory", isOn: $showMemory)
        Toggle("Show Swap", isOn: $showSwap)
      }

      Section("Process rows") {
        Toggle("Show Top CPU rows", isOn: $showTopCPU)
        Toggle("Show Top Memory rows", isOn: $showTopMemory)
        Text("The menu bar monitor reuses the current Corewise snapshot and does not start another collector.")
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct SettingsInfoRow: View {
  var title: String
  var detail: String

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title)
        .font(.callout.weight(.semibold))
      Text(detail)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 2)
  }
}
