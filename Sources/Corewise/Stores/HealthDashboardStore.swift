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

  private let collector: SystemHealthCollecting
  private var appIssuesScanResult: AppIssuesHealth?

  init(collector: SystemHealthCollecting) {
    self.collector = collector
  }

  func refresh() async {
    isRefreshing = true
    errorMessage = nil

    do {
      snapshot = applyManualResults(to: try await collector.currentSnapshot())
    } catch {
      errorMessage = error.localizedDescription
    }

    isRefreshing = false
  }

  func startLiveRefresh(intervalSeconds: UInt64 = 2) async {
    await refresh()

    while !Task.isCancelled {
      try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
      await refresh()
    }
  }

  func scanStorageFolder(startingAt directoryURL: URL? = nil) async {
    guard let url = chooseDirectory(
      title: "Choose a folder to scan",
      message: "Corewise will read file sizes only in the folder you choose.",
      directoryURL: directoryURL
    ) else {
      return
    }

    await scanStorageSessionFolder(url, root: url)
  }

  func scanDownloadsFolder() async {
    await scanStorageFolder(startingAt: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first)
  }

  func scanDeveloperFolder() async {
    await scanStorageFolder(startingAt: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Developer"))
  }

  func scanStorageSessionFolder(_ url: URL) async {
    await scanStorageSessionFolder(url, root: storageScanSession?.rootURL ?? url)
  }

  func scanStorageParentFolder() async {
    guard let session = storageScanSession else {
      return
    }

    let parent = session.currentURL.deletingLastPathComponent()
    guard parent.path.hasPrefix(session.rootURL.path), parent.path != session.currentURL.path else {
      return
    }

    await scanStorageSessionFolder(parent, root: session.rootURL)
  }

  func scanCrashReportsFolder() async {
    let defaultURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/DiagnosticReports")
    guard let url = chooseDirectory(
      title: "Choose diagnostic reports folder",
      message: "Corewise will read crash report metadata from the folder you choose.",
      directoryURL: defaultURL
    ) else {
      return
    }

    isScanningReports = true
    errorMessage = nil
    let didStartAccess = url.startAccessingSecurityScopedResource()
    let appIssues = await Task.detached {
      CrashReportDiagnosticsCollector().currentAppIssues(reportDirectory: url, now: Date())
    }.value
    if didStartAccess {
      url.stopAccessingSecurityScopedResource()
    }

    appIssuesScanResult = appIssues
    if let snapshot {
      self.snapshot = applyManualResults(to: snapshot)
    }
    isScanningReports = false
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

  private func applyManualResults(to snapshot: HealthSnapshot) -> HealthSnapshot {
    var snapshot = snapshot

    if let storageScanSession {
      snapshot.storage = storageByApplying(storageScanSession.result, to: snapshot.storage)
      snapshot.dataAccess = updateDataAccess(snapshot.dataAccess, title: "Storage folder details", dataMode: .live)
    }

    if let appIssuesScanResult {
      snapshot.appIssues = appIssuesScanResult
      snapshot.dataAccess = updateDataAccess(snapshot.dataAccess, title: "Crash report patterns", dataMode: .live)
    }

    return snapshot
  }

  private func storageByApplying(_ result: StorageScanResult, to storage: StorageHealth) -> StorageHealth {
    var storage = storage
    let scanStatus: FindingSeverity = result.inaccessibleItemCount > 0 ? .info : .good
    let now = result.lastUpdated

    storage.metrics.append(contentsOf: [
      DiagnosticMetric(title: "Scanned Folder", value: result.rootTitle, unit: "", dataMode: .live, status: .good, severityScore: 0, explanation: "Folder selected manually for a read-only size scan.", source: "User-selected folder scan", confidence: "Live / medium", recommendedAction: "Review results manually before changing files.", lastUpdated: now),
      DiagnosticMetric(title: "Scan Size", value: number(result.totalSizeGB), unit: "GB", dataMode: .live, status: scanStatus, severityScore: min(Int((result.totalSizeGB * 2).rounded()), 100), explanation: "Total file size found inside the selected folder.", source: "User-selected folder scan", confidence: "Live / medium", recommendedAction: "Use Finder to inspect anything you do not recognize.", lastUpdated: now),
      DiagnosticMetric(title: "Items Scanned", value: "\(result.scannedItemCount)", unit: "files", dataMode: .live, status: .info, severityScore: min(result.scannedItemCount / 100, 100), explanation: "Readable regular files counted during the scan.", source: "User-selected folder scan", confidence: "Live / medium", recommendedAction: "Large counts are normal in developer and cache folders.", lastUpdated: now),
      DiagnosticMetric(title: "Unreadable Items", value: "\(result.inaccessibleItemCount)", unit: "items", dataMode: .live, status: scanStatus, severityScore: min(result.inaccessibleItemCount * 4, 100), explanation: "Items Corewise could not read during the scan.", source: "User-selected folder scan", confidence: "Live / medium", recommendedAction: "Unreadable items are omitted instead of estimated.", lastUpdated: now)
    ])
    storage.largeFolders = result.largestFolders
    storage.largeFiles = result.largestFiles
    storage.developerCaches = []
    storage.browserCaches = []
    storage.spaceOffenders = result.chartData
    storage.findings.append(
      DiagnosticFinding(
        title: "Manual scan completed",
        detail: "\(result.rootPath) scanned in \(number(result.scanDuration)) seconds. \(result.inaccessibleItemCount) items were unreadable and omitted.",
        status: scanStatus,
        severityScore: min(result.inaccessibleItemCount * 4, 100)
      )
    )
    storage.sourceNote = "Mixed live storage data. Volume capacity is automatic; largest items come only from the last user-selected folder scan."
    return storage
  }

  private func scanStorageSessionFolder(_ url: URL, root: URL) async {
    isScanningStorage = true
    errorMessage = nil
    let didStartAccess = root.startAccessingSecurityScopedResource()
    let result = await Task.detached {
      StorageTargetedScanCollector().scan(root: url, now: Date())
    }.value
    if didStartAccess {
      root.stopAccessingSecurityScopedResource()
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
    isScanningStorage = false
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

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }
}
