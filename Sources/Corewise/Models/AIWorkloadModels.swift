import Foundation

struct AIWorkloadID: RawRepresentable, Hashable, Sendable, Identifiable {
  var rawValue: String
  var id: String { rawValue }

  init(rawValue: String) {
    self.rawValue = rawValue
  }

  static let codex = AIWorkloadID(rawValue: "codex")
  static let claude = AIWorkloadID(rawValue: "claude")
  static let cursor = AIWorkloadID(rawValue: "cursor")
  static let ollama = AIWorkloadID(rawValue: "ollama")
  static let windsurf = AIWorkloadID(rawValue: "windsurf")
  static let lmStudio = AIWorkloadID(rawValue: "lm-studio")
  static let gemini = AIWorkloadID(rawValue: "gemini-cli")
  static let aider = AIWorkloadID(rawValue: "aider")
}

enum AIWorkloadCategory: String, Sendable {
  case codingAgent
  case aiEditor
  case cliAgent
  case localModelRuntime
}

enum AIWorkloadSupportLevel: String, Sendable {
  case verified
  case bestEffort

  var title: String {
    switch self {
    case .verified: corewiseText("Verified", comment: "AI workload support level")
    case .bestEffort: corewiseText("Best effort", comment: "AI workload support level")
    }
  }
}

enum AIWorkloadSurface: String, Sendable {
  case desktop
  case cli
  case embeddedRuntime
  case localRuntime
  case sharedHost

  var title: String {
    switch self {
    case .desktop: corewiseText("Desktop", comment: "AI workload surface")
    case .cli: corewiseText("CLI", comment: "AI workload surface")
    case .embeddedRuntime: corewiseText("Embedded runtime", comment: "AI workload surface")
    case .localRuntime: corewiseText("Local runtime", comment: "AI workload surface")
    case .sharedHost: corewiseText("Shared host", comment: "AI workload surface")
    }
  }
}

enum AIProcessRole: String, Sendable {
  case host
  case renderer
  case service
  case agentRuntime
  case commandHost
  case spawnedTool
  case localModel
  case helper
  case sharedHost
  case unknown

  var title: String {
    switch self {
    case .host: corewiseText("Host", comment: "AI process role")
    case .renderer: corewiseText("Renderer", comment: "AI process role")
    case .service: corewiseText("Service", comment: "AI process role")
    case .agentRuntime: corewiseText("Agent runtime", comment: "AI process role")
    case .commandHost: corewiseText("Command host", comment: "AI process role")
    case .spawnedTool: corewiseText("Related local work", comment: "AI process role")
    case .localModel: corewiseText("Local model runtime", comment: "AI process role")
    case .helper: corewiseText("Helper", comment: "AI process role")
    case .sharedHost: corewiseText("Shared host", comment: "AI process role")
    case .unknown: corewiseText("Other component", comment: "AI process role")
    }
  }
}

enum AIAttributionKind: String, Sendable {
  case direct
  case descendant
  case sharedHost
}

enum AIWorkloadActivity: String, Sendable {
  case active
  case sustained
  case quiet
  case notObserved

  var title: String {
    switch self {
    case .active: corewiseText("Active", comment: "AI workload activity")
    case .sustained: corewiseText("Sustained", comment: "AI workload activity")
    case .quiet: corewiseText("Quiet", comment: "AI workload activity")
    case .notObserved: corewiseText("Not observed", comment: "AI workload activity")
    }
  }
}

struct AIWorkloadDescriptor: Identifiable, Hashable, Sendable {
  struct MatchRule: Hashable, Sendable {
    var exactExecutableNames: Set<String> = []
    var exactBundleNames: Set<String> = []
    var exactSigningIdentifiers: Set<String> = []
    var requiredPathComponents: [[String]] = []

    func matches(process: ProcessObservation) -> Bool {
      let executable = (process.path.map { URL(fileURLWithPath: $0).lastPathComponent } ?? process.processName).lowercased()
      if exactExecutableNames.contains(executable) {
        return true
      }

      if let signingIdentifier = process.signingIdentifier?.lowercased(), exactSigningIdentifiers.contains(signingIdentifier) {
        return true
      }

      if let bundleName = AIWorkloadDescriptor.bundleName(in: process.path), exactBundleNames.contains(bundleName) {
        return true
      }

      let components = AIWorkloadDescriptor.normalizedComponents(process.path)
      return requiredPathComponents.contains { required in
        required.allSatisfy(components.contains)
      }
    }
  }

  var id: AIWorkloadID
  var name: String
  var category: AIWorkloadCategory
  var supportLevel: AIWorkloadSupportLevel
  var directRule: MatchRule
  var sharedHostRule: MatchRule?

  static func normalizedComponents(_ path: String?) -> Set<String> {
    guard let path else { return [] }
    return Set(path.split(separator: "/", omittingEmptySubsequences: true).map { $0.lowercased() })
  }

  static func bundleName(in path: String?) -> String? {
    guard let path else { return nil }
    return path.split(separator: "/", omittingEmptySubsequences: true)
      .first(where: { $0.lowercased().hasSuffix(".app") })?
      .lowercased()
  }
}

struct AIProcessAttribution: Identifiable, Sendable {
  var id: Int32 { process.pid }
  var process: ProcessObservation
  var workloadID: AIWorkloadID
  var kind: AIAttributionKind
  var role: AIProcessRole
  var surface: AIWorkloadSurface
  var confidence: EvidenceConfidence
}

struct AIWorkloadObservation: Identifiable, Sendable {
  var id: AIWorkloadID
  var name: String
  var category: AIWorkloadCategory
  var supportLevel: AIWorkloadSupportLevel
  var activity: AIWorkloadActivity
  var directCPUPercent: Double
  var relatedCPUPercent: Double
  var sharedHostCPUPercent: Double
  var directResidentMemoryBytes: UInt64
  var directPhysicalFootprintBytes: UInt64?
  var relatedResidentMemoryBytes: UInt64
  var relatedPhysicalFootprintBytes: UInt64?
  var sharedHostResidentMemoryBytes: UInt64
  var sharedHostPhysicalFootprintBytes: UInt64?
  var attributions: [AIProcessAttribution]
  var lastUpdated: Date

  var directObservedMemoryBytes: UInt64 {
    max(directPhysicalFootprintBytes ?? 0, directResidentMemoryBytes)
  }

  var relatedObservedMemoryBytes: UInt64 {
    max(relatedPhysicalFootprintBytes ?? 0, relatedResidentMemoryBytes)
  }

  var sharedHostObservedMemoryBytes: UInt64 {
    max(sharedHostPhysicalFootprintBytes ?? 0, sharedHostResidentMemoryBytes)
  }

  var totalCPUPercent: Double { directCPUPercent + relatedCPUPercent }
  var processCount: Int { attributions.filter { $0.kind != .sharedHost }.count }
}

struct AIWorkloadSessionPoint: Equatable, Sendable {
  var timestamp: Date
  var workloadID: AIWorkloadID
  var directCPUPercent: Double
  var relatedCPUPercent: Double
  var directMemoryBytes: UInt64
  var relatedMemoryBytes: UInt64
  var processCount: Int
}

struct AIWorkloadSessionSummary: Identifiable, Equatable, Sendable {
  var id: AIWorkloadID { workloadID }
  var workloadID: AIWorkloadID
  var name: String
  var sampleCount: Int
  var firstObservedAt: Date
  var lastObservedAt: Date
  var averageCPUPercent: Double
  var maximumCPUPercent: Double
  var initialMemoryBytes: UInt64
  var finalMemoryBytes: UInt64
  var peakMemoryBytes: UInt64
  var peakRelatedMemoryBytes: UInt64
  var maximumProcessCount: Int
  var activity: AIWorkloadActivity
}
