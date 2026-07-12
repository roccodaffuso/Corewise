import Foundation

enum FocusedCheckResolver {
  static func resolve(_ summary: FocusedCheckAggregateSummary) -> FocusedCheckResult {
    let resolved = switch summary.intent {
    case .slow:
      resolveSlow(summary)
    case .hot:
      resolveHot(summary)
    case .batteryDrain:
      resolveBattery(summary)
    case .storageFull:
      resolveStorage(summary)
    case .general:
      unavailable(
        summary,
        headline: corewiseText("Current signals are not available for this check.", comment: "Focused Check headline"),
        detail: corewiseText("Just checking uses the current Overview summary rather than a timed observation.", comment: "Focused Check detail"),
        action: FocusedCheckAction(title: corewiseText("Review Overview", comment: "Focused Check action"), detail: corewiseText("Return to Overview to inspect the current supported signals.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview))
      )
    case .aiWorkloads:
      resolveAIWorkloads(summary)
    }
    return applyingMissingIntervalConfidence(resolved, summary: summary)
  }

  static func resolveGeneral(attention: AttentionSummary, now: Date) -> FocusedCheckResult {
    let state: FocusedCheckResultState
    switch attention.state {
    case .clear: state = .clear
    case .review: state = .review
    case .critical: state = .critical
    case .unavailable: state = .unavailable
    }

    let evidence = attention.signals.prefix(3).map { signal in
      FocusedCheckEvidence(
        id: signal.role.rawValue,
        kind: evidenceKind(for: signal.role),
        area: signal.area,
        title: signal.title,
        value: [signal.value, signal.unit].filter { !$0.isEmpty }.joined(separator: " "),
        detail: corewiseText("This is a current live signal from Corewise's normal snapshot.", comment: "Focused Check evidence detail"),
        severity: signal.status,
        confidence: .high,
        source: signal.source,
        firstObservedAt: signal.lastUpdated,
        lastObservedAt: signal.lastUpdated,
        sampleCount: 1,
        destination: DashboardRoute(section: section(for: signal.area))
      )
    }

    return FocusedCheckResult(
      intent: .general,
      state: state,
      headline: attention.headline,
      detail: attention.detail,
      evidence: evidence,
      primaryAction: FocusedCheckAction(
        title: evidence.isEmpty ? corewiseText("Refresh signals", comment: "Focused Check action") : corewiseText("Review the leading signal", comment: "Focused Check action"),
        detail: attention.recommendedAction.isEmpty ? corewiseText("Refresh Corewise to try the live checks again.", comment: "Focused Check action detail") : attention.recommendedAction,
        destination: evidence.first?.destination
      ),
      observationStartedAt: now,
      observationEndedAt: now,
      coverage: corewiseText("This result uses the current supported live snapshot. Data coverage remains separate from the conclusion.", comment: "Focused Check coverage"),
      generatedAt: now
    )
  }

  private static func resolveSlow(_ summary: FocusedCheckAggregateSummary) -> FocusedCheckResult {
    guard !summary.cpuValues.isEmpty || !summary.memoryValues.isEmpty else {
      return unavailable(summary, headline: corewiseText("Live performance signals are unavailable.", comment: "Focused Check headline"), detail: corewiseText("Corewise did not receive supported CPU or memory readings during this check.", comment: "Focused Check detail"), action: refreshAction)
    }
    guard summary.systemSampleCount >= 5, summary.elapsed >= summary.intent.minimumDuration else {
      return insufficient(summary, required: corewiseText("Keep the check running for at least 15 seconds and five live samples.", comment: "Focused Check minimum evidence guidance"))
    }

    var candidates: [RankedEvidence] = []
    if let group = summary.appGroups.first(where: \.hasSustainedCPU) {
      candidates.append(activityEvidence(group, kind: .appGroupActivity, priority: 100, destination: DashboardRoute(section: .performance, performanceMode: .cpu, focus: .appGroup(id: group.id, mode: .cpu))))
    } else if let process = summary.processes.first(where: \.hasSustainedCPU) {
      let pid = process.memberPIDs.first ?? Int32(process.id) ?? 0
      candidates.append(activityEvidence(process, kind: .processActivity, priority: 95, destination: DashboardRoute(section: .performance, performanceMode: .cpu, focus: .process(pid: pid, mode: .cpu))))
    }
    if summary.hasRisingSwap, let first = summary.systemPoints.first, let last = summary.systemPoints.last {
      candidates.append(
        RankedEvidence(
          evidence: FocusedCheckEvidence(
            kind: .swapGrowth,
            area: .performance,
            title: corewiseText("Swap increased during the check", comment: "Focused Check evidence title"),
            value: swapChange(first: first.swapUsedBytes, last: last.swapUsedBytes),
            detail: corewiseText("Rising swap was observed in the same window. Public macOS data does not expose exact per-process swap ownership.", comment: "Focused Check evidence detail"),
            severity: .warning,
            confidence: .medium,
            source: corewiseText("Local in-memory swap history", comment: "Focused Check evidence source"),
            firstObservedAt: first.timestamp,
            lastObservedAt: last.timestamp,
            sampleCount: summary.systemSampleCount,
            destination: DashboardRoute(section: .performance, performanceMode: .memory)
          ),
          priority: 90
        )
      )
    }
    if let maximumMemory = summary.maximumMemoryUsedPercent, maximumMemory >= 85 {
      candidates.append(
        RankedEvidence(
          evidence: FocusedCheckEvidence(
            kind: .memoryLoad,
            area: .performance,
            title: corewiseText("Memory use stayed worth reviewing", comment: "Focused Check evidence title"),
            value: percent(maximumMemory),
            detail: summary.hasRisingSwap ? corewiseText("Elevated memory use coincided with rising swap.", comment: "Focused Check evidence detail") : corewiseText("Elevated memory use was observed; swap did not show a rising signal in this window.", comment: "Focused Check evidence detail"),
            severity: maximumMemory >= 95 ? .critical : .warning,
            confidence: .medium,
            source: corewiseText("Public VM statistics", comment: "Focused Check evidence source"),
            firstObservedAt: summary.systemPoints.first?.timestamp ?? summary.startedAt,
            lastObservedAt: summary.systemPoints.last?.timestamp ?? summary.endedAt,
            sampleCount: summary.memoryValues.count,
            destination: DashboardRoute(section: .performance, performanceMode: .memory)
          ),
          priority: 80
        )
      )
    }
    if summary.highestThermalLevel >= .serious {
      candidates.append(thermalEvidence(summary, priority: 70))
    }
    if let averageCPU = summary.averageCPUPercent, averageCPU >= 70 {
      candidates.append(
        RankedEvidence(
          evidence: FocusedCheckEvidence(
            kind: .elevatedSystemCPU,
            area: .performance,
            title: corewiseText("System CPU stayed elevated", comment: "Focused Check evidence title"),
            value: corewiseFormat("%@ average", percent(averageCPU)),
            detail: corewiseText("Elevated system CPU was observed during this check; this alone does not identify a cause.", comment: "Focused Check evidence detail"),
            severity: averageCPU >= 90 ? .critical : .warning,
            confidence: .high,
            source: corewiseText("Live CPU tick samples", comment: "Focused Check evidence source"),
            firstObservedAt: summary.systemPoints.first?.timestamp ?? summary.startedAt,
            lastObservedAt: summary.systemPoints.last?.timestamp ?? summary.endedAt,
            sampleCount: summary.cpuValues.count,
            destination: DashboardRoute(section: .performance, performanceMode: .cpu)
          ),
          priority: 60
        )
      )
    }

    let evidence = ranked(candidates)
    guard !evidence.isEmpty else {
      return result(
        summary,
        state: .clear,
        headline: corewiseText("No persistent live signal appeared during this check.", comment: "Focused Check headline"),
        detail: corewiseText("The slowdown may have been intermittent or may not have occurred in this observation window.", comment: "Focused Check detail"),
        evidence: [],
        action: FocusedCheckAction(title: corewiseText("Repeat while it feels slow", comment: "Focused Check action"), detail: corewiseText("Run the check again while the symptom is visible.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview)),
        coverage: coverage(summary)
      )
    }
    return evidenceResult(summary, headline: corewiseText("Persistent activity is worth reviewing.", comment: "Focused Check headline"), evidence: evidence)
  }

  private static func resolveAIWorkloads(_ summary: FocusedCheckAggregateSummary) -> FocusedCheckResult {
    guard summary.elapsed >= summary.intent.minimumDuration, summary.systemSampleCount >= 5 else {
      return insufficient(summary, required: corewiseText("Keep observing for at least one minute and five live samples.", comment: "AI Focused Check minimum guidance"))
    }
    guard !summary.aiWorkloads.isEmpty else {
      return unavailable(
        summary,
        headline: corewiseText("No supported local AI workload was observed.", comment: "AI Focused Check headline"),
        detail: corewiseText("Cloud agents and unsupported local tools remain outside this observation.", comment: "AI Focused Check detail"),
        action: FocusedCheckAction(title: corewiseText("Open AI Workloads", comment: "AI Focused Check action"), detail: corewiseText("Review supported tools and attribution limits in Performance.", comment: "AI Focused Check action detail"), destination: DashboardRoute(section: .performance, performanceMode: .aiWorkloads))
      )
    }

    let evidence = summary.aiWorkloads.prefix(3).map { workload in
      FocusedCheckEvidence(
        id: "ai:\(workload.workloadID.rawValue)",
        kind: .aiWorkloadActivity,
        area: .performance,
        title: corewiseFormat("%@ local activity", workload.name),
        value: corewiseBytes(workload.peakMemoryBytes),
        detail: corewiseFormat("Peak observed memory with up to %@ CPU and %@ related-process peak memory. This is local process attribution, not an agent count.", percent(workload.maximumCPUPercent), corewiseBytes(workload.peakRelatedMemoryBytes)),
        severity: workload.maximumCPUPercent >= 200 ? .warning : .info,
        confidence: .medium,
        source: corewiseText("Local volatile AI workload history", comment: "AI Focused Check source"),
        firstObservedAt: workload.firstObservedAt,
        lastObservedAt: workload.lastObservedAt,
        sampleCount: workload.sampleCount,
        destination: DashboardRoute(section: .performance, performanceMode: .aiWorkloads)
      )
    }

    var resolved = result(
      summary,
      state: evidence.contains { $0.severity == .warning } ? .review : .clear,
      headline: corewiseFormat("%@ supported local AI workloads were observed.", String(summary.aiWorkloads.count)),
      detail: summary.highestThermalLevel >= .serious && summary.aiWorkloads.contains { $0.activity == .sustained }
        ? corewiseText("Sustained AI-related activity coincided with elevated thermal state; this does not establish cause.", comment: "AI Focused Check detail")
        : corewiseText("App footprint and attributable local work are separated. Cloud activity is not included.", comment: "AI Focused Check detail"),
      evidence: evidence,
      action: FocusedCheckAction(title: corewiseText("Review AI Workloads", comment: "AI Focused Check action"), detail: corewiseText("Compare app footprint with related local work in Performance.", comment: "AI Focused Check action detail"), destination: DashboardRoute(section: .performance, performanceMode: .aiWorkloads)),
      coverage: coverage(summary)
    )
    resolved.aiWorkloads = summary.aiWorkloads
    return resolved
  }

  private static func resolveHot(_ summary: FocusedCheckAggregateSummary) -> FocusedCheckResult {
    guard summary.systemPoints.contains(where: { $0.thermalLevel != .unavailable }) else {
      return unavailable(summary, headline: corewiseText("Live thermal pressure is unavailable.", comment: "Focused Check headline"), detail: corewiseText("Corewise cannot infer physical temperature from CPU activity alone.", comment: "Focused Check detail"), action: refreshAction)
    }
    guard summary.systemSampleCount >= 5, summary.elapsed >= summary.intent.minimumDuration else {
      return insufficient(summary, required: corewiseText("Keep the check running for at least 15 seconds and five live samples.", comment: "Focused Check minimum evidence guidance"))
    }

    guard summary.highestThermalLevel > .nominal else {
      return result(
        summary,
        state: .clear,
        headline: corewiseText("macOS reported nominal thermal pressure during this check.", comment: "Focused Check headline"),
        detail: corewiseText("Corewise does not infer physical temperature from CPU activity when the supported thermal state is nominal.", comment: "Focused Check detail"),
        evidence: [],
        action: FocusedCheckAction(title: corewiseText("Repeat while the Mac feels hot", comment: "Focused Check action"), detail: corewiseText("Run the check again while the symptom is visible.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview)),
        coverage: coverage(summary)
      )
    }

    var candidates = [thermalEvidence(summary, priority: 100)]
    if let group = summary.appGroups.first(where: \.hasSustainedCPU) {
      candidates.append(activityEvidence(group, kind: .appGroupActivity, priority: 80, destination: DashboardRoute(section: .performance, performanceMode: .cpu, focus: .appGroup(id: group.id, mode: .cpu))))
    } else if let averageCPU = summary.averageCPUPercent, averageCPU >= 70 {
      candidates.append(
        RankedEvidence(
          evidence: FocusedCheckEvidence(
            kind: .elevatedSystemCPU,
            area: .performance,
            title: corewiseText("CPU activity coincided with thermal pressure", comment: "Focused Check evidence title"),
            value: corewiseFormat("%@ average", percent(averageCPU)),
            detail: corewiseText("Sustained CPU activity was observed in the same window. This is coincidence, not proof of cause.", comment: "Focused Check evidence detail"),
            severity: .warning,
            confidence: .medium,
            source: corewiseText("Live CPU tick samples", comment: "Focused Check evidence source"),
            firstObservedAt: summary.systemPoints.first?.timestamp ?? summary.startedAt,
            lastObservedAt: summary.systemPoints.last?.timestamp ?? summary.endedAt,
            sampleCount: summary.cpuValues.count,
            destination: DashboardRoute(section: .performance, performanceMode: .cpu)
          ),
          priority: 70
        )
      )
    }
    let evidence = ranked(candidates)
    let headline = evidence.count > 1
      ? corewiseText("Elevated thermal pressure coincided with sustained CPU activity.", comment: "Focused Check headline")
      : corewiseText("Elevated thermal pressure was observed.", comment: "Focused Check headline")
    return evidenceResult(summary, headline: headline, evidence: evidence)
  }

  private static func resolveBattery(_ summary: FocusedCheckAggregateSummary) -> FocusedCheckResult {
    guard let firstReading = summary.batteryReadings.first else {
      return unavailable(summary, headline: corewiseText("An internal battery reading is unavailable.", comment: "Focused Check headline"), detail: corewiseText("Corewise did not receive a supported internal battery reading for this check.", comment: "Focused Check detail"), action: refreshAction)
    }
    guard firstReading.powerSource == .battery else {
      return unavailable(
        summary,
        headline: corewiseText("Run this check while using battery power.", comment: "Focused Check headline"),
        detail: corewiseText("A battery-drain observation cannot be interpreted while the Mac is connected to AC or another external power source.", comment: "Focused Check detail"),
        action: FocusedCheckAction(title: corewiseText("Disconnect power and start again", comment: "Focused Check action"), detail: corewiseText("Start a new battery check after macOS reports Battery Power.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview))
      )
    }
    guard summary.distinctBatterySampleCount >= 5, summary.elapsed >= summary.intent.minimumDuration else {
      return insufficient(summary, required: corewiseText("Keep the Mac on battery for at least five minutes and five distinct battery readings.", comment: "Focused Check minimum evidence guidance"))
    }
    guard let lastReading = summary.batteryReadings.last,
          summary.batteryReadings.allSatisfy({ $0.powerSource == .battery }),
          let firstCharge = firstReading.chargePercent,
          let lastCharge = lastReading.chargePercent else {
      return unavailable(summary, headline: corewiseText("The battery observation was interrupted.", comment: "Focused Check headline"), detail: corewiseText("Power-source or charge readings were not consistently available during this check.", comment: "Focused Check detail"), action: refreshAction)
    }

    let drop = max(firstCharge - lastCharge, 0)
    var candidates: [RankedEvidence] = [
      RankedEvidence(
        evidence: FocusedCheckEvidence(
          kind: .batteryChargeChange,
          area: .battery,
          title: corewiseText("Observed charge change", comment: "Focused Check evidence title"),
          value: drop == 0 ? corewiseText("No whole-percent change", comment: "Focused Check battery value") : "−\(percent(drop))",
          detail: drop == 0 ? corewiseText("No whole-percent charge change appeared in this window; Corewise does not extrapolate a rate from it.", comment: "Focused Check evidence detail") : corewiseText("This is the charge change observed in this window, not an extrapolated hourly rate.", comment: "Focused Check evidence detail"),
          severity: drop >= 10 ? .warning : (drop >= 5 ? .info : .good),
          confidence: .high,
          source: corewiseText("IOKit power source readings", comment: "Focused Check evidence source"),
          firstObservedAt: firstReading.timestamp,
          lastObservedAt: lastReading.timestamp,
          sampleCount: summary.distinctBatterySampleCount,
          destination: DashboardRoute(section: .battery)
        ),
        priority: 100
      )
    ]
    if summary.highestThermalLevel >= .serious {
      candidates.append(thermalEvidence(summary, priority: 70))
    }
    if let group = summary.appGroups.first(where: \.hasSustainedCPU) {
      var activity = activityEvidence(group, kind: .appGroupActivity, priority: 60, destination: DashboardRoute(section: .performance, performanceMode: .cpu, focus: .appGroup(id: group.id, mode: .cpu)))
      activity.evidence.detail = corewiseText("This CPU activity coincided with the battery observation. Corewise does not measure per-app energy impact.", comment: "Focused Check evidence detail")
      candidates.append(activity)
    }
    let evidence = ranked(candidates)
    let state: FocusedCheckResultState = drop >= 10 ? .review : .clear
    let headline = drop >= 10
      ? corewiseText("The observed charge change is worth reviewing.", comment: "Focused Check headline")
      : corewiseText("No strong battery-drain signal appeared in this window.", comment: "Focused Check headline")
    return result(
      summary,
      state: state,
      headline: headline,
      detail: corewiseText("Corewise reports only the actual charge change and coincident supported signals.", comment: "Focused Check detail"),
      evidence: evidence,
      action: state == .review
        ? FocusedCheckAction(title: corewiseText("Review battery context", comment: "Focused Check action"), detail: corewiseText("Compare this result with macOS Battery settings and repeat under the same workload.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .battery))
        : FocusedCheckAction(title: corewiseText("Repeat during the drain", comment: "Focused Check action"), detail: corewiseText("Run another check while the unexpected drain is visible.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview)),
      coverage: corewiseFormat("%@ distinct battery readings over %@. Per-app energy impact is not measured.", String(summary.distinctBatterySampleCount), duration(summary.elapsed))
    )
  }

  private static func resolveStorage(_ summary: FocusedCheckAggregateSummary) -> FocusedCheckResult {
    guard let storage = summary.storage else {
      return unavailable(summary, headline: corewiseText("A completed storage scan is required.", comment: "Focused Check headline"), detail: corewiseText("Corewise will not infer what uses space before a real approved-scope scan completes.", comment: "Focused Check detail"), action: FocusedCheckAction(title: corewiseText("Open Storage", comment: "Focused Check action"), detail: corewiseText("Complete Full Storage Analysis or scan the remembered folder scope.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .storage)))
    }

    var candidates: [RankedEvidence] = []
    let headroomSeverity: FindingSeverity = storage.volumeAvailableGB < 5 ? .critical : (storage.volumeAvailableGB < 20 ? .warning : .good)
    candidates.append(
      RankedEvidence(
        evidence: FocusedCheckEvidence(
          kind: .lowStorageHeadroom,
          area: .storage,
          title: corewiseText("Volume headroom", comment: "Focused Check evidence title"),
          value: corewiseFormat("%@ GB available", decimal(storage.volumeAvailableGB)),
          detail: corewiseText("This is live startup-volume headroom reported by macOS.", comment: "Focused Check evidence detail"),
          severity: headroomSeverity,
          confidence: .high,
          source: corewiseText("URL volume capacity values", comment: "Focused Check evidence source"),
          firstObservedAt: summary.startedAt,
          lastObservedAt: storage.completedAt,
          sampleCount: 1,
          destination: DashboardRoute(section: .storage)
        ),
        priority: 100
      )
    )
    if let title = storage.largestCategoryTitle, let size = storage.largestCategoryGB {
      candidates.append(
        RankedEvidence(
          evidence: FocusedCheckEvidence(
            kind: .storageAttribution,
            area: .storage,
            title: title,
            value: corewiseFormat("%@ GB classified", decimal(size)),
            detail: corewiseText("This was the largest category inside the approved scan scope; Corewise makes no removal recommendation.", comment: "Focused Check evidence detail"),
            severity: .info,
            confidence: .medium,
            source: corewiseText("Read-only approved-scope scan", comment: "Focused Check evidence source"),
            firstObservedAt: storage.completedAt,
            lastObservedAt: storage.completedAt,
            sampleCount: 1,
            destination: DashboardRoute(section: .storage, focus: storage.largestCategory.map(DashboardFocus.storageCategory))
          ),
          priority: 80
        )
      )
    }
    if let folder = storage.largestFolder {
      candidates.append(storageItemEvidence(folder, title: corewiseText("Largest observed folder", comment: "Focused Check evidence title"), priority: 70, completedAt: storage.completedAt))
    }
    if let file = storage.largestFile {
      candidates.append(storageItemEvidence(file, title: corewiseText("Largest observed file", comment: "Focused Check evidence title"), priority: 60, completedAt: storage.completedAt))
    }
    if storage.largestCategoryTitle == nil, storage.largestFolder == nil, storage.largestFile == nil {
      candidates.append(
        RankedEvidence(
          evidence: FocusedCheckEvidence(
            kind: .storageCoverage,
            area: .storage,
            title: corewiseText("Approved scan coverage", comment: "Focused Check evidence title"),
            value: corewiseFormat("%@ GB classified", decimal(storage.classifiedGB)),
            detail: corewiseText("Items outside the approved scope or inaccessible to the scan remain unclassified.", comment: "Focused Check evidence detail"),
            severity: storage.inaccessibleItemCount > 0 ? .info : .good,
            confidence: .high,
            source: corewiseText("Read-only approved-scope scan", comment: "Focused Check evidence source"),
            firstObservedAt: storage.completedAt,
            lastObservedAt: storage.completedAt,
            sampleCount: 1,
            destination: DashboardRoute(section: .storage)
          ),
          priority: 50
        )
      )
    }

    let evidence = ranked(candidates)
    let state: FocusedCheckResultState = headroomSeverity == .critical ? .critical : (headroomSeverity == .warning ? .review : .clear)
    return result(
      summary,
      state: state,
      headline: state == .clear ? corewiseText("Storage headroom is not urgent in the current volume reading.", comment: "Focused Check headline") : corewiseText("Low storage headroom is worth reviewing.", comment: "Focused Check headline"),
      detail: corewiseFormat("The scan shows observed size inside %@; it does not estimate removable space.", storage.scanRootTitle),
      evidence: evidence,
      action: FocusedCheckAction(title: corewiseText("Review the largest observed items", comment: "Focused Check action"), detail: corewiseText("Inspect ownership and usefulness before removing anything.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .storage)),
      coverage: corewiseFormat("%@ GB classified in the approved scope; %@ items were inaccessible. Space outside the scope remains unclassified.", decimal(storage.classifiedGB), String(storage.inaccessibleItemCount))
    )
  }

  private static func evidenceResult(_ summary: FocusedCheckAggregateSummary, headline: String, evidence: [FocusedCheckEvidence]) -> FocusedCheckResult {
    let state: FocusedCheckResultState = evidence.contains { $0.severity == .critical } ? .critical : .review
    return result(
      summary,
      state: state,
      headline: headline,
      detail: corewiseText("These signals were observed in the same window. They indicate what is worth reviewing, not a proven cause.", comment: "Focused Check detail"),
      evidence: evidence,
      action: action(for: evidence[0]),
      coverage: coverage(summary)
    )
  }

  private static func ranked(_ candidates: [RankedEvidence]) -> [FocusedCheckEvidence] {
    let sorted = candidates.sorted(by: RankedEvidence.precedes)
    var families = Set<FocusedCheckEvidenceFamily>()
    var selected: [FocusedCheckEvidence] = []
    for candidate in sorted where selected.count < 3 {
      if families.insert(candidate.evidence.kind.family).inserted {
        selected.append(candidate.evidence)
      }
    }
    if selected.count < 3 {
      var selectedIDs = Set(selected.map(\.id))
      for candidate in sorted where selected.count < 3 {
        if selectedIDs.insert(candidate.evidence.id).inserted {
          selected.append(candidate.evidence)
        }
      }
    }
    return selected
  }

  private static func activityEvidence(_ aggregate: FocusedCheckActivityAggregate, kind: FocusedCheckEvidenceKind, priority: Int, destination: DashboardRoute) -> RankedEvidence {
    RankedEvidence(
      evidence: FocusedCheckEvidence(
        id: "\(kind.rawValue):\(aggregate.id)",
        kind: kind,
        area: .performance,
        title: corewiseFormat("%@ stayed active", aggregate.title),
        value: corewiseFormat("up to %@ CPU", percent(aggregate.maximumCPUPercent)),
        detail: corewiseFormat("Repeated CPU activity was observed across %@ samples. Treat it as coincident activity, not an explanation by itself.", String(aggregate.activeCPUSampleCount)),
        severity: aggregate.maximumCPUPercent >= 200 ? .critical : .warning,
        confidence: .medium,
        source: corewiseText("Local in-memory process history", comment: "Focused Check evidence source"),
        firstObservedAt: aggregate.firstObservedAt,
        lastObservedAt: aggregate.lastObservedAt,
        sampleCount: aggregate.sampleCount,
        destination: destination
      ),
      priority: priority
    )
  }

  private static func thermalEvidence(_ summary: FocusedCheckAggregateSummary, priority: Int) -> RankedEvidence {
    let level = summary.highestThermalLevel
    return RankedEvidence(
      evidence: FocusedCheckEvidence(
        kind: .thermalPressure,
        area: .thermal,
        title: corewiseText("Elevated thermal pressure", comment: "Focused Check evidence title"),
        value: level.title,
        detail: corewiseFormat("macOS reported %@ thermal pressure during this observation window.", level.title.lowercased()),
        severity: level == .critical ? .critical : (level == .serious ? .warning : .info),
        confidence: .high,
        source: corewiseText("ProcessInfo.thermalState", comment: "Focused Check evidence source"),
        firstObservedAt: summary.systemPoints.first?.timestamp ?? summary.startedAt,
        lastObservedAt: summary.systemPoints.last?.timestamp ?? summary.endedAt,
        sampleCount: summary.systemPoints.filter { $0.thermalLevel == level }.count,
        destination: DashboardRoute(section: .thermal)
      ),
      priority: priority
    )
  }

  private static func storageItemEvidence(_ item: StorageItem, title: String, priority: Int, completedAt: Date) -> RankedEvidence {
    RankedEvidence(
      evidence: FocusedCheckEvidence(
        id: "storage:\(item.path)",
        kind: .storageAttribution,
        area: .storage,
        title: title,
        value: corewiseFormat("%@ GB", decimal(item.sizeGB)),
        detail: corewiseFormat("%@ was observed in the approved scope. Review it in context before changing anything.", item.title),
        severity: .info,
        confidence: .medium,
        source: item.source,
        firstObservedAt: completedAt,
        lastObservedAt: completedAt,
        sampleCount: 1,
        destination: DashboardRoute(section: .storage, focus: .storagePath(item.path))
      ),
      priority: priority
    )
  }

  private static func result(
    _ summary: FocusedCheckAggregateSummary,
    state: FocusedCheckResultState,
    headline: String,
    detail: String,
    evidence: [FocusedCheckEvidence],
    action: FocusedCheckAction,
    coverage: String
  ) -> FocusedCheckResult {
    FocusedCheckResult(
      intent: summary.intent,
      state: state,
      headline: headline,
      detail: detail,
      evidence: Array(evidence.prefix(3)),
      primaryAction: action,
      observationStartedAt: summary.startedAt,
      observationEndedAt: summary.endedAt,
      coverage: coverage,
      generatedAt: summary.endedAt
    )
  }

  private static func insufficient(_ summary: FocusedCheckAggregateSummary, required: String) -> FocusedCheckResult {
    result(
      summary,
      state: .insufficientEvidence,
      headline: corewiseText("More observation is needed.", comment: "Focused Check headline"),
      detail: required,
      evidence: [],
      action: FocusedCheckAction(title: corewiseText("Keep observing", comment: "Focused Check action"), detail: corewiseText("Leave the check running while the symptom is visible.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview)),
      coverage: coverage(summary)
    )
  }

  private static func unavailable(_ summary: FocusedCheckAggregateSummary, headline: String, detail: String, action: FocusedCheckAction) -> FocusedCheckResult {
    result(summary, state: .unavailable, headline: headline, detail: detail, evidence: [], action: action, coverage: coverage(summary))
  }

  private static func action(for evidence: FocusedCheckEvidence) -> FocusedCheckAction {
    switch evidence.kind {
    case .sustainedCPU, .elevatedSystemCPU, .appGroupActivity, .processActivity, .aiWorkloadActivity:
      FocusedCheckAction(title: corewiseText("Review sustained activity", comment: "Focused Check action"), detail: corewiseText("Open Performance and check whether the observed work is expected.", comment: "Focused Check action detail"), destination: evidence.destination)
    case .memoryLoad, .swapGrowth:
      FocusedCheckAction(title: corewiseText("Review memory context", comment: "Focused Check action"), detail: corewiseText("Open Memory and compare observed memory with swap trend.", comment: "Focused Check action detail"), destination: evidence.destination)
    case .thermalPressure:
      FocusedCheckAction(title: corewiseText("Reduce sustained work", comment: "Focused Check action"), detail: corewiseText("Pause optional heavy work and see whether macOS thermal pressure returns toward nominal.", comment: "Focused Check action detail"), destination: evidence.destination)
    case .batteryState, .batteryChargeChange:
      FocusedCheckAction(title: corewiseText("Review battery context", comment: "Focused Check action"), detail: corewiseText("Compare this observation with macOS Battery settings.", comment: "Focused Check action detail"), destination: evidence.destination)
    case .lowStorageHeadroom, .storageCoverage, .storageAttribution:
      FocusedCheckAction(title: corewiseText("Review observed storage", comment: "Focused Check action"), detail: corewiseText("Inspect ownership and usefulness before removing anything.", comment: "Focused Check action detail"), destination: evidence.destination)
    case .unavailable:
      refreshAction
    }
  }

  private static let refreshAction = FocusedCheckAction(title: corewiseText("Refresh signals", comment: "Focused Check action"), detail: corewiseText("Refresh Corewise and try the check again.", comment: "Focused Check action detail"), destination: DashboardRoute(section: .overview))

  private static func coverage(_ summary: FocusedCheckAggregateSummary) -> String {
    let gaps = summary.missingSampleCount == 0
      ? ""
      : corewiseFormat(" %@ refresh intervals were missing and confidence was reduced.", String(summary.missingSampleCount))
    return corewiseFormat("%@ supported system samples over %@.%@ History is local, volatile, and discarded when Corewise quits.", String(summary.systemSampleCount), duration(summary.elapsed), gaps)
  }

  private static func applyingMissingIntervalConfidence(
    _ result: FocusedCheckResult,
    summary: FocusedCheckAggregateSummary
  ) -> FocusedCheckResult {
    guard summary.missingSampleCount > 0 else {
      return result
    }
    var result = result
    result.evidence = result.evidence.map { evidence in
      var evidence = evidence
      switch evidence.confidence {
      case .high: evidence.confidence = .medium
      case .medium: evidence.confidence = .low
      case .low: break
      }
      return evidence
    }
    if !result.coverage.contains("refresh intervals were missing") {
      result.coverage += corewiseFormat(" %@ refresh intervals were missing and confidence was reduced.", String(summary.missingSampleCount))
    }
    return result
  }

  private static func evidenceKind(for role: DiagnosticMetricRole) -> FocusedCheckEvidenceKind {
    switch role {
    case .cpuNow, .sustainedCPU: .sustainedCPU
    case .memoryNow: .memoryLoad
    case .swapTrend: .swapGrowth
    case .storageHeadroom: .lowStorageHeadroom
    case .batteryState: .batteryState
    case .thermalState: .thermalPressure
    case .startupLoad, .appIssuePattern: .unavailable
    }
  }

  private static func section(for area: DiagnosticArea) -> DashboardSection {
    switch area {
    case .performance: .performance
    case .storage: .storage
    case .battery: .battery
    case .thermal: .thermal
    case .startup: .startup
    case .appIssues: .issues
    }
  }

  private static func percent(_ value: Double) -> String {
    value.rounded() == value ? "\(Int(value))%" : String(format: "%.1f%%", value)
  }

  private static func decimal(_ value: Double) -> String {
    value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
  }

  private static func duration(_ interval: TimeInterval) -> String {
    let seconds = max(Int(interval.rounded()), 0)
    if seconds >= 60 {
      return "\(seconds / 60)m \(seconds % 60)s"
    }
    return "\(seconds)s"
  }

  private static func swapChange(first: UInt64?, last: UInt64?) -> String {
    guard let first, let last, last >= first else {
      return corewiseText("Rising", comment: "Focused Check swap trend")
    }
    return "+\(decimal(Double(last - first) / SystemMetricsSampler.bytesPerGB)) GB"
  }
}

private struct RankedEvidence {
  var evidence: FocusedCheckEvidence
  var priority: Int

  static func precedes(_ lhs: RankedEvidence, _ rhs: RankedEvidence) -> Bool {
    let lhsSeverity = severityRank(lhs.evidence.severity)
    let rhsSeverity = severityRank(rhs.evidence.severity)
    if lhsSeverity != rhsSeverity {
      return lhsSeverity > rhsSeverity
    }
    if lhs.priority != rhs.priority {
      return lhs.priority > rhs.priority
    }
    if lhs.evidence.confidence != rhs.evidence.confidence {
      return lhs.evidence.confidence > rhs.evidence.confidence
    }
    return lhs.evidence.id < rhs.evidence.id
  }

  private static func severityRank(_ severity: FindingSeverity) -> Int {
    switch severity {
    case .critical: 4
    case .warning: 3
    case .info: 2
    case .good: 1
    }
  }
}
