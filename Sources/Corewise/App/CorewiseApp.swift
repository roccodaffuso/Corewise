import SwiftUI

@main
struct CorewiseApp: App {
  @NSApplicationDelegateAdaptor(AppActivationDelegate.self) private var appDelegate
  @StateObject private var store = HealthDashboardStore(collector: MockSystemHealthCollector())

  var body: some Scene {
    WindowGroup("Corewise") {
      ContentView(store: store)
        .frame(minWidth: 980, minHeight: 680)
        .task {
          await store.refresh()
        }
    }
    .windowStyle(.hiddenTitleBar)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }

    Settings {
      SettingsView()
    }
  }
}
