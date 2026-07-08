import Foundation

struct ProcessInsightBuilder {
  func insights(for processes: [ProcessObservation]) -> [ProcessInsight] {
    var insights: [ProcessInsight] = []

    let helperMatches = processes.filter {
      $0.displayName.localizedCaseInsensitiveContains("Helper")
        || $0.displayName.localizedCaseInsensitiveContains("Renderer")
    }
    if !helperMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Helpers belong to apps",
          detail: "Browser and Electron apps often split work into helper, renderer, and service processes. Read the app owner before treating a helper row as a separate app.",
          matchedProcessNames: names(helperMatches),
          status: .info
        )
      )
    }

    let electronMatches = processes.filter {
      ($0.appName ?? "").localizedCaseInsensitiveContains("Codex")
        || ($0.path ?? "").localizedCaseInsensitiveContains("Electron")
        || ($0.displayName.localizedCaseInsensitiveContains("Codex") && $0.displayName.localizedCaseInsensitiveContains("Renderer"))
    }
    if !electronMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Electron-style apps can split load",
          detail: "Apps built on web runtimes may show renderer and service rows. Corewise keeps the rows visible so memory and CPU are not hidden behind a single app label.",
          matchedProcessNames: names(electronMatches),
          status: .info
        )
      )
    }

    let windowServerMatches = processes.filter { $0.displayName == "WindowServer" || $0.processName == "WindowServer" }
    if !windowServerMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "WindowServer is display work",
          detail: "WindowServer is macOS drawing windows, displays, spaces, and visual effects. Higher usage can be normal during screen recording, many windows, or external display work.",
          matchedProcessNames: names(windowServerMatches),
          status: .info
        )
      )
    }

    let spotlightMatches = processes.filter {
      $0.displayName.localizedCaseInsensitiveContains("mdworker")
        || $0.displayName.localizedCaseInsensitiveContains("Spotlight")
    }
    if !spotlightMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Spotlight may be indexing",
          detail: "mdworker and Spotlight rows usually mean macOS is indexing files. A short spike is normal; repeated high CPU is what deserves review.",
          matchedProcessNames: names(spotlightMatches),
          status: .info
        )
      )
    }

    let syncMatches = processes.filter {
      $0.displayName.localizedCaseInsensitiveContains("fileproviderd")
        || $0.displayName.localizedCaseInsensitiveContains("CloudDocs")
        || ($0.path ?? "").localizedCaseInsensitiveContains("FileProvider")
    }
    if !syncMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Cloud sync can be visible",
          detail: "fileproviderd and CloudDocs rows are usually file provider or iCloud Drive work. Review them with storage/network context rather than treating them as cleanup targets.",
          matchedProcessNames: names(syncMatches),
          status: .info
        )
      )
    }

    let corewiseMatches = processes.filter { $0.processName == "Corewise" || $0.displayName == "Corewise" }
    if !corewiseMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Corewise includes itself",
          detail: "Corewise appears when refresh or rendering costs CPU or memory. Showing it keeps the sample honest.",
          matchedProcessNames: names(corewiseMatches),
          status: .good
        )
      )
    }

    return insights
  }

  private func names(_ processes: [ProcessObservation]) -> [String] {
    Array(Array(Set(processes.map(\.displayName))).sorted().prefix(5))
  }
}
