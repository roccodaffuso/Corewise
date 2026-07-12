import Foundation

enum QuickActionID: Hashable, Sendable {
  case navigate(DashboardSection)
  case openAIWorkloads
  case refresh
  case openSettings
  case enableFullStorageAnalysis
  case startFocusedCheck(FocusedCheckIntent)
  case finishFocusedCheck
  case cancelFocusedCheck
  case copyFocusedCheck
  case copySummary
  case copyMarkdown
}

struct QuickActionDescriptor: Identifiable, Hashable, Sendable {
  var id: QuickActionID
  var title: String
  var subtitle: String
  var systemImage: String
  var keywords: [String]

  func matches(_ query: String) -> Bool {
    guard !query.isEmpty else {
      return true
    }
    return ([title, subtitle] + keywords).contains { $0.localizedStandardContains(query) }
  }

  static let all: [QuickActionDescriptor] =
    DashboardSection.allCases.map {
      QuickActionDescriptor(
        id: .navigate($0),
        title: "Open \($0.title)",
        subtitle: "Navigate to the \($0.title) section",
        systemImage: $0.systemImage,
        keywords: ["navigate", "section"]
      )
    } + FocusedCheckIntent.allCases.map {
      QuickActionDescriptor(id: .startFocusedCheck($0), title: "Start: \($0.title)", subtitle: "Begin a Focused Check from Overview", systemImage: "scope", keywords: ["diagnose", "observe", "check"])
    } + [
      QuickActionDescriptor(id: .openAIWorkloads, title: "Open AI Workloads", subtitle: "Review supported local AI resource use", systemImage: "sparkles.rectangle.stack", keywords: ["codex", "claude", "cursor", "ollama", "performance"]),
      QuickActionDescriptor(id: .refresh, title: "Refresh Signals", subtitle: "Collect a new local snapshot", systemImage: "arrow.clockwise", keywords: ["update", "reload"]),
      QuickActionDescriptor(id: .openSettings, title: "Open Settings", subtitle: "Change Corewise preferences", systemImage: "gearshape", keywords: ["preferences"]),
      QuickActionDescriptor(id: .enableFullStorageAnalysis, title: "Enable Full Storage Analysis", subtitle: "Grant one permission for user-started read-only scans", systemImage: "lock.shield", keywords: ["privacy", "storage", "scan", "permission"]),
      QuickActionDescriptor(id: .copySummary, title: "Copy Summary", subtitle: "Copy the concise local report", systemImage: "doc.on.clipboard", keywords: ["report", "clipboard"]),
      QuickActionDescriptor(id: .copyMarkdown, title: "Copy Markdown Report", subtitle: "Copy the detailed local report", systemImage: "text.page", keywords: ["report", "clipboard"])
    ]

  static func available(session: FocusedCheckSession?, result: FocusedCheckResult?) -> [QuickActionDescriptor] {
    var descriptors = all
    if session != nil, session?.phase != .completed {
      descriptors.removeAll {
        if case .startFocusedCheck = $0.id { return true }
        return false
      }
    }
    if session != nil, session?.phase != .completed {
      if session?.intent != .storageFull {
        descriptors.append(QuickActionDescriptor(id: .finishFocusedCheck, title: "Finish Focused Check", subtitle: "Resolve the observation collected so far", systemImage: "checkmark.circle", keywords: ["diagnose", "result"]))
      }
      descriptors.append(QuickActionDescriptor(id: .cancelFocusedCheck, title: "Cancel Focused Check", subtitle: "Discard the partial observation", systemImage: "stop.circle", keywords: ["diagnose", "stop"]))
    }
    if result != nil {
      descriptors.append(QuickActionDescriptor(id: .copyFocusedCheck, title: "Copy Focused Check", subtitle: "Copy the latest focused result", systemImage: "scope", keywords: ["diagnose", "clipboard", "result"]))
    }
    return descriptors
  }
}
