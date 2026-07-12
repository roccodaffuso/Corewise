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
          interpretation: interpretation(for: helperMatches),
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
          interpretation: interpretation(for: electronMatches),
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
          interpretation: interpretation(for: windowServerMatches),
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
          interpretation: interpretation(for: spotlightMatches),
          status: .info
        )
      )
    }

    let syncMatches = processes.filter {
      $0.displayName.localizedCaseInsensitiveContains("fileproviderd")
        || $0.displayName.localizedCaseInsensitiveContains("bird")
        || $0.displayName.localizedCaseInsensitiveContains("cloudd")
        || $0.displayName.localizedCaseInsensitiveContains("CloudDocs")
        || ($0.path ?? "").localizedCaseInsensitiveContains("FileProvider")
    }
    if !syncMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Cloud sync can be visible",
          detail: "fileproviderd, bird, cloudd, and CloudDocs rows are usually file provider or iCloud Drive work. Review them with storage/network context rather than treating them as removal targets.",
          matchedProcessNames: names(syncMatches),
          interpretation: interpretation(for: syncMatches),
          status: .info
        )
      )
    }

    let mediaMatches = processes.filter {
      $0.displayName.localizedCaseInsensitiveContains("VTDecoder")
        || $0.displayName.localizedCaseInsensitiveContains("mediaanalysis")
        || $0.displayName.localizedCaseInsensitiveContains("photolibraryd")
        || $0.displayName.localizedCaseInsensitiveContains("coreaudiod")
        || ($0.path ?? "").localizedCaseInsensitiveContains("VideoToolbox")
    }
    if !mediaMatches.isEmpty {
      insights.append(
        ProcessInsight(
          title: "Media services can spike briefly",
          detail: "Video, audio, and photo-analysis services can appear during playback, calls, imports, or previews. Repeated high CPU is more meaningful than a short burst.",
          matchedProcessNames: names(mediaMatches),
          interpretation: interpretation(for: mediaMatches),
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
          interpretation: interpretation(for: corewiseMatches),
          status: .good
        )
      )
    }

    return insights
  }

  private func names(_ processes: [ProcessObservation]) -> [String] {
    Array(Array(Set(processes.map(\.displayName))).sorted().prefix(5))
  }

  private func interpretation(for processes: [ProcessObservation]) -> String {
    let highestCPU = processes.map(\.cpuPercent).max() ?? 0
    let highestMemory = processes.map(\.observedMemoryBytes).max() ?? 0
    if highestCPU >= 50 || highestMemory >= 2 * 1024 * 1024 * 1024 {
      return "Investigate"
    }
    if highestCPU >= 15 || highestMemory >= 750 * 1024 * 1024 {
      return "Worth watching"
    }
    return "Normal"
  }
}
