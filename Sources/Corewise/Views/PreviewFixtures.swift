// SPDX-License-Identifier: MPL-2.0

import Foundation

@MainActor
enum PreviewFixtures {
  static let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

  static let performance: PerformanceHealth = {
    let cpu = SystemCPUReading(totalPercent: 24, userPercent: 16, systemPercent: 8, idlePercent: 76, nicePercent: 0, dataMode: .live, source: "Preview", confidence: "Live / high", lastUpdated: now)
    let memory = SystemMemoryReading(
      physicalBytes: 16 * 1024 * 1024 * 1024,
      usedBytes: 10 * 1024 * 1024 * 1024,
      freeBytes: 6 * 1024 * 1024 * 1024,
      appMemoryBytes: 6 * 1024 * 1024 * 1024,
      cachedFilesBytes: 2 * 1024 * 1024 * 1024,
      wiredBytes: 1 * 1024 * 1024 * 1024,
      compressedBytes: 1 * 1024 * 1024 * 1024,
      swap: nil,
      dataMode: .live,
      source: "Preview",
      confidence: "Live / high",
      lastUpdated: now
    )
    let swap = SwapInsight(reading: nil, trend: .unavailable, swapInRateBytesPerSecond: nil, swapOutRateBytesPerSecond: nil, contributors: [], explanation: "Swap unavailable in preview.", source: "Preview", confidence: "Unavailable", dataMode: .unavailable, lastUpdated: now)
    let summary = metric(title: "CPU Now", value: "24", unit: "%", role: .cpuNow, status: .good)
    let context = MemoryPressureContext(memory: memory, swapInsight: swap)
    let history = historyPoints()
    let processes: [ProcessObservation] = [
      process(pid: 101, name: "Xcode", cpu: 18, memoryMB: 1_700),
      process(pid: 202, name: "Safari", cpu: 8, memoryMB: 1_100),
      process(pid: 303, name: "WindowServer", cpu: 5, memoryMB: 640)
    ]
    let metrics: [DiagnosticMetric] = [summary]
    let appGroups = AppProcessGroupingResolver.groups(processes: processes, now: now)
    var codex = process(pid: 404, name: "codex", cpu: 22, memoryMB: 940)
    codex.path = "/Applications/ChatGPT.app/Contents/Resources/codex"
    var build = process(pid: 405, name: "swiftc", cpu: 38, memoryMB: 320)
    build.path = "/usr/bin/swiftc"
    build.parentPID = codex.pid
    let aiWorkloads = AIWorkloadResolver.resolve(processes: [codex, build])
    let insights: [ProcessInsight] = []
    let findings: [DiagnosticFinding] = []
    let actions: [SafeAction] = []
    return PerformanceHealth(
      summary: summary,
      cpu: cpu,
      memory: memory,
      swapInsight: swap,
      memoryContext: context,
      history: history,
      metrics: metrics,
      processes: processes,
      appGroups: appGroups,
      aiWorkloads: aiWorkloads,
      insights: insights,
      findings: findings,
      actions: actions,
      sourceNote: "Deterministic preview data."
    )
  }()

  static let storage: StorageHealth = {
    var value = StorageDiagnosticsCollector().currentStorage(now: now)
    value.summary.role = .storageHeadroom
    return value
  }()

  static let storageScanResult: StorageScanResult = {
    let item = StorageItem(
      title: "Projects",
      path: "~/Projects",
      sizeGB: 42,
      dataMode: .live,
      status: .info,
      severityScore: 30,
      explanation: "Deterministic preview folder.",
      source: "Preview Folder Scope",
      confidence: "Live / medium",
      recommendedAction: "Review the owning project before changing anything.",
      lastUpdated: now
    )
    let category = StorageCategorySummary(
      category: .development,
      title: "Development",
      sizeGB: 42,
      fileCount: 24_000,
      folderCount: 1_800,
      largestExamples: [item],
      dataMode: .live,
      status: .info,
      source: "Preview Folder Scope",
      confidence: "Live / medium"
    )
    return StorageScanResult(
      rootTitle: "Projects",
      rootPath: "~/Projects",
      totalSizeGB: 42,
      scannedItemCount: 24_000,
      scannedFileCount: 24_000,
      scannedFolderCount: 1_800,
      inaccessibleItemCount: 3,
      scanDuration: 38,
      largestItems: [item],
      largestFiles: [],
      largestFolders: [item],
      categoryBreakdown: [category],
      chartData: [ChartDatum(title: "Development", value: 42, unit: "GB", dataMode: .live, status: .info, detail: "Preview")],
      lastUpdated: now
    )
  }()

  static let storageScanSession = StorageScanSession(
    rootURL: URL(fileURLWithPath: "/Users/preview/Projects"),
    currentURL: URL(fileURLWithPath: "/Users/preview/Projects"),
    breadcrumbs: [StorageBreadcrumb(title: "Projects", url: URL(fileURLWithPath: "/Users/preview/Projects"))],
    result: storageScanResult
  )

  static let battery = BatteryDiagnosticsCollector(powerSources: { [] }, registrySnapshot: { nil }).currentBattery(now: now)
  static let startup = StartupDiagnosticsCollector(locations: []).currentStartup(now: now)
  static let appIssues = CrashReportDiagnosticsCollector().unavailableAppIssues(now: now)
  static let thermal: ThermalHealth = {
    let summary = metric(title: "Thermal State", value: "Nominal", unit: "", role: .thermalState, status: .good)
    return ThermalHealth(summary: summary, metrics: [summary], contributors: ThermalContributorResolver.contributors(stateLabel: "Nominal", status: .good, severityScore: 0, hasSustainedCPU: false), actions: [], sourceNote: "ProcessInfo thermal state preview.")
  }()

  static let snapshot: HealthSnapshot = {
    let signals = [performance.summary, storage.summary, thermal.summary]
    return HealthSnapshot(
      generatedAt: now,
      attentionSummary: AttentionSummaryResolver.resolve(metrics: signals),
      coverageSummary: DataCoverageSummary(modes: [.live, .live, .live, .planned]),
      overviewMetrics: signals,
      dataAccess: [DataAccessCapability(title: "CPU, RAM, and processes", dataMode: .live, source: "Mach and libproc", reason: "Read locally for preview.", actionLabel: nil)],
      battery: battery,
      storage: storage,
      performance: performance,
      startup: startup,
      thermal: thermal,
      appIssues: appIssues,
      suggestions: []
    )
  }()

  static let focusedSession: FocusedCheckSession = {
    var session = FocusedCheckSession(intent: .slow, now: now.addingTimeInterval(-28))
    session.phase = .readyToFinish
    session.systemSampleCount = 12
    session.provisionalEvidence = [focusedEvidence]
    session.lastUpdatedAt = now
    session.activityGroups = [
      FocusedCheckActivitySummary(
        id: performance.appGroups.first?.id ?? "preview|app|xcode",
        title: "Xcode",
        firstObservedAt: now.addingTimeInterval(-28),
        lastObservedAt: now,
        sampleCount: 12,
        activeCPUSampleCount: 8,
        maximumCPUPercent: 84,
        peakMemoryBytes: 1_700 * 1024 * 1024,
        memberPIDs: [101]
      )
    ]
    return session
  }()

  static let focusedResult = FocusedCheckResult(
    intent: .slow,
    state: .review,
    headline: "Persistent activity is worth reviewing.",
    detail: "These signals were observed in the same window. They indicate what is worth reviewing, not a proven cause.",
    evidence: [focusedEvidence],
    primaryAction: FocusedCheckAction(
      title: "Review sustained activity",
      detail: "Open Performance and check whether the observed work is expected.",
      destination: DashboardRoute(section: .performance, performanceMode: .cpu)
    ),
    observationStartedAt: now.addingTimeInterval(-60),
    observationEndedAt: now,
    coverage: "20 supported system samples over 60 seconds. History is local and volatile.",
    generatedAt: now
  )

  static let focusedInsufficientResult = makeFocusedResult(
    intent: .slow,
    state: .insufficientEvidence,
    headline: "More observation is needed.",
    detail: "Keep the check running for at least 15 seconds and five live samples.",
    evidenceCount: 0
  )

  static let focusedClearResult = makeFocusedResult(
    intent: .slow,
    state: .clear,
    headline: "No persistent live signal appeared during this check.",
    detail: "The slowdown may have been intermittent or outside this observation window.",
    evidenceCount: 0
  )

  static let focusedHotNominalResult = makeFocusedResult(
    intent: .hot,
    state: .clear,
    headline: "macOS reported nominal thermal pressure during this check.",
    detail: "Corewise does not infer physical temperature from CPU activity.",
    evidenceCount: 0
  )

  static let focusedHotElevatedResult = makeFocusedResult(
    intent: .hot,
    state: .review,
    headline: "Elevated thermal pressure coincided with sustained CPU activity.",
    detail: "The signals appeared in the same window without establishing a cause.",
    evidenceCount: 2
  )

  static let focusedBatteryACResult = makeFocusedResult(
    intent: .batteryDrain,
    state: .unavailable,
    headline: "Run this check while using battery power.",
    detail: "A drain observation cannot be interpreted while the Mac is connected to external power.",
    evidenceCount: 0
  )

  static let focusedBatteryResult = makeFocusedResult(
    intent: .batteryDrain,
    state: .review,
    headline: "The observed charge change is worth reviewing.",
    detail: "Corewise reports the actual charge change and coincident supported signals.",
    evidenceCount: 2
  )

  static let focusedThreeEvidenceResult = makeFocusedResult(
    intent: .slow,
    state: .critical,
    headline: "Several persistent signals are worth reviewing.",
    detail: "Three independent evidence families were observed during the same local check.",
    evidenceCount: 3
  )

  static let focusedLongCopyResult = makeFocusedResult(
    intent: .slow,
    state: .review,
    headline: "Persistent application activity remained visible throughout the complete observation window and deserves a closer review.",
    detail: "This deliberately long deterministic sentence verifies that the result surface remains readable when localized copy expands significantly.",
    evidenceCount: 3
  )

  static func makeFocusedSession(
    intent: FocusedCheckIntent,
    phase: FocusedCheckPhase,
    elapsed: TimeInterval,
    systemSamples: Int = 0,
    batterySamples: Int = 0
  ) -> FocusedCheckSession {
    var session = FocusedCheckSession(intent: intent, now: now.addingTimeInterval(-elapsed))
    session.phase = phase
    session.lastUpdatedAt = now
    session.systemSampleCount = systemSamples
    session.distinctBatterySampleCount = batterySamples
    session.provisionalEvidence = phase == .observing || phase == .readyToFinish ? [focusedEvidence] : []
    session.activityGroups = focusedSession.activityGroups
    return session
  }

  static func makeFocusedResult(
    intent: FocusedCheckIntent,
    state: FocusedCheckResultState,
    headline: String,
    detail: String,
    evidenceCount: Int
  ) -> FocusedCheckResult {
    let evidence = Array(focusedEvidenceSet.prefix(max(min(evidenceCount, 3), 0)))
    return FocusedCheckResult(
      intent: intent,
      state: state,
      headline: headline,
      detail: detail,
      evidence: evidence,
      primaryAction: FocusedCheckAction(
        title: evidence.isEmpty ? "Repeat the check" : "Open the leading evidence",
        detail: evidence.isEmpty ? "Try again while the symptom is visible." : "Review the strongest observed signal in context.",
        destination: evidence.first?.destination ?? DashboardRoute(section: .overview)
      ),
      observationStartedAt: now.addingTimeInterval(-60),
      observationEndedAt: now,
      coverage: "20 supported system samples over 60 seconds. History is local, volatile, and discarded when Corewise quits.",
      generatedAt: now
    )
  }

  private static let focusedEvidence = FocusedCheckEvidence(
    kind: .appGroupActivity,
    area: .performance,
    title: "Xcode stayed active",
    value: "up to 84% CPU",
    detail: "Repeated CPU activity was observed across recent samples. This does not prove it produced the symptom.",
    severity: .warning,
    confidence: .medium,
    source: "Preview local history",
    firstObservedAt: now.addingTimeInterval(-50),
    lastObservedAt: now,
    sampleCount: 12,
    destination: DashboardRoute(section: .performance, performanceMode: .cpu)
  )

  private static let focusedEvidenceSet: [FocusedCheckEvidence] = [
    focusedEvidence,
    FocusedCheckEvidence(
      kind: .swapGrowth,
      area: .performance,
      title: "Swap increased during the check",
      value: "+1.2 GB",
      detail: "Rising swap was observed in the same window without assigning ownership to a process.",
      severity: .warning,
      confidence: .medium,
      source: "Preview local swap history",
      firstObservedAt: now.addingTimeInterval(-45),
      lastObservedAt: now,
      sampleCount: 10,
      destination: DashboardRoute(section: .performance, performanceMode: .memory)
    ),
    FocusedCheckEvidence(
      kind: .thermalPressure,
      area: .thermal,
      title: "Elevated thermal pressure",
      value: "Serious",
      detail: "macOS reported elevated thermal pressure during this deterministic observation.",
      severity: .critical,
      confidence: .high,
      source: "Preview ProcessInfo thermal state",
      firstObservedAt: now.addingTimeInterval(-30),
      lastObservedAt: now,
      sampleCount: 8,
      destination: DashboardRoute(section: .thermal)
    )
  ]

  static let store = HealthDashboardStore(collector: PreviewHealthCollector(snapshot: snapshot))

  private static func metric(title: String, value: String, unit: String, role: DiagnosticMetricRole, status: FindingSeverity) -> DiagnosticMetric {
    DiagnosticMetric(title: title, value: value, unit: unit, role: role, dataMode: .live, status: status, severityScore: status == .good ? 8 : 60, explanation: "Deterministic preview signal.", source: "Preview fixture", confidence: "Live / high", recommendedAction: "No action needed right now.", lastUpdated: now)
  }

  private static func process(pid: Int32, name: String, cpu: Double, memoryMB: UInt64) -> ProcessObservation {
    ProcessObservation(pid: pid, processName: name, displayName: name, appName: name, path: "/Applications/\(name).app", user: "rocco", cpuPercent: cpu, cpuTimeSeconds: cpu * 10, threadCount: 12, residentMemoryBytes: memoryMB * 1024 * 1024, physicalFootprintBytes: memoryMB * 1024 * 1024, pageIns: 0, dataMode: .live, status: .info, severityScore: Int(cpu), explanation: "Preview process row.", source: "Preview fixture", confidence: "Live / high", recommendedAction: "Review expected work before quitting anything.", lastUpdated: now)
  }

  private static func historyPoints() -> [PerformanceTimePoint] {
    var result: [PerformanceTimePoint] = []
    for offset in 0..<30 {
      let seconds = Double(offset - 30) * 2
      let cpu = Double(18 + offset % 12)
      let memory = Double(58 + offset % 8)
      result.append(
        PerformanceTimePoint(
          timestamp: now.addingTimeInterval(seconds),
          cpuPercent: cpu,
          memoryUsedPercent: memory,
          swapUsedBytes: nil
        )
      )
    }
    return result
  }
}

private struct PreviewHealthCollector: SystemHealthCollecting {
  var snapshot: HealthSnapshot

  func currentSnapshot() async throws -> HealthSnapshot {
    snapshot
  }
}
