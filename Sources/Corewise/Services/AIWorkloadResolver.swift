import Foundation

enum AIWorkloadRegistry {
  static let descriptors: [AIWorkloadDescriptor] = [
    AIWorkloadDescriptor(
      id: .codex,
      name: "Codex",
      category: .codingAgent,
      supportLevel: .verified,
      directRule: .init(
        exactExecutableNames: ["codex", "codex-code-mode-host", "skycomputeruseservice"],
        exactBundleNames: ["codex.app", "codex (renderer).app", "codex (service).app"],
        exactSigningIdentifiers: ["com.openai.codex"],
        requiredPathComponents: [["codex framework.framework"]]
      ),
      sharedHostRule: .init(
        exactExecutableNames: ["chatgpt"],
        exactBundleNames: [],
        requiredPathComponents: [["chatgpt.app", "macos"]]
      )
    ),
    AIWorkloadDescriptor(
      id: .claude,
      name: "Claude",
      category: .codingAgent,
      supportLevel: .verified,
      directRule: .init(
        exactExecutableNames: ["claude"],
        exactBundleNames: ["claude.app", "claude helper.app", "claude helper (renderer).app", "claude code url handler.app"],
        exactSigningIdentifiers: ["com.anthropic.claudefordesktop"],
        requiredPathComponents: [["application support", "claude", "claude-code"]]
      )
    ),
    AIWorkloadDescriptor(
      id: .cursor,
      name: "Cursor",
      category: .aiEditor,
      supportLevel: .verified,
      directRule: .init(exactExecutableNames: ["cursor"], exactBundleNames: ["cursor.app", "cursor helper.app", "cursor helper (renderer).app"], exactSigningIdentifiers: ["com.todesktop.230313mzl4w4u92"])
    ),
    AIWorkloadDescriptor(
      id: .ollama,
      name: "Ollama",
      category: .localModelRuntime,
      supportLevel: .verified,
      directRule: .init(exactExecutableNames: ["ollama", "ollama_llama_server"], exactBundleNames: ["ollama.app"], exactSigningIdentifiers: ["com.electron.ollama"])
    ),
    AIWorkloadDescriptor(
      id: .windsurf,
      name: "Windsurf",
      category: .aiEditor,
      supportLevel: .bestEffort,
      directRule: .init(exactExecutableNames: ["windsurf"], exactBundleNames: ["windsurf.app", "windsurf helper.app", "windsurf helper (renderer).app"])
    ),
    AIWorkloadDescriptor(
      id: .lmStudio,
      name: "LM Studio",
      category: .localModelRuntime,
      supportLevel: .bestEffort,
      directRule: .init(exactExecutableNames: ["lm studio", "lms", "llmster"], exactBundleNames: ["lm studio.app"])
    ),
    AIWorkloadDescriptor(
      id: .gemini,
      name: "Gemini CLI",
      category: .cliAgent,
      supportLevel: .bestEffort,
      directRule: .init(exactExecutableNames: ["gemini"])
    ),
    AIWorkloadDescriptor(
      id: .aider,
      name: "Aider",
      category: .cliAgent,
      supportLevel: .bestEffort,
      directRule: .init(exactExecutableNames: ["aider", "aider-chat"])
    )
  ]
}

enum AIWorkloadResolver {
  static func resolve(
    processes: [ProcessObservation],
    descriptors: [AIWorkloadDescriptor] = AIWorkloadRegistry.descriptors
  ) -> [AIWorkloadObservation] {
    guard !processes.isEmpty else { return [] }

    let processByPID = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
    let descriptorByID = Dictionary(uniqueKeysWithValues: descriptors.map { ($0.id, $0) })
    var directByPID: [Int32: AIProcessAttribution] = [:]
    var sharedByPID: [Int32: AIProcessAttribution] = [:]

    for process in processes {
      if let descriptor = descriptors.first(where: { $0.directRule.matches(process: process) }) {
        directByPID[process.pid] = attribution(process: process, descriptor: descriptor, kind: .direct)
      } else if let descriptor = descriptors.first(where: { $0.sharedHostRule?.matches(process: process) == true }) {
        sharedByPID[process.pid] = attribution(process: process, descriptor: descriptor, kind: .sharedHost)
      }
    }

    var attributions = directByPID
    var inheritedOwnerByPID: [Int32: AIProcessAttribution] = [:]
    var resolvedWithoutOwner: Set<Int32> = []
    for process in processes where attributions[process.pid] == nil && sharedByPID[process.pid] == nil {
      guard let owner = nearestDirectAncestor(
        of: process,
        processByPID: processByPID,
        directByPID: directByPID,
        inheritedOwnerByPID: &inheritedOwnerByPID,
        resolvedWithoutOwner: &resolvedWithoutOwner
      ), let descriptor = descriptorByID[owner.workloadID] else {
        continue
      }
      attributions[process.pid] = AIProcessAttribution(
        process: process,
        workloadID: descriptor.id,
        kind: .descendant,
        role: .spawnedTool,
        surface: owner.surface,
        confidence: .medium
      )
    }

    for (pid, attribution) in sharedByPID where attributions[pid] == nil {
      attributions[pid] = attribution
    }

    let orderedAttributions = processes.compactMap { attributions[$0.pid] }
    let grouped = Dictionary(grouping: orderedAttributions, by: \.workloadID)
    return grouped.compactMap { id, rows in
      guard let descriptor = descriptorByID[id] else { return nil }
      return observation(descriptor: descriptor, attributions: rows)
    }
    .sorted {
      if $0.directObservedMemoryBytes != $1.directObservedMemoryBytes {
        return $0.directObservedMemoryBytes > $1.directObservedMemoryBytes
      }
      return $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }
  }

  private static func nearestDirectAncestor(
    of process: ProcessObservation,
    processByPID: [Int32: ProcessObservation],
    directByPID: [Int32: AIProcessAttribution],
    inheritedOwnerByPID: inout [Int32: AIProcessAttribution],
    resolvedWithoutOwner: inout Set<Int32>
  ) -> AIProcessAttribution? {
    var currentPID = process.parentPID
    var visited: Set<Int32> = [process.pid]
    var path: [Int32] = [process.pid]
    while currentPID > 1, visited.insert(currentPID).inserted {
      if let direct = directByPID[currentPID] {
        for pid in path { inheritedOwnerByPID[pid] = direct }
        return direct
      }
      if let inherited = inheritedOwnerByPID[currentPID] {
        for pid in path { inheritedOwnerByPID[pid] = inherited }
        return inherited
      }
      if resolvedWithoutOwner.contains(currentPID) {
        resolvedWithoutOwner.formUnion(path)
        return nil
      }
      guard let parent = processByPID[currentPID] else {
        resolvedWithoutOwner.formUnion(path)
        return nil
      }
      path.append(currentPID)
      currentPID = parent.parentPID
    }
    resolvedWithoutOwner.formUnion(path)
    return nil
  }

  private static func attribution(
    process: ProcessObservation,
    descriptor: AIWorkloadDescriptor,
    kind: AIAttributionKind
  ) -> AIProcessAttribution {
    let role = role(for: process, descriptor: descriptor, kind: kind)
    return AIProcessAttribution(
      process: process,
      workloadID: descriptor.id,
      kind: kind,
      role: role,
      surface: surface(for: process, descriptor: descriptor, kind: kind),
      confidence: kind == .direct && descriptor.supportLevel == .verified && process.signingIdentifier != nil ? .high : .medium
    )
  }

  private static func role(
    for process: ProcessObservation,
    descriptor: AIWorkloadDescriptor,
    kind: AIAttributionKind
  ) -> AIProcessRole {
    if kind == .sharedHost { return .sharedHost }
    if kind == .descendant { return .spawnedTool }
    if descriptor.category == .localModelRuntime { return .localModel }

    let value = "\(process.processName) \(process.path ?? "")".lowercased()
    if value.contains("renderer") { return .renderer }
    if value.contains("service") { return .service }
    if value.contains("code-mode-host") { return .commandHost }
    if value.contains("helper") || value.contains("crashpad") { return .helper }
    if descriptor.category == .cliAgent || !(process.path ?? "").lowercased().contains(".app/") {
      return .agentRuntime
    }
    return .host
  }

  private static func surface(
    for process: ProcessObservation,
    descriptor: AIWorkloadDescriptor,
    kind: AIAttributionKind
  ) -> AIWorkloadSurface {
    if kind == .sharedHost { return .sharedHost }
    if descriptor.category == .localModelRuntime { return .localRuntime }
    let path = (process.path ?? "").lowercased()
    if path.contains(".app/") {
      return descriptor.id == .codex && path.contains("chatgpt.app/") ? .embeddedRuntime : .desktop
    }
    return .cli
  }

  private static func observation(
    descriptor: AIWorkloadDescriptor,
    attributions: [AIProcessAttribution]
  ) -> AIWorkloadObservation {
    let direct = attributions.filter { $0.kind == .direct }
    let related = attributions.filter { $0.kind == .descendant }
    let shared = attributions.filter { $0.kind == .sharedHost }
    let directCPU = direct.reduce(0) { $0 + $1.process.cpuPercent }
    let relatedCPU = related.reduce(0) { $0 + $1.process.cpuPercent }
    let totalCPU = directCPU + relatedCPU
    let activity: AIWorkloadActivity = totalCPU >= 5 ? .active : .quiet

    return AIWorkloadObservation(
      id: descriptor.id,
      name: descriptor.name,
      category: descriptor.category,
      supportLevel: descriptor.supportLevel,
      activity: activity,
      directCPUPercent: directCPU,
      relatedCPUPercent: relatedCPU,
      sharedHostCPUPercent: shared.reduce(0) { $0 + $1.process.cpuPercent },
      directResidentMemoryBytes: direct.reduce(0) { $0 + $1.process.residentMemoryBytes },
      directPhysicalFootprintBytes: summedFootprint(direct),
      relatedResidentMemoryBytes: related.reduce(0) { $0 + $1.process.residentMemoryBytes },
      relatedPhysicalFootprintBytes: summedFootprint(related),
      sharedHostResidentMemoryBytes: shared.reduce(0) { $0 + $1.process.residentMemoryBytes },
      sharedHostPhysicalFootprintBytes: summedFootprint(shared),
      attributions: direct + related + shared,
      lastUpdated: attributions.map(\.process.lastUpdated).max() ?? Date()
    )
  }

  private static func summedFootprint(_ rows: [AIProcessAttribution]) -> UInt64? {
    let values = rows.compactMap(\.process.physicalFootprintBytes)
    return values.isEmpty ? nil : values.reduce(0, +)
  }

}
