// SPDX-License-Identifier: MPL-2.0

import Foundation
import Testing
@testable import Corewise

@Suite("Focused Check tracker")
struct FocusedCheckTrackerTests {
  @Test func samplesBeforeStartAreIgnoredAndStartIsClean() {
    let tracker = FocusedCheckTracker()
    let start = Date()
    tracker.ingest(FocusedCheckSample(timestamp: start, cpuPercent: 80))
    #expect(tracker.summary(now: start) == nil)

    tracker.start(intent: .slow, now: start)
    tracker.ingest(FocusedCheckSample(timestamp: start, cpuPercent: 40, memoryUsedPercent: 60))
    let summary = tracker.summary(now: start)

    #expect(summary?.intent == .slow)
    #expect(summary?.systemSampleCount == 1)
  }

  @Test func systemHistoryIsBoundedAndChronological() throws {
    let tracker = FocusedCheckTracker()
    let start = Date()
    tracker.start(intent: .slow, now: start)

    for offset in (0...320).reversed() {
      tracker.ingest(FocusedCheckSample(timestamp: start.addingTimeInterval(Double(offset)), cpuPercent: Double(offset)))
    }

    let points = try #require(tracker.summary(now: start.addingTimeInterval(400))?.systemPoints)
    #expect(points.count == FocusedCheckTracker.maximumSystemPointCount)
    #expect(points == points.sorted { $0.timestamp < $1.timestamp })
  }

  @Test func batteryReadingsDeduplicateBySourceTimestamp() throws {
    let tracker = FocusedCheckTracker()
    let start = Date()
    tracker.start(intent: .batteryDrain, now: start)
    let reading = BatteryLiveReading(chargePercent: 80, powerSource: .battery, isCharging: false, timestamp: start)

    tracker.ingest(FocusedCheckSample(timestamp: start, batteryReading: reading))
    tracker.ingest(FocusedCheckSample(timestamp: start.addingTimeInterval(2), batteryReading: reading))

    #expect(try #require(tracker.summary(now: start.addingTimeInterval(2))).distinctBatterySampleCount == 1)
  }

  @Test func activityAccumulatorsAreBoundedAndRetainStrongest() throws {
    let tracker = FocusedCheckTracker()
    let start = Date()
    tracker.start(intent: .slow, now: start)

    let processes = (0..<60).map { index in
      process(pid: Int32(index + 1), name: "Process \(index)", cpu: Double(index))
    }
    tracker.ingest(FocusedCheckSample(timestamp: start, cpuPercent: 50, processes: processes))

    let retained = try #require(tracker.summary(now: start)?.processes)
    #expect(retained.count == FocusedCheckTracker.maximumActivityCount)
    #expect(retained.contains { $0.title == "Process 59" })
    #expect(retained.contains { $0.title == "Process 0" } == false)
  }

  @Test func topAppGroupSummariesExposeOnlyThreeRankedAggregates() throws {
    let start = Date()
    let groups = (0..<5).map { index in
      activity(
        id: "group-\(index)",
        title: "Group \(index)",
        activeSamples: index + 1,
        maximumCPU: Double(index * 20),
        start: start
      )
    }
    let summary = FocusedCheckAggregateSummary(
      intent: .slow,
      startedAt: start,
      endedAt: start.addingTimeInterval(20),
      appGroups: groups.sorted { $0.maximumCPUPercent > $1.maximumCPUPercent }
    )

    #expect(summary.topAppGroupSummaries.count == 3)
    #expect(summary.topAppGroupSummaries.map(\.id) == ["group-4", "group-3", "group-2"])
    #expect(summary.topAppGroupSummaries[0].sampleCount == 5)
  }

  @Test func resetDiscardsPartialAggregates() {
    let tracker = FocusedCheckTracker()
    let start = Date()
    tracker.start(intent: .hot, now: start)
    tracker.ingest(FocusedCheckSample(timestamp: start, thermalLevel: .serious))
    tracker.reset()

    #expect(tracker.summary(now: start) == nil)
  }

  @Test func missingRefreshIntervalsAreCountedWithoutErasingSamples() throws {
    let tracker = FocusedCheckTracker()
    let start = Date()
    tracker.start(intent: .slow, now: start)
    tracker.ingest(FocusedCheckSample(timestamp: start, cpuPercent: 40))
    tracker.recordMissingInterval(at: start.addingTimeInterval(2))

    let summary = try #require(tracker.summary(now: start.addingTimeInterval(4)))
    #expect(summary.systemSampleCount == 1)
    #expect(summary.missingSampleCount == 1)
  }
}

@Suite("Focused Check resolver")
struct FocusedCheckResolverTests {
  @Test func slowIsUnavailableWithoutSupportedSignals() {
    let result = FocusedCheckResolver.resolve(summary(intent: .slow, elapsed: 20))

    #expect(result.state == .unavailable)
    #expect(result.evidence.isEmpty)
  }

  @Test func slowIsInsufficientBeforeMinimumGate() {
    let result = FocusedCheckResolver.resolve(
      summary(intent: .slow, elapsed: 10, points: [point(at: 0, cpu: 80)])
    )

    #expect(result.state == .insufficientEvidence)
    #expect(result.headline == "More observation is needed.")
  }

  @Test func slowRanksSustainedActivityAboveOneOffSystemCPU() throws {
    let start = Date(timeIntervalSince1970: 1_000)
    let group = activity(id: "editor", title: "Editor", activeSamples: 5, maximumCPU: 120, start: start)
    let points = (0..<5).map { point(at: Double($0 * 4), cpu: 80, base: start) }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .slow, startedAt: start, endedAt: start.addingTimeInterval(20), systemPoints: points, appGroups: [group])
    )

    #expect(result.state == .review)
    #expect(try #require(result.evidence.first).kind == .appGroupActivity)
    #expect(result.evidence.count <= 3)
  }

  @Test func slowRanksRisingSwapAboveStaticMemoryLoad() throws {
    let start = Date(timeIntervalSince1970: 2_000)
    let points = (0..<5).map { index in
      point(at: Double(index * 4), cpu: 20, memory: 90, swap: UInt64(index) * 300_000_000, trend: index == 4 ? .rising : .stable, base: start)
    }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .slow, startedAt: start, endedAt: start.addingTimeInterval(20), systemPoints: points)
    )

    #expect(try #require(result.evidence.first).kind == .swapGrowth)
  }

  @Test func clearSlowResultAvoidsHealthDiagnosis() {
    let start = Date(timeIntervalSince1970: 3_000)
    let points = (0..<5).map { point(at: Double($0 * 4), cpu: 15, memory: 50, base: start) }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .slow, startedAt: start, endedAt: start.addingTimeInterval(20), systemPoints: points)
    )

    #expect(result.state == .clear)
    #expect(result.headline == "No persistent live signal appeared during this check.")
    #expect(resultText(result).localizedCaseInsensitiveContains("healthy") == false)
  }

  @Test func hotRequiresElevatedThermalStateForThermalConclusion() {
    let start = Date(timeIntervalSince1970: 4_000)
    let points = (0..<5).map { point(at: Double($0 * 4), cpu: 95, thermal: .nominal, base: start) }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .hot, startedAt: start, endedAt: start.addingTimeInterval(20), systemPoints: points)
    )

    #expect(result.state == .clear)
    #expect(result.evidence.contains { $0.kind == .thermalPressure } == false)
  }

  @Test func hotDescribesCPUOnlyAsCoincidentActivity() {
    let start = Date(timeIntervalSince1970: 5_000)
    let points = (0..<5).map { point(at: Double($0 * 4), cpu: 90, thermal: .serious, base: start) }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .hot, startedAt: start, endedAt: start.addingTimeInterval(20), systemPoints: points)
    )

    #expect(result.state == .review)
    #expect(result.headline.localizedCaseInsensitiveContains("coincided"))
    #expect(resultText(result).localizedCaseInsensitiveContains("caused") == false)
  }

  @Test func missingIntervalsReduceEvidenceConfidenceAndAppearInCoverage() throws {
    let start = Date(timeIntervalSince1970: 5_500)
    let points = (0..<5).map { point(at: Double($0 * 4), cpu: 90, thermal: .serious, base: start) }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(
        intent: .hot,
        startedAt: start,
        endedAt: start.addingTimeInterval(20),
        systemPoints: points,
        missingSampleCount: 2
      )
    )

    #expect(try #require(result.evidence.first).confidence == .medium)
    #expect(result.coverage.contains("2 refresh intervals were missing"))
  }

  @Test func batteryRejectsExternalPower() {
    let start = Date(timeIntervalSince1970: 6_000)
    let readings = (0..<5).map { index in
      BatteryLiveReading(chargePercent: 80, powerSource: .ac, isCharging: true, timestamp: start.addingTimeInterval(Double(index * 75)))
    }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .batteryDrain, startedAt: start, endedAt: start.addingTimeInterval(360), batteryReadings: readings)
    )

    #expect(result.state == .unavailable)
    #expect(result.headline == "Run this check while using battery power.")
  }

  @Test func batteryReportsActualChangeWithoutRateExtrapolation() throws {
    let start = Date(timeIntervalSince1970: 7_000)
    let readings = (0..<5).map { index in
      BatteryLiveReading(chargePercent: Double(90 - index), powerSource: .battery, isCharging: false, timestamp: start.addingTimeInterval(Double(index * 75)))
    }
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .batteryDrain, startedAt: start, endedAt: start.addingTimeInterval(360), batteryReadings: readings)
    )

    #expect(try #require(result.evidence.first).value == "−4%")
    #expect(resultText(result).localizedCaseInsensitiveContains("per hour") == false)
  }

  @Test func storageRequiresCompletedScan() {
    let result = FocusedCheckResolver.resolve(summary(intent: .storageFull, elapsed: 10))

    #expect(result.state == .unavailable)
    #expect(result.headline == "A completed storage scan is required.")
  }

  @Test func storageResultDoesNotPromiseCleanup() {
    let start = Date(timeIntervalSince1970: 8_000)
    let folder = StorageItem(
      title: "Projects",
      path: "~/Projects",
      sizeGB: 80,
      dataMode: .live,
      status: .info,
      severityScore: 20,
      explanation: "Test folder",
      source: "Test scan",
      confidence: "Live / medium",
      recommendedAction: "Review context",
      lastUpdated: start
    )
    let file = StorageItem(
      title: "Archive.zip",
      path: "~/Archive.zip",
      sizeGB: 20,
      dataMode: .live,
      status: .info,
      severityScore: 10,
      explanation: "Test file",
      source: "Test scan",
      confidence: "Live / medium",
      recommendedAction: "Review context",
      lastUpdated: start
    )
    let storage = FocusedCheckStorageAggregate(
      volumeUsedGB: 495,
      volumeAvailableGB: 5,
      scanRootTitle: "Macintosh HD",
      classifiedGB: 320,
      inaccessibleItemCount: 4,
      largestCategory: .documents,
      largestCategoryTitle: "Documents",
      largestCategoryGB: 120,
      largestFolder: folder,
      largestFile: file,
      completedAt: start.addingTimeInterval(5)
    )
    let result = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .storageFull, startedAt: start, endedAt: start.addingTimeInterval(5), storage: storage)
    )
    let text = resultText(result)

    #expect(result.state == .review)
    #expect(text.localizedCaseInsensitiveContains("reclaimable") == false)
    #expect(text.localizedCaseInsensitiveContains("safe to delete") == false)
    #expect(result.evidence.count <= 3)
    #expect(result.evidence.contains { $0.title == "Documents" })
    #expect(result.evidence.contains { $0.title == "Largest observed folder" })
  }

  @Test func resolvedResultsAvoidForbiddenCausalHealthAndCleanupClaims() {
    let start = Date(timeIntervalSince1970: 9_000)
    let points = (0..<5).map { point(at: Double($0 * 4), cpu: 90, memory: 90, thermal: .serious, base: start) }
    let slow = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(
        intent: .slow,
        startedAt: start,
        endedAt: start.addingTimeInterval(20),
        systemPoints: points,
        appGroups: [activity(id: "editor", title: "Editor", activeSamples: 5, maximumCPU: 90, start: start)]
      )
    )
    let hot = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .hot, startedAt: start, endedAt: start.addingTimeInterval(20), systemPoints: points)
    )
    let batteryReadings = (0..<5).map { index in
      BatteryLiveReading(chargePercent: Double(90 - index), powerSource: .battery, isCharging: false, timestamp: start.addingTimeInterval(Double(index * 75)))
    }
    let battery = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(intent: .batteryDrain, startedAt: start, endedAt: start.addingTimeInterval(360), systemPoints: points, batteryReadings: batteryReadings)
    )
    let storage = FocusedCheckResolver.resolve(
      FocusedCheckAggregateSummary(
        intent: .storageFull,
        startedAt: start,
        endedAt: start.addingTimeInterval(20),
        storage: FocusedCheckStorageAggregate(
          volumeUsedGB: 495,
          volumeAvailableGB: 5,
          scanRootTitle: "Full Storage Analysis",
          classifiedGB: 320,
          inaccessibleItemCount: 0,
          largestCategory: .documents,
          largestCategoryTitle: "Documents",
          largestCategoryGB: 120,
          largestFolder: nil,
          largestFile: nil,
          completedAt: start.addingTimeInterval(20)
        )
      )
    )
    let forbidden = ["caused", "your mac is healthy", "safe to delete", "reclaimable", "health score"]

    for result in [slow, hot, battery, storage] {
      let text = resultText(result).lowercased()
      #expect(result.evidence.count <= 3)
      for phrase in forbidden {
        #expect(!text.contains(phrase))
      }
    }
  }
}

@Suite("Focused Check store lifecycle")
@MainActor
struct FocusedCheckStoreTests {
  @Test func storageFocusedCheckRequiresConfirmationForRememberedFolderScope() {
    #expect(HealthDashboardStore.focusedStorageInitialPhase(accessStatus: .folderScopeGranted) == .readyForStorageScan)
    #expect(HealthDashboardStore.focusedStorageInitialPhase(accessStatus: .fullDiskAccessLikelyGranted) == .scanningStorage)
    #expect(HealthDashboardStore.focusedStorageInitialPhase(accessStatus: .needsFullDiskAccess) == .awaitingAccess)
  }

  @Test func recentFullStorageResultCanBeReusedButLimitedOrStaleResultsCannot() {
    let now = Date()
    let interval: TimeInterval = 6 * 60 * 60

    #expect(HealthDashboardStore.shouldReuseFullStorageResult(rootTitle: "Full Storage Analysis", lastUpdated: now.addingTimeInterval(-60), now: now, interval: interval))
    #expect(!HealthDashboardStore.shouldReuseFullStorageResult(rootTitle: "Folder", lastUpdated: now.addingTimeInterval(-60), now: now, interval: interval))
    #expect(!HealthDashboardStore.shouldReuseFullStorageResult(rootTitle: "Full Storage Analysis", lastUpdated: now.addingTimeInterval(-interval - 1), now: now, interval: interval))
  }

  @Test func retainedRefreshStartsOnceAndStopsExplicitly() {
    let store = HealthDashboardStore(collector: FocusedCheckFixtureCollector(snapshot: PreviewFixtures.snapshot))

    store.startLiveRefreshIfNeeded(intervalSeconds: 60)
    store.startLiveRefreshIfNeeded(intervalSeconds: 60)
    #expect(store.isLiveRefreshActive)

    store.stopLiveRefresh()
    #expect(store.isLiveRefreshActive == false)
  }

  @Test func generalCheckCompletesImmediatelyFromCurrentAttention() async {
    let store = HealthDashboardStore(collector: FocusedCheckFixtureCollector(snapshot: PreviewFixtures.snapshot))
    await store.refresh()

    store.startFocusedCheck(.general, now: PreviewFixtures.now)

    #expect(store.focusedCheckSession == nil)
    #expect(store.lastFocusedCheckResult?.intent == .general)
    #expect(store.lastFocusedCheckResult?.state == .clear)
  }

  @Test func finishFreezesAnInsufficientTimedResult() async {
    let store = HealthDashboardStore(collector: FocusedCheckFixtureCollector(snapshot: PreviewFixtures.snapshot))
    await store.refresh()
    store.startFocusedCheck(.slow, now: PreviewFixtures.now.addingTimeInterval(-1))

    store.finishFocusedCheck(now: PreviewFixtures.now)

    #expect(store.focusedCheckSession?.phase == .completed)
    #expect(store.lastFocusedCheckResult?.state == .insufficientEvidence)
  }

  @Test func cancelDiscardsOnlyPartialSession() async {
    let store = HealthDashboardStore(collector: FocusedCheckFixtureCollector(snapshot: PreviewFixtures.snapshot))
    await store.refresh()
    store.startFocusedCheck(.hot, now: PreviewFixtures.now.addingTimeInterval(-1))

    store.cancelFocusedCheck()

    #expect(store.focusedCheckSession == nil)
    #expect(store.lastFocusedCheckResult == nil)
  }

  @Test func cancellingANewCheckRestoresThePreviousCompletedResult() async {
    let store = HealthDashboardStore(collector: FocusedCheckFixtureCollector(snapshot: PreviewFixtures.snapshot))
    await store.refresh()
    store.startFocusedCheck(.general, now: PreviewFixtures.now)
    let previous = store.lastFocusedCheckResult
    #expect(previous != nil)

    store.startFocusedCheck(.hot, now: PreviewFixtures.now.addingTimeInterval(1))
    #expect(store.focusedCheckSession?.intent == .hot)
    #expect(store.lastFocusedCheckResult == previous)

    store.cancelFocusedCheck()

    #expect(store.focusedCheckSession == nil)
    #expect(store.lastFocusedCheckResult == previous)
  }

  @Test func temporarilyUnavailableSessionRecoversOnNextLiveSnapshot() async {
    let collector = MutableFocusedCollector(snapshot: PreviewFixtures.snapshot)
    let store = HealthDashboardStore(collector: collector)
    await store.refresh()
    let start = PreviewFixtures.now.addingTimeInterval(1)

    store.startFocusedCheck(.slow, now: start)
    #expect(store.focusedCheckSession?.phase == .unavailable)

    var next = PreviewFixtures.snapshot
    next.generatedAt = start.addingTimeInterval(2)
    collector.snapshot = next
    await store.refresh()

    #expect(store.focusedCheckSession?.phase == .observing)
    #expect(store.focusedCheckSession?.systemSampleCount == 1)
  }

  @Test func refreshFailureRecordsAGapWithoutDiscardingTheActiveCheck() async {
    let collector = FailableFocusedCollector(snapshot: PreviewFixtures.snapshot)
    let store = HealthDashboardStore(collector: collector)
    await store.refresh()
    store.startFocusedCheck(.slow, now: PreviewFixtures.now.addingTimeInterval(-1))
    let samplesBeforeFailure = store.focusedCheckSession?.systemSampleCount

    collector.shouldFail = true
    await store.refresh()

    #expect(store.focusedCheckSession?.systemSampleCount == samplesBeforeFailure)
    #expect(store.focusedCheckSession?.missingSampleCount == 1)
    #expect(store.errorMessage != nil)
  }
}

@Suite("Focused Check process interpretation")
struct FocusedCheckProcessInterpretationTests {
  @Test func appHelpersGroupByBundlePathAndUser() throws {
    let now = Date()
    let groups = AppProcessGroupingResolver.groups(
      processes: [
        process(pid: 1, name: "Editor Helper", cpu: 20, user: "rocco", path: "/Applications/Editor.app/Contents/Frameworks/Editor Helper", appName: "Editor"),
        process(pid: 2, name: "Editor Renderer", cpu: 30, user: "rocco", path: "/Applications/Editor.app/Contents/Frameworks/Editor Renderer", appName: "Editor")
      ],
      now: now
    )

    let group = try #require(groups.first)
    #expect(groups.count == 1)
    #expect(group.name == "Editor")
    #expect(group.memberPIDs == [1, 2])
    #expect(group.bundlePath == "/Applications/Editor.app")
    #expect(group.cpuPercent == 50)
  }

  @Test func sameProcessNameUnderDifferentUsersDoesNotCollide() {
    let groups = AppProcessGroupingResolver.groups(
      processes: [
        process(pid: 1, name: "worker", cpu: 5, user: "alice"),
        process(pid: 2, name: "worker", cpu: 5, user: "bob")
      ],
      now: Date()
    )

    #expect(groups.count == 2)
    #expect(Set(groups.map(\.id)).count == 2)
  }

  @Test(
    "Known process families resolve without causal claims",
    arguments: [
      ("WindowServer", ProcessInterpretationFamily.windowServer),
      ("mdworker_shared", .spotlight),
      ("fileproviderd", .cloudSync),
      ("mediaanalysisd", .mediaAnalysis),
      ("Corewise", .corewise),
      ("UnfamiliarWorker", .unknown)
    ]
  )
  func knownFamilies(name: String, expected: ProcessInterpretationFamily) {
    let interpretation = ProcessInterpretationResolver.interpretation(for: process(pid: 10, name: name, cpu: 1))

    #expect(interpretation.family == expected)
    #expect(interpretation.detail.localizedCaseInsensitiveContains("caused") == false)
  }

  @Test func evidenceRouteCarriesTypedAppGroupFocus() {
    let route = DashboardRoute(section: .performance, performanceMode: .cpu, focus: .appGroup(id: "owner|app|editor", mode: .cpu))

    #expect(route.focus == .appGroup(id: "owner|app|editor", mode: .cpu))
  }

  @Test func interpretationIncludesFocusedPersistenceAndSafeReviewContext() {
    let start = Date()
    let activity = FocusedCheckActivitySummary(
      id: "editor",
      title: "Editor",
      firstObservedAt: start,
      lastObservedAt: start.addingTimeInterval(20),
      sampleCount: 5,
      activeCPUSampleCount: 4,
      maximumCPUPercent: 80,
      peakMemoryBytes: 400 * 1024 * 1024,
      memberPIDs: [10, 11]
    )
    let interpretation = ProcessInterpretationResolver.interpretation(
      for: process(pid: 10, name: "Editor Helper", cpu: 80, path: "/Applications/Editor.app/Contents/Frameworks/Editor Helper", appName: "Editor"),
      activity: activity
    )

    #expect(interpretation.family == .appHelper)
    #expect(interpretation.activityPattern == .sustained)
    #expect(interpretation.matchedPIDs == [10, 11])
    #expect(!interpretation.expectedContexts.isEmpty)
    #expect(!interpretation.safeReviewAction.isEmpty)
  }
}

@Suite("Focused Check storage interpretation")
@MainActor
struct FocusedCheckStorageInterpretationTests {
  @Test func coverageSeparatesClassifiedFromOutsideScopeAndClampsAtZero() {
    var volume = PreviewFixtures.storage
    volume.usedGB = 100
    let result = storageResult(totalSizeGB: 35, inaccessible: 3)

    let coverage = StorageCoverageResolver.resolve(volume: volume, result: result, accessStatus: .folderScopeGranted, source: "Folder Scope")

    #expect(coverage.classifiedApprovedScopeGB == 35)
    #expect(coverage.outsideApprovedScopeGB == 65)
    #expect(coverage.coverageRatio == 0.35)
    #expect(coverage.inaccessibleItemCount == 3)
    #expect(coverage.scopeDescription == "One remembered folder scope")

    let oversized = StorageCoverageResolver.resolve(volume: volume, result: storageResult(totalSizeGB: 150), accessStatus: .fullDiskAccessLikelyGranted, source: "Full Disk Access")
    #expect(oversized.classifiedApprovedScopeGB == 100)
    #expect(oversized.outsideApprovedScopeGB == 0)
  }

  @Test func fullDiskAndFolderScopesUseDifferentCoverageLanguage() {
    var volume = PreviewFixtures.storage
    volume.usedGB = 100
    let result = storageResult(totalSizeGB: 20)

    let full = StorageCoverageResolver.resolve(volume: volume, result: result, accessStatus: .fullDiskAccessLikelyGranted, source: "Full Disk Access")
    let folder = StorageCoverageResolver.resolve(volume: volume, result: result, accessStatus: .folderScopeGranted, source: "Folder Scope")

    #expect(full.scopeDescription != folder.scopeDescription)
  }

  @Test func cacheAttributionDoesNotRecommendRemoval() {
    let attribution = StorageAttributionResolver.attribution(for: .cacheTemporary)
    let text = "\(attribution.explanation) \(attribution.safeActionLabel)"

    #expect(attribution.ownerKind == .cache)
    #expect(text.localizedCaseInsensitiveContains("safe to delete") == false)
    #expect(text.localizedCaseInsensitiveContains("reclaimable") == false)
  }

  @Test func applicationSupportPathsRemainDistinctFromApplicationsAndSystemData() {
    let item = StorageItem(
      title: "Editor Data",
      path: "~/Library/Application Support/Editor/Data",
      sizeGB: 2,
      dataMode: .live,
      status: .info,
      severityScore: 10,
      explanation: "Test fixture",
      source: "Test scan",
      confidence: "Live / medium",
      recommendedAction: "Review context",
      lastUpdated: Date()
    )

    let attribution = StorageAttributionResolver.attribution(for: item, isDirectory: true)

    #expect(attribution.ownerKind == .applicationSupport)
    #expect(attribution.reviewClass == .reviewInOwningApp)
    #expect(attribution.safeActionLabel == "Review in owning app")
  }
}

@Suite("Focused Check commands and report")
struct FocusedCheckCommandsAndReportTests {
  @Test func storageIntentLaunchesIntoStorageWhileTimedChecksLaunchIntoOverview() {
    #expect(FocusedCheckIntent.storageFull.launchRoute.section == .storage)
    #expect(FocusedCheckIntent.slow.launchRoute.section == .overview)
    #expect(FocusedCheckIntent.general.launchRoute.section == .overview)
  }

  @Test func quickActionsExposeLifecycleCommandsOnlyWhenRelevant() {
    let start = Date()
    let session = FocusedCheckSession(intent: .slow, now: start)
    let result = reportResult(start: start)

    let idle = QuickActionDescriptor.available(session: nil, result: nil)
    let active = QuickActionDescriptor.available(session: session, result: nil)
    let storageActive = QuickActionDescriptor.available(session: FocusedCheckSession(intent: .storageFull, now: start), result: nil)
    let completed = QuickActionDescriptor.available(session: nil, result: result)

    #expect(idle.contains { $0.id == .startFocusedCheck(.slow) })
    #expect(idle.contains { $0.id == .finishFocusedCheck } == false)
    #expect(active.contains { $0.id == .finishFocusedCheck })
    #expect(active.contains { $0.id == .cancelFocusedCheck })
    #expect(storageActive.contains { $0.id == .finishFocusedCheck } == false)
    #expect(storageActive.contains { $0.id == .cancelFocusedCheck })
    #expect(completed.contains { $0.id == .copyFocusedCheck })
  }

  @Test func focusedReportsShareResultAndRedactHomeDirectory() {
    let result = reportResult(start: Date())
    let builder = DiagnosticReportBuilder()
    let summary = builder.focusedCheckSummary(for: result)
    let markdown = builder.focusedCheckMarkdown(for: result)
    let home = FileManager.default.homeDirectoryForCurrentUser.path

    #expect(summary.contains(result.headline))
    #expect(markdown.contains(result.headline))
    #expect(summary.contains(result.primaryAction.title))
    #expect(markdown.contains(result.primaryAction.title))
    #expect(summary.contains(home) == false)
    #expect(markdown.contains(home) == false)
    #expect(summary.contains("Observed for: 20s"))
    #expect(markdown.contains("Coverage and Limitations"))
  }
}

private func summary(intent: FocusedCheckIntent, elapsed: TimeInterval, points: [FocusedCheckSystemPoint] = []) -> FocusedCheckAggregateSummary {
  let start = Date(timeIntervalSince1970: 100)
  return FocusedCheckAggregateSummary(intent: intent, startedAt: start, endedAt: start.addingTimeInterval(elapsed), systemPoints: points)
}

private func point(
  at offset: TimeInterval,
  cpu: Double? = nil,
  memory: Double? = nil,
  swap: UInt64? = nil,
  trend: SwapTrend = .stable,
  thermal: ThermalLevel = .unavailable,
  base: Date = Date(timeIntervalSince1970: 100)
) -> FocusedCheckSystemPoint {
  FocusedCheckSystemPoint(timestamp: base.addingTimeInterval(offset), cpuPercent: cpu, memoryUsedPercent: memory, swapUsedBytes: swap, swapTrend: trend, thermalLevel: thermal)
}

private func activity(id: String, title: String, activeSamples: Int, maximumCPU: Double, start: Date) -> FocusedCheckActivityAggregate {
  FocusedCheckActivityAggregate(
    id: id,
    title: title,
    firstObservedAt: start,
    lastObservedAt: start.addingTimeInterval(20),
    sampleCount: activeSamples,
    activeCPUSampleCount: activeSamples,
    maximumCPUPercent: maximumCPU,
    peakMemoryBytes: 500 * 1024 * 1024,
    memberPIDs: []
  )
}

private func process(
  pid: Int32,
  name: String,
  cpu: Double,
  user: String = "tester",
  path: String? = nil,
  appName: String? = nil
) -> ProcessObservation {
  ProcessObservation(
    pid: pid,
    processName: name,
    displayName: name,
    appName: appName,
    path: path,
    user: user,
    cpuPercent: cpu,
    cpuTimeSeconds: 1,
    threadCount: 1,
    residentMemoryBytes: 100 * 1024 * 1024,
    physicalFootprintBytes: nil,
    pageIns: 0,
    dataMode: .live,
    status: .info,
    severityScore: 0,
    explanation: "Test fixture",
    source: "Test fixture",
    confidence: "Live / high",
    recommendedAction: "None",
    lastUpdated: Date()
  )
}

private func resultText(_ result: FocusedCheckResult) -> String {
  ([result.headline, result.detail, result.coverage, result.primaryAction.title, result.primaryAction.detail]
    + result.evidence.flatMap { [$0.title, $0.value, $0.detail] })
    .joined(separator: " ")
}

private func storageResult(totalSizeGB: Double, inaccessible: Int = 0) -> StorageScanResult {
  StorageScanResult(
    rootTitle: "Test Scope",
    rootPath: "/Test",
    totalSizeGB: totalSizeGB,
    scannedItemCount: 1,
    scannedFileCount: 1,
    scannedFolderCount: 0,
    inaccessibleItemCount: inaccessible,
    scanDuration: 1,
    largestItems: [],
    largestFiles: [],
    largestFolders: [],
    categoryBreakdown: [],
    chartData: [],
    lastUpdated: Date()
  )
}

private func reportResult(start: Date) -> FocusedCheckResult {
  let path = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Documents/Large.mov").path
  let evidence = FocusedCheckEvidence(
    kind: .storageAttribution,
    area: .storage,
    title: "Largest observed file",
    value: "12 GB",
    detail: "Observed at \(path). Review it in context.",
    severity: .info,
    confidence: .medium,
    source: "Test scan",
    firstObservedAt: start,
    lastObservedAt: start.addingTimeInterval(20),
    sampleCount: 1,
    destination: DashboardRoute(section: .storage, focus: .storagePath(path))
  )
  return FocusedCheckResult(
    intent: .storageFull,
    state: .review,
    headline: "Low storage headroom is worth reviewing.",
    detail: "Observed storage only.",
    evidence: [evidence],
    primaryAction: FocusedCheckAction(title: "Review observed storage", detail: "Inspect ownership first.", destination: evidence.destination),
    observationStartedAt: start,
    observationEndedAt: start.addingTimeInterval(20),
    coverage: "Approved scope only.",
    generatedAt: start.addingTimeInterval(20)
  )
}

private struct FocusedCheckFixtureCollector: SystemHealthCollecting {
  var snapshot: HealthSnapshot

  func currentSnapshot() async throws -> HealthSnapshot {
    snapshot
  }
}

@MainActor
private final class MutableFocusedCollector: SystemHealthCollecting {
  var snapshot: HealthSnapshot

  init(snapshot: HealthSnapshot) {
    self.snapshot = snapshot
  }

  func currentSnapshot() async throws -> HealthSnapshot {
    snapshot
  }
}

@MainActor
private final class FailableFocusedCollector: SystemHealthCollecting {
  var snapshot: HealthSnapshot
  var shouldFail = false

  init(snapshot: HealthSnapshot) {
    self.snapshot = snapshot
  }

  func currentSnapshot() async throws -> HealthSnapshot {
    if shouldFail {
      throw FailableFocusedCollectorError.expected
    }
    return snapshot
  }
}

private enum FailableFocusedCollectorError: Error {
  case expected
}
