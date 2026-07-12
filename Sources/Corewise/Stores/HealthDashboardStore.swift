import AppKit
import Combine
import Foundation

@MainActor
final class HealthDashboardStore: ObservableObject {
  @Published private(set) var snapshot: HealthSnapshot?
  @Published private(set) var isRefreshing = false
  @Published private(set) var isScanningStorage = false
  @Published private(set) var isScanningReports = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var storageScanSession: StorageScanSession?
  @Published private(set) var rememberedStorageScopeEnabled = false
  @Published private(set) var rememberedStorageScopeTitle: String?
  @Published private(set) var storageAccessStatus: StorageAccessStatus = .notRequested
  @Published private(set) var storageAccessSummary = "Full Disk Access has not been checked yet."
  @Published private(set) var storageAnalysisSource = "Startup volume only"
  @Published private(set) var storageScanProgress: StorageScanProgress?
  @Published private(set) var storageScanPhase: StorageScanPhase = .idle
  @Published private(set) var isAwaitingFullDiskAccess = false
  @Published private(set) var focusedCheckSession: FocusedCheckSession?
  @Published private(set) var lastFocusedCheckResult: FocusedCheckResult?

  private let collector: SystemHealthCollecting
  private let openFullDiskAccessSettingsAction: @MainActor () -> Void
  private let focusedCheckTracker = FocusedCheckTracker()
  private var appIssuesScanResult: AppIssuesHealth?
  private var liveRefreshTask: Task<Void, Never>?
  private var storageCoordinatorTask: Task<Void, Never>?
  private var storageScanTask: Task<StorageScanResult, Never>?
  private var lastExplicitStorageScanAt: Date?
  private var lastStorageAccessProbeAt: Date?
  private var lastStorageAccessProbe: StorageAccessProbeResult?
  private let fullStorageScanInterval: TimeInterval = 6 * 60 * 60
  private let storageAccessProbeInterval: TimeInterval = 60

  init(
    collector: SystemHealthCollecting,
    openFullDiskAccessSettings: @escaping @MainActor () -> Void = HealthDashboardStore.openFullDiskAccessSettings
  ) {
    self.collector = collector
    self.openFullDiskAccessSettingsAction = openFullDiskAccessSettings
    rememberedStorageScopeEnabled = Self.savedAutomaticStorageBookmark != nil
    rememberedStorageScopeTitle = UserDefaults.standard.string(forKey: CorewiseSettingsKeys.storageAutomaticClassificationTitle)
  }

  deinit {
    liveRefreshTask?.cancel()
    storageCoordinatorTask?.cancel()
    storageScanTask?.cancel()
  }

  var isLiveRefreshActive: Bool {
    liveRefreshTask != nil
  }

  func refresh() async {
    guard !isRefreshing else {
      return
    }

    isRefreshing = true
    defer { isRefreshing = false }
    errorMessage = nil

    do {
      let refreshedSnapshot = applyManualResults(to: try await collector.currentSnapshot())
      snapshot = refreshedSnapshot
      ingestFocusedCheck(refreshedSnapshot)
      await refreshStorageAnalysisIfNeeded()
    } catch is CancellationError {
      return
    } catch {
      recordFocusedCheckRefreshGap(now: Date())
      errorMessage = error.localizedDescription
    }
  }

  func startLiveRefreshIfNeeded(intervalSeconds: UInt64 = 2) {
    guard liveRefreshTask == nil else {
      return
    }

    liveRefreshTask = Task { [weak self] in
      while !Task.isCancelled {
        guard let self else { return }
        await self.refresh()
        do {
          try await Task.sleep(for: .seconds(intervalSeconds))
        } catch {
          return
        }
      }
    }
  }

  func stopLiveRefresh() {
    liveRefreshTask?.cancel()
    liveRefreshTask = nil
  }

  func startFocusedCheck(_ intent: FocusedCheckIntent, now: Date = Date()) {
    if intent == .general {
      focusedCheckTracker.reset()
      focusedCheckSession = nil
      guard let snapshot else {
        lastFocusedCheckResult = FocusedCheckResult(
          intent: .general,
          state: .unavailable,
          headline: "Live signals are not available yet.",
          detail: "Wait for the first local snapshot, then try again.",
          evidence: [],
          primaryAction: FocusedCheckAction(title: "Refresh signals", detail: "Collect a new local snapshot.", destination: DashboardRoute(section: .overview)),
          observationStartedAt: now,
          observationEndedAt: now,
          coverage: "No supported snapshot was available.",
          generatedAt: now
        )
        return
      }
      lastFocusedCheckResult = FocusedCheckResolver.resolveGeneral(attention: snapshot.attentionSummary, now: now)
      return
    }

    focusedCheckTracker.start(intent: intent, now: now)
    var session = FocusedCheckSession(intent: intent, now: now)
    if intent == .storageFull {
      session.phase = Self.focusedStorageInitialPhase(accessStatus: storageAccessStatus)
    }
    focusedCheckSession = session

    if let snapshot, intent != .storageFull {
      ingestFocusedCheck(snapshot)
    }

    if intent == .storageFull,
       storageAccessStatus == .fullDiskAccessLikelyGranted,
       let reusableResult = reusableFullStorageResult(now: now) {
      completeStorageFocusedCheckIfNeeded(reusableResult)
    } else if intent == .storageFull, storageAccessStatus != .folderScopeGranted {
      Task { [weak self] in
        await self?.refreshStorageAnalysisIfNeeded(force: true)
      }
    }
  }

  func finishFocusedCheck(now: Date = Date()) {
    guard let summary = focusedCheckTracker.summary(now: now) else {
      return
    }
    completeFocusedCheck(summary)
  }

  func cancelFocusedCheck() {
    guard focusedCheckSession != nil else {
      return
    }
    if focusedCheckSession?.intent == .storageFull {
      storageCoordinatorTask?.cancel()
      storageScanTask?.cancel()
    }
    focusedCheckTracker.reset()
    focusedCheckSession = nil
  }

  func dismissFocusedCheckResult() {
    lastFocusedCheckResult = nil
    if focusedCheckSession?.phase == .completed {
      focusedCheckSession = nil
    }
  }

  func chooseLimitedStorageScope() async {
    guard let url = chooseDirectory(
      title: "Choose one limited storage scope",
      message: "Corewise remembers this folder and reuses it for read-only analysis. You will not need to choose it again.",
      directoryURL: FileManager.default.homeDirectoryForCurrentUser
    ) else {
      return
    }

    do {
      let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(bookmark, forKey: CorewiseSettingsKeys.storageAutomaticClassificationBookmark)
      UserDefaults.standard.set(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent, forKey: CorewiseSettingsKeys.storageAutomaticClassificationTitle)
      rememberedStorageScopeEnabled = true
      rememberedStorageScopeTitle = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
      isAwaitingFullDiskAccess = false
      storageAccessStatus = .folderScopeGranted
      storageAnalysisSource = "Folder Scope"
      if await scanStorageSessionFolder(url, root: url, source: "Folder Scope") {
        lastExplicitStorageScanAt = Date()
      }
    } catch {
      errorMessage = "Could not remember the selected folder for later read-only scans."
    }
  }

  func forgetLimitedStorageScope() {
    UserDefaults.standard.removeObject(forKey: CorewiseSettingsKeys.storageAutomaticClassificationBookmark)
    UserDefaults.standard.removeObject(forKey: CorewiseSettingsKeys.storageAutomaticClassificationTitle)
    rememberedStorageScopeEnabled = false
    rememberedStorageScopeTitle = nil
    lastExplicitStorageScanAt = nil
    storageScanSession = nil
    storageAccessStatus = .needsFullDiskAccess
    storageAnalysisSource = "Startup volume only"
  }

  func requestFullStorageAnalysisAccess() {
    isAwaitingFullDiskAccess = true
    storageAccessSummary = "Enable Corewise once in Full Disk Access, then return here. Corewise will check automatically."
    updateFocusedStoragePhase(.awaitingAccess)
    openFullDiskAccessSettingsAction()
  }

  func checkStorageAccessAndRescan() async {
    await refreshStorageAnalysisIfNeeded(force: true)
  }

  func applicationDidBecomeActive() async {
    guard isAwaitingFullDiskAccess else {
      return
    }
    await checkStorageAccessAndRescan()
  }

  func cancelStorageScan() {
    storageCoordinatorTask?.cancel()
    storageScanTask?.cancel()
    storageScanProgress = nil
    storageScanPhase = .cancelled
    if focusedCheckSession?.intent == .storageFull {
      cancelFocusedCheck()
    }
  }

  func clearError() {
    errorMessage = nil
  }

  func scanStorageSessionFolder(_ url: URL) async {
    _ = await scanStorageSessionFolder(url, root: storageScanSession?.rootURL ?? url)
  }

  func scanStorageParentFolder() async {
    guard let session = storageScanSession else {
      return
    }

    let parent = session.currentURL.deletingLastPathComponent()
    guard parent.path.hasPrefix(session.rootURL.path), parent.path != session.currentURL.path else {
      return
    }

    _ = await scanStorageSessionFolder(parent, root: session.rootURL, source: storageAnalysisSource)
  }

  func scanCrashReportsFolder() async {
    guard !isScanningReports else {
      return
    }

    let defaultURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/DiagnosticReports")
    guard let url = chooseDirectory(
      title: "Choose diagnostic reports folder",
      message: "Corewise will read crash report metadata from the folder you choose.",
      directoryURL: defaultURL
    ) else {
      return
    }

    isScanningReports = true
    defer { isScanningReports = false }
    errorMessage = nil
    let didStartAccess = url.startAccessingSecurityScopedResource()
    let appIssues = await Task.detached {
      CrashReportDiagnosticsCollector().currentAppIssues(reportDirectory: url, now: Date())
    }.value
    if didStartAccess {
      url.stopAccessingSecurityScopedResource()
    }

    guard !Task.isCancelled else {
      return
    }

    appIssuesScanResult = appIssues
    if let snapshot {
      self.snapshot = applyManualResults(to: snapshot)
    }
  }

  private func chooseDirectory(title: String, message: String, directoryURL: URL?) -> URL? {
    let panel = NSOpenPanel()
    panel.title = title
    panel.message = message
    panel.prompt = "Choose"
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = false
    panel.directoryURL = directoryURL

    return panel.runModal() == .OK ? panel.url : nil
  }

  private func refreshStorageAnalysisIfNeeded(force: Bool = false) async {
    let now = Date()
    let probe: StorageAccessProbeResult
    if Self.shouldProbeStorageAccess(
      lastProbeAt: lastStorageAccessProbeAt,
      now: now,
      interval: storageAccessProbeInterval,
      force: force
    ) {
      let probeTask = Task.detached(priority: .utility) {
        FullStorageAnalysisCollector().probe(now: now)
      }
      probe = await probeTask.value
      guard !Task.isCancelled else {
        return
      }
      lastStorageAccessProbe = probe
      lastStorageAccessProbeAt = now
    } else if let cachedProbe = lastStorageAccessProbe {
      probe = cachedProbe
    } else {
      return
    }

    storageAccessStatus = probe.status
    storageAccessSummary = storageAccessSummary(for: probe)
    if !isScanningStorage {
      storageScanPhase = probe.status == .needsFullDiskAccess ? .accessRequired : .ready
    }
    if focusedCheckSession?.intent == .storageFull {
      updateFocusedStoragePhase(probe.status == .needsFullDiskAccess ? .awaitingAccess : .scanningStorage)
    }

    if probe.status == .fullDiskAccessLikelyGranted {
      isAwaitingFullDiskAccess = false
      rememberedStorageScopeEnabled = false
      rememberedStorageScopeTitle = nil
      storageAnalysisSource = "Full Disk Access"
      if Self.shouldRunStorageAnalysis(lastScanAt: lastExplicitStorageScanAt, now: now, interval: fullStorageScanInterval, force: force) {
        scheduleFullStorageAnalysisIfNeeded(force: true)
      }
      return
    }

    guard let bookmark = Self.savedAutomaticStorageBookmark else {
      return
    }

    var isStale = false
    do {
      let url = try URL(
        resolvingBookmarkData: bookmark,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      if isStale {
        UserDefaults.standard.removeObject(forKey: CorewiseSettingsKeys.storageAutomaticClassificationBookmark)
        UserDefaults.standard.removeObject(forKey: CorewiseSettingsKeys.storageAutomaticClassificationTitle)
        rememberedStorageScopeEnabled = false
        rememberedStorageScopeTitle = nil
        storageAccessStatus = .needsFullDiskAccess
        storageAnalysisSource = "Startup volume only"
        storageScanPhase = .failed("The remembered folder permission is no longer valid. The last completed result was kept.")
        return
      }

      storageAccessStatus = .folderScopeGranted
      isAwaitingFullDiskAccess = false
      storageAnalysisSource = "Folder Scope"
      if Self.shouldRunStorageAnalysis(lastScanAt: lastExplicitStorageScanAt, now: now, interval: fullStorageScanInterval, force: force) {
        scheduleFolderStorageAnalysis(url: url, now: now)
      }
    } catch {
      errorMessage = "Could not read the remembered storage classification scope."
      storageScanPhase = .failed("The remembered folder could not be opened. The last completed result was kept.")
    }
  }

  private func scheduleFullStorageAnalysisIfNeeded(force: Bool) {
    guard storageCoordinatorTask == nil else {
      return
    }

    storageCoordinatorTask = Task { [weak self] in
      guard let self else {
        return
      }
      defer { self.storageCoordinatorTask = nil }
      await self.scanFullStorageAnalysisIfNeeded(force: force)
    }
  }

  private func scheduleFolderStorageAnalysis(url: URL, now: Date) {
    guard storageCoordinatorTask == nil else {
      return
    }

    storageCoordinatorTask = Task { [weak self] in
      guard let self else {
        return
      }
      defer { self.storageCoordinatorTask = nil }
      if await self.scanStorageSessionFolder(url, root: url, source: "Folder Scope") {
        self.lastExplicitStorageScanAt = now
      }
    }
  }

  private func scanFullStorageAnalysisIfNeeded(force: Bool) async {
    let now = Date()
    guard !isScanningStorage,
          Self.shouldRunStorageAnalysis(lastScanAt: lastExplicitStorageScanAt, now: now, interval: fullStorageScanInterval, force: force) else {
      return
    }

    isScanningStorage = true
    updateFocusedStoragePhase(.scanningStorage)
    storageScanPhase = .scanning(
      StorageScanProgress(currentScope: "Preparing", scopeIndex: 1, scopeCount: 1, scannedFiles: 0, scannedFolders: 0, unreadableCount: 0, elapsed: 0)
    )
    defer {
      isScanningStorage = false
      storageScanTask = nil
      storageScanProgress = nil
    }
    errorMessage = nil
    let (progressStream, progressContinuation) = AsyncStream.makeStream(of: StorageScanProgress.self)
    let progressTask = Task { [weak self] in
      for await progress in progressStream {
        self?.storageScanProgress = progress
        self?.storageScanPhase = .scanning(progress)
      }
    }
    let task = Task.detached(priority: .utility) {
      FullStorageAnalysisCollector().scan(now: Date()) { progress in
        progressContinuation.yield(progress)
      }
    }
    storageScanTask = task
    let result = await withTaskCancellationHandler {
      await task.value
    } onCancel: {
      task.cancel()
    }
    progressContinuation.finish()
    await progressTask.value

    guard !task.isCancelled, !Task.isCancelled else {
      storageScanPhase = .cancelled
      return
    }

    storageScanSession = StorageScanSession(
      rootURL: FileManager.default.homeDirectoryForCurrentUser,
      currentURL: FileManager.default.homeDirectoryForCurrentUser,
      breadcrumbs: [StorageBreadcrumb(title: "Full Storage Analysis", url: FileManager.default.homeDirectoryForCurrentUser)],
      result: result
    )
    if let snapshot {
      self.snapshot = applyManualResults(to: snapshot)
    }
    lastExplicitStorageScanAt = now
    storageScanPhase = .result
    completeStorageFocusedCheckIfNeeded(result)
  }

  private func applyManualResults(to snapshot: HealthSnapshot) -> HealthSnapshot {
    var snapshot = snapshot

    if let storageScanSession {
      snapshot.storage = storageByApplying(storageScanSession.result, to: snapshot.storage, source: storageAnalysisSource)
      snapshot.dataAccess = updateDataAccess(snapshot.dataAccess, title: "Storage folder details", dataMode: .live)
    }

    if let appIssuesScanResult {
      snapshot.appIssues = appIssuesScanResult
      snapshot.dataAccess = updateDataAccess(snapshot.dataAccess, title: "Crash report patterns", dataMode: .live)
    }

    return snapshot
  }

  private func storageByApplying(_ result: StorageScanResult, to storage: StorageHealth, source: String) -> StorageHealth {
    var storage = storage
    let scanStatus: FindingSeverity = result.inaccessibleItemCount > 0 ? .info : .good
    let now = result.lastUpdated

    storage.metrics.append(contentsOf: [
      DiagnosticMetric(title: "Storage Analysis Source", value: source, unit: "", dataMode: .live, status: .good, severityScore: 0, explanation: "Storage classification source currently used by Corewise.", source: source, confidence: "Live / medium", recommendedAction: "Use System Settings to revoke Full Disk Access if you no longer want broad storage analysis.", lastUpdated: now),
      DiagnosticMetric(title: "Scan Size", value: number(result.totalSizeGB), unit: "GB", dataMode: .live, status: scanStatus, severityScore: min(Int((result.totalSizeGB * 2).rounded()), 100), explanation: "Total file size found inside the approved storage analysis scope.", source: source, confidence: "Live / medium", recommendedAction: "Use Finder to inspect anything you do not recognize.", lastUpdated: now),
      DiagnosticMetric(title: "Files Scanned", value: "\(result.scannedFileCount)", unit: "files", dataMode: .live, status: .info, severityScore: min(result.scannedFileCount / 100, 100), explanation: "Readable regular files counted during the scan.", source: source, confidence: "Live / medium", recommendedAction: "Large counts are normal in developer and cache folders.", lastUpdated: now),
      DiagnosticMetric(title: "Folders Scanned", value: "\(result.scannedFolderCount)", unit: "folders", dataMode: .live, status: .info, severityScore: min(result.scannedFolderCount / 100, 100), explanation: "Readable folders visited during the scan.", source: source, confidence: "Live / medium", recommendedAction: "Use largest folders to focus manual review.", lastUpdated: now),
      DiagnosticMetric(title: "Unreadable Items", value: "\(result.inaccessibleItemCount)", unit: "items", dataMode: .live, status: scanStatus, severityScore: min(result.inaccessibleItemCount * 4, 100), explanation: "Items Corewise could not read during the scan.", source: source, confidence: "Live / medium", recommendedAction: "Unreadable items are omitted instead of estimated.", lastUpdated: now)
    ])
    storage.largeFolders = result.largestFolders
    storage.largeFiles = result.largestFiles
    storage.developerCaches = []
    storage.browserCaches = []
    storage.spaceOffenders = result.chartData
    storage.findings.append(
      DiagnosticFinding(
        title: "Storage analysis completed",
        detail: "\(result.rootPath) scanned in \(number(result.scanDuration)) seconds. \(result.inaccessibleItemCount) items were unreadable and omitted.",
        status: scanStatus,
        severityScore: min(result.inaccessibleItemCount * 4, 100)
      )
    )
    storage.sourceNote = "Mixed live storage data. Volume capacity is automatic; category and largest-item detail come from \(source). Corewise reads file sizes locally and does not delete, upload, or modify files."
    return storage
  }

  private func scanStorageSessionFolder(_ url: URL, root: URL, source: String = "User-selected folder scan") async -> Bool {
    guard !isScanningStorage else {
      return false
    }

    isScanningStorage = true
    updateFocusedStoragePhase(.scanningStorage)
    storageScanPhase = .scanning(
      StorageScanProgress(currentScope: url.lastPathComponent, scopeIndex: 1, scopeCount: 1, scannedFiles: 0, scannedFolders: 0, unreadableCount: 0, elapsed: 0)
    )
    defer {
      isScanningStorage = false
      storageScanTask = nil
      storageScanProgress = nil
    }
    errorMessage = nil
    let didStartAccess = root.startAccessingSecurityScopedResource()
    defer {
      if didStartAccess {
        root.stopAccessingSecurityScopedResource()
      }
    }

    let (progressStream, progressContinuation) = AsyncStream.makeStream(of: StorageScanProgress.self)
    let progressTask = Task { [weak self] in
      for await progress in progressStream {
        self?.storageScanProgress = progress
        self?.storageScanPhase = .scanning(progress)
      }
    }
    let task = Task.detached(priority: .utility) {
      StorageTargetedScanCollector().scan(root: url, now: Date(), source: source) { progress in
        progressContinuation.yield(progress)
      }
    }
    storageScanTask = task
    let result = await withTaskCancellationHandler {
      await task.value
    } onCancel: {
      task.cancel()
    }
    progressContinuation.finish()
    await progressTask.value

    guard !task.isCancelled, !Task.isCancelled else {
      storageScanPhase = .cancelled
      return false
    }

    storageScanSession = StorageScanSession(
      rootURL: root,
      currentURL: url,
      breadcrumbs: breadcrumbs(root: root, current: url),
      result: result
    )
    if let snapshot {
      self.snapshot = applyManualResults(to: snapshot)
    }
    storageScanPhase = .result
    completeStorageFocusedCheckIfNeeded(result)
    return true
  }

  private func breadcrumbs(root: URL, current: URL) -> [StorageBreadcrumb] {
    let root = root.standardizedFileURL
    let current = current.standardizedFileURL
    let rootPath = root.path
    let currentPath = current.path
    let rootTitle = root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent

    guard currentPath.hasPrefix(rootPath) else {
      return [StorageBreadcrumb(title: rootTitle, url: root)]
    }

    let relative = currentPath.dropFirst(rootPath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    var breadcrumbs = [StorageBreadcrumb(title: rootTitle, url: root)]
    var url = root
    for part in relative.split(separator: "/", omittingEmptySubsequences: true) {
      url.appendPathComponent(String(part))
      breadcrumbs.append(StorageBreadcrumb(title: String(part), url: url))
    }
    return breadcrumbs
  }

  private func updateDataAccess(_ capabilities: [DataAccessCapability], title: String, dataMode: DataMode) -> [DataAccessCapability] {
    capabilities.map { capability in
      guard capability.title == title else {
        return capability
      }

      var capability = capability
      capability.dataMode = dataMode
      return capability
    }
  }

  private func ingestFocusedCheck(_ snapshot: HealthSnapshot) {
    guard var session = focusedCheckSession,
          session.phase == .observing || session.phase == .readyToFinish || session.phase == .unavailable,
          session.intent != .storageFull else {
      return
    }

    focusedCheckTracker.ingest(snapshot: snapshot)
    guard let summary = focusedCheckTracker.summary(now: snapshot.generatedAt) else {
      return
    }
    let provisional = FocusedCheckResolver.resolve(summary)
    session.systemSampleCount = summary.systemSampleCount
    session.distinctBatterySampleCount = summary.distinctBatterySampleCount
    session.missingSampleCount = summary.missingSampleCount
    session.lastUpdatedAt = snapshot.generatedAt
    session.provisionalEvidence = provisional.evidence
    session.activityGroups = summary.topAppGroupSummaries
    if provisional.state == .unavailable {
      session.phase = .unavailable
    } else if provisional.state == .insufficientEvidence {
      session.phase = .observing
    } else {
      session.phase = .readyToFinish
    }

    if session != focusedCheckSession {
      focusedCheckSession = session
    }

    if let suggestedDuration = session.suggestedDuration,
       summary.elapsed >= suggestedDuration,
       provisional.state != .insufficientEvidence,
       provisional.state != .unavailable {
      completeFocusedCheck(summary)
    }
  }

  private func completeFocusedCheck(_ summary: FocusedCheckAggregateSummary) {
    let result = FocusedCheckResolver.resolve(summary)
    lastFocusedCheckResult = result
    if var session = focusedCheckSession {
      session.phase = .completed
      session.completedAt = result.generatedAt
      session.lastUpdatedAt = result.generatedAt
      session.systemSampleCount = summary.systemSampleCount
      session.distinctBatterySampleCount = summary.distinctBatterySampleCount
      session.missingSampleCount = summary.missingSampleCount
      session.provisionalEvidence = result.evidence
      session.activityGroups = summary.topAppGroupSummaries
      session.result = result
      focusedCheckSession = session
    }
    focusedCheckTracker.reset()
  }

  private func completeStorageFocusedCheckIfNeeded(_ result: StorageScanResult) {
    guard focusedCheckSession?.intent == .storageFull,
          let snapshot else {
      return
    }
    focusedCheckTracker.recordStorage(result: result, volume: snapshot.storage)
    if let summary = focusedCheckTracker.summary(now: result.lastUpdated) {
      completeFocusedCheck(summary)
    }
  }

  private func reusableFullStorageResult(now: Date) -> StorageScanResult? {
    guard let result = storageScanSession?.result,
          Self.shouldReuseFullStorageResult(
            rootTitle: result.rootTitle,
            lastUpdated: result.lastUpdated,
            now: now,
            interval: fullStorageScanInterval
          ) else {
      return nil
    }
    return result
  }

  private func updateFocusedStoragePhase(_ phase: FocusedCheckPhase) {
    guard var session = focusedCheckSession, session.intent == .storageFull else {
      return
    }
    session.phase = phase
    session.lastUpdatedAt = Date()
    focusedCheckSession = session
  }

  private func recordFocusedCheckRefreshGap(now: Date) {
    guard var session = focusedCheckSession,
          session.phase != .completed,
          session.intent != .storageFull else {
      return
    }
    focusedCheckTracker.recordMissingInterval(at: now)
    guard let summary = focusedCheckTracker.summary(now: now) else {
      return
    }
    session.missingSampleCount = summary.missingSampleCount
    session.lastUpdatedAt = now
    focusedCheckSession = session
  }

  private func storageAccessSummary(for probe: StorageAccessProbeResult) -> String {
    switch probe.status {
    case .fullDiskAccessLikelyGranted:
      return "Full Disk Access is available. Corewise can analyze its curated standard scopes without folder prompts."
    case .needsFullDiskAccess:
      return "Full Disk Access is required before Corewise can analyze standard folders when requested."
    case .unavailable:
      return "No standard storage scopes were available to probe."
    case .folderScopeGranted:
      return "A remembered folder scope is available."
    case .notRequested:
      return "Full Disk Access has not been checked yet."
    }
  }

  private static var savedAutomaticStorageBookmark: Data? {
    UserDefaults.standard.data(forKey: CorewiseSettingsKeys.storageAutomaticClassificationBookmark)
  }

  private static func openFullDiskAccessSettings() {
    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
      return
    }
    NSWorkspace.shared.open(url)
  }

  static func shouldRunStorageAnalysis(lastScanAt: Date?, now: Date, interval: TimeInterval, force: Bool) -> Bool {
    _ = lastScanAt
    _ = now
    _ = interval
    return force
  }

  static func shouldProbeStorageAccess(lastProbeAt: Date?, now: Date, interval: TimeInterval, force: Bool) -> Bool {
    if force || lastProbeAt == nil {
      return true
    }
    return now.timeIntervalSince(lastProbeAt ?? now) >= interval
  }

  static func focusedStorageInitialPhase(accessStatus: StorageAccessStatus) -> FocusedCheckPhase {
    switch accessStatus {
    case .fullDiskAccessLikelyGranted: .scanningStorage
    case .folderScopeGranted: .readyForStorageScan
    case .notRequested, .needsFullDiskAccess, .unavailable: .awaitingAccess
    }
  }

  static func shouldReuseFullStorageResult(
    rootTitle: String,
    lastUpdated: Date,
    now: Date,
    interval: TimeInterval
  ) -> Bool {
    let age = now.timeIntervalSince(lastUpdated)
    return rootTitle == "Full Storage Analysis" && age >= 0 && age <= interval
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }
}
