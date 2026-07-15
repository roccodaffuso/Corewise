// SPDX-License-Identifier: MPL-2.0

import Foundation

enum ProcessInterpretationFamily: String, CaseIterable, Sendable {
  case appHelper
  case windowServer
  case spotlight
  case cloudSync
  case mediaAnalysis
  case corewise
  case unknown
}

enum ProcessActivityPattern: String, Sendable {
  case currentSampleOnly
  case transient
  case repeated
  case sustained

  var title: String {
    switch self {
    case .currentSampleOnly: corewiseText("Current sample only", comment: "Process observation pattern")
    case .transient: corewiseText("Observed briefly in this check", comment: "Process observation pattern")
    case .repeated: corewiseText("Repeated during this check", comment: "Process observation pattern")
    case .sustained: corewiseText("Sustained during this check", comment: "Process observation pattern")
    }
  }
}

struct ProcessInterpretation: Equatable, Sendable {
  var family: ProcessInterpretationFamily
  var title: String
  var detail: String
  var ownerName: String?
  var expectedContexts: [String]
  var activityPattern: ProcessActivityPattern
  var safeReviewAction: String
  var matchedPIDs: [Int32]
}

enum ProcessInterpretationResolver {
  static func interpretation(
    for process: ProcessObservation,
    activity: FocusedCheckActivitySummary? = nil
  ) -> ProcessInterpretation {
    let name = process.displayName.lowercased()
    let path = process.path?.lowercased() ?? ""

    if process.processName == "Corewise" || process.displayName == "Corewise" {
      return make(
        family: .corewise,
        title: corewiseText("Corewise monitoring work", comment: "Process interpretation title"),
        detail: corewiseText("Corewise includes its own refresh and rendering cost so the sample stays transparent.", comment: "Process interpretation detail"),
        ownerName: "Corewise",
        expectedContexts: [
          corewiseText("Live signal refresh", comment: "Expected process context"),
          corewiseText("Rendering Corewise views", comment: "Expected process context"),
          corewiseText("An explicit Storage analysis", comment: "Expected process context")
        ],
        safeReviewAction: corewiseText("Compare Corewise activity while idle and while an explicit check is running.", comment: "Safe process review action"),
        process: process,
        activity: activity
      )
    }
    if process.processName == "WindowServer" || process.displayName == "WindowServer" {
      return make(
        family: .windowServer,
        title: corewiseText("macOS display work", comment: "Process interpretation title"),
        detail: corewiseText("WindowServer draws windows, displays, spaces, and visual effects. Activity here may coincide with display-heavy work.", comment: "Process interpretation detail"),
        ownerName: "macOS",
        expectedContexts: [
          corewiseText("Moving or resizing windows", comment: "Expected process context"),
          corewiseText("Multiple displays or spaces", comment: "Expected process context"),
          corewiseText("Animation and screen sharing", comment: "Expected process context")
        ],
        safeReviewAction: corewiseText("Compare the activity after closing optional display-heavy windows or disconnecting an unused display.", comment: "Safe process review action"),
        process: process,
        activity: activity
      )
    }
    if name.contains("mdworker") || name.contains("spotlight") {
      return make(
        family: .spotlight,
        title: corewiseText("Spotlight indexing", comment: "Process interpretation title"),
        detail: corewiseText("This process is commonly associated with file indexing. Repeated activity is more useful than a single spike.", comment: "Process interpretation detail"),
        ownerName: "macOS",
        expectedContexts: [
          corewiseText("New or changed files", comment: "Expected process context"),
          corewiseText("A recent macOS update", comment: "Expected process context"),
          corewiseText("An attached or restored volume", comment: "Expected process context")
        ],
        safeReviewAction: corewiseText("Allow indexing to settle, then repeat the check if the activity remains persistent.", comment: "Safe process review action"),
        process: process,
        activity: activity
      )
    }
    if ["fileproviderd", "bird", "cloudd", "clouddocs"].contains(where: name.contains) || path.contains("fileprovider") {
      return make(
        family: .cloudSync,
        title: corewiseText("Cloud or file-provider work", comment: "Process interpretation title"),
        detail: corewiseText("This process is commonly associated with file synchronization. Review it with the owning service rather than as a removal target.", comment: "Process interpretation detail"),
        ownerName: process.appName ?? "macOS",
        expectedContexts: [
          corewiseText("Uploading or downloading files", comment: "Expected process context"),
          corewiseText("A large sync queue", comment: "Expected process context"),
          corewiseText("Reconnecting after being offline", comment: "Expected process context")
        ],
        safeReviewAction: corewiseText("Open the owning sync service and review its current queue or status.", comment: "Safe process review action"),
        process: process,
        activity: activity
      )
    }
    if ["vtdecoder", "mediaanalysis", "photolibraryd", "coreaudiod"].contains(where: name.contains) || path.contains("videotoolbox") {
      return make(
        family: .mediaAnalysis,
        title: corewiseText("Media or photo analysis", comment: "Process interpretation title"),
        detail: corewiseText("This process may appear during playback, calls, imports, previews, or photo analysis. Corewise does not identify it as the source of the current symptom.", comment: "Process interpretation detail"),
        ownerName: process.appName ?? "macOS",
        expectedContexts: [
          corewiseText("Video playback or calls", comment: "Expected process context"),
          corewiseText("Photo or media imports", comment: "Expected process context"),
          corewiseText("Background library analysis", comment: "Expected process context")
        ],
        safeReviewAction: corewiseText("Check whether a related media task is active and repeat the observation after it finishes.", comment: "Safe process review action"),
        process: process,
        activity: activity
      )
    }
    if name.contains("helper") || name.contains("renderer") || path.contains("/frameworks/") {
      return make(
        family: .appHelper,
        title: corewiseText("Part of an app process group", comment: "Process interpretation title"),
        detail: corewiseText("Apps can split work into helper, renderer, and service processes. Review the owning app group before treating this row independently.", comment: "Process interpretation detail"),
        ownerName: process.appName,
        expectedContexts: [
          corewiseText("Web or document rendering", comment: "Expected process context"),
          corewiseText("Extensions and background services", comment: "Expected process context"),
          corewiseText("Multiple app windows or tabs", comment: "Expected process context")
        ],
        safeReviewAction: corewiseText("Review the owning app group and its workload before acting on this helper alone.", comment: "Safe process review action"),
        process: process,
        activity: activity
      )
    }
    return make(
      family: .unknown,
      title: corewiseText("No typed interpretation", comment: "Process interpretation title"),
      detail: corewiseText("Corewise has live resource values for this process but no reliable explanatory family. The raw process row remains the source of truth.", comment: "Process interpretation detail"),
      ownerName: process.appName,
      expectedContexts: [],
      safeReviewAction: corewiseText("Use the executable path and owning app as context before deciding whether the activity is expected.", comment: "Safe process review action"),
      process: process,
      activity: activity
    )
  }

  private static func make(
    family: ProcessInterpretationFamily,
    title: String,
    detail: String,
    ownerName: String?,
    expectedContexts: [String],
    safeReviewAction: String,
    process: ProcessObservation,
    activity: FocusedCheckActivitySummary?
  ) -> ProcessInterpretation {
    let activityPattern: ProcessActivityPattern
    if let activity {
      if activity.activeCPUSampleCount >= 3 {
        activityPattern = .sustained
      } else if activity.sampleCount >= 3 {
        activityPattern = .repeated
      } else {
        activityPattern = .transient
      }
    } else {
      activityPattern = .currentSampleOnly
    }

    return ProcessInterpretation(
      family: family,
      title: title,
      detail: detail,
      ownerName: ownerName,
      expectedContexts: expectedContexts,
      activityPattern: activityPattern,
      safeReviewAction: safeReviewAction,
      matchedPIDs: activity?.memberPIDs ?? [process.pid]
    )
  }
}
