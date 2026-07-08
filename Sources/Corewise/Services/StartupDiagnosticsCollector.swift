import Foundation
import Security

struct StartupDiagnosticsCollector {
  private var locations: [StartupScanLocation]
  private var fileManager: FileManager

  init(locations: [StartupScanLocation] = StartupScanLocation.defaultLocations(), fileManager: FileManager = .default) {
    self.locations = locations
    self.fileManager = fileManager
  }

  func currentStartup(now: Date) -> StartupHealth {
    let scannedItems = locations.flatMap { scan(location: $0, now: now) }
    let launchAgents = scannedItems.filter { $0.kind == "Launch Agent" }
    let launchDaemons = scannedItems.filter { $0.kind == "Launch Daemon" }
    let recentlyAddedCount = scannedItems.filter(\.recentlyAdded).count
    let summary = metric(
      "Startup Inventory",
      "\(scannedItems.count)",
      "items",
      .live,
      scannedItems.isEmpty ? .good : .info,
      min(scannedItems.count * 3, 100),
      "Read-only inventory of accessible launch agent and daemon plist files.",
      "LaunchAgents and LaunchDaemons folders",
      "Live / medium",
      "Use the owning app, System Settings, or package manager for changes.",
      now
    )

    return StartupHealth(
      summary: summary,
      metrics: [
        summary,
        metric("Login Items", "Unavailable", "", .unavailable, .info, 0, "Modern login items are not read in this build through a safe public collector.", "Login item collector", "Unavailable / medium", "Review login items in System Settings.", now),
        metric("Launch Agents", "\(launchAgents.count)", "items", .live, launchAgents.isEmpty ? .good : .info, min(launchAgents.count * 4, 100), "Accessible user and system launch agent plist files found by a read-only scan.", "LaunchAgents folders", "Live / medium", "Review labels and owning apps before changing anything.", now),
        metric("Launch Daemons", "\(launchDaemons.count)", "items", .live, launchDaemons.isEmpty ? .good : .info, min(launchDaemons.count * 5, 100), "Accessible system launch daemon plist files found by a read-only scan.", "LaunchDaemons folders", "Live / medium", "Handle daemons carefully and prefer vendor uninstallers.", now),
        metric("Background Items", "Planned", "", .planned, .info, 0, "Background items use newer macOS visibility surfaces that are not integrated yet.", "Background item collector", "Planned / low", "Use System Settings for background item review.", now),
        metric("Privileged Helpers", "Planned", "", .planned, .info, 0, "Privileged helper inventory needs a separate safe collector and clear wording.", "Privileged helper collector", "Planned / low", "Manage helpers through the owning app.", now),
        metric("Code Signing", "Best Effort", "", .live, .info, 0, "Corewise checks executable signatures only when a launch plist points to a readable executable path.", "Security framework", "Live / medium", "Treat unreadable or missing executables as not checked, not suspicious.", now)
      ],
      loginItems: [],
      launchAgents: launchAgents,
      launchDaemons: launchDaemons,
      backgroundItems: [],
      privilegedHelpers: [],
      findings: [
        DiagnosticFinding(
          title: scannedItems.isEmpty ? "No accessible launch items found" : "\(scannedItems.count) launch items found",
          detail: scannedItems.isEmpty ? "Corewise did not find readable launch agent or daemon plist files in the configured folders." : "Corewise lists accessible plist metadata only; presence alone is not a problem.",
          status: scannedItems.isEmpty ? .good : .info,
          severityScore: min(scannedItems.count * 3, 100)
        ),
        DiagnosticFinding(
          title: recentlyAddedCount == 0 ? "No recent launch plist changes found" : "\(recentlyAddedCount) launch plist files changed recently",
          detail: "Recent file modification dates are clues, not proof of startup impact.",
          status: recentlyAddedCount == 0 ? .good : .info,
          severityScore: min(recentlyAddedCount * 8, 100)
        )
      ],
      actions: [
        SafeAction(title: "Review the owning app first", body: "Use app settings, System Settings, or package managers before editing startup files.", systemImage: "app.badge", status: .good),
        SafeAction(title: "Do not remove plist files from Corewise", body: "Corewise only explains startup metadata in this MVP; it does not modify launch files.", systemImage: "lock.shield", status: .info)
      ],
      sourceNote: "Live read-only startup data. Corewise reads accessible LaunchAgents and LaunchDaemons plist metadata and checks executable signatures only when a readable executable path is present. Login items, background items, and privileged helpers remain unavailable or planned."
    )
  }

  private func scan(location: StartupScanLocation, now: Date) -> [StartupItem] {
    guard let urls = try? fileManager.contentsOfDirectory(
      at: location.url,
      includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return urls
      .filter { $0.pathExtension == "plist" }
      .compactMap { item(url: $0, location: location, now: now) }
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  private func item(url: URL, location: StartupScanLocation, now: Date) -> StartupItem? {
    guard let data = try? Data(contentsOf: url),
          let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
          let dictionary = plist as? [String: Any] else {
      return nil
    }

    let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey])
    let modifiedAt = resourceValues?.contentModificationDate
    let recentlyAdded = modifiedAt.map { now.timeIntervalSince($0) <= 14 * 24 * 60 * 60 } ?? false
    let label = (dictionary["Label"] as? String) ?? url.deletingPathExtension().lastPathComponent
    let program = programDescription(dictionary)
    let signedState = executablePath(dictionary).map(signedState(for:)) ?? "Not checked"
    let runAtLoad = dictionary["RunAtLoad"] as? Bool
    let keepAlive = keepAliveDescription(dictionary["KeepAlive"])
    let impact = startupImpact(runAtLoad: runAtLoad, keepAlive: keepAlive)

    return StartupItem(
      title: label,
      kind: location.kind,
      path: displayPath(url),
      startupImpact: impact.label,
      signedState: signedState,
      recentlyAdded: recentlyAdded,
      dataMode: .live,
      status: impact.status,
      severityScore: impact.severityScore + (recentlyAdded ? 8 : 0),
      explanation: "Program: \(program). RunAtLoad: \(boolDescription(runAtLoad)). KeepAlive: \(keepAlive).",
      source: location.displayName,
      confidence: "Live / medium",
      recommendedAction: "Identify the owning app before changing startup behavior.",
      lastUpdated: now
    )
  }

  private func metric(
    _ title: String,
    _ value: String,
    _ unit: String,
    _ dataMode: DataMode,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date
  ) -> DiagnosticMetric {
    DiagnosticMetric(
      title: title,
      value: value,
      unit: unit,
      dataMode: dataMode,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func programDescription(_ dictionary: [String: Any]) -> String {
    if let program = dictionary["Program"] as? String, !program.isEmpty {
      return program
    }

    if let arguments = dictionary["ProgramArguments"] as? [String],
       let first = arguments.first,
       !first.isEmpty {
      return first
    }

    return "Not specified"
  }

  private func executablePath(_ dictionary: [String: Any]) -> String? {
    if let program = dictionary["Program"] as? String, program.hasPrefix("/") {
      return program
    }

    if let arguments = dictionary["ProgramArguments"] as? [String],
       let first = arguments.first,
       first.hasPrefix("/") {
      return first
    }

    return nil
  }

  private func signedState(for path: String) -> String {
    guard fileManager.isReadableFile(atPath: path) else {
      return "Not checked"
    }

    let url = URL(fileURLWithPath: path)
    var staticCode: SecStaticCode?
    let createStatus = SecStaticCodeCreateWithPath(url as CFURL, SecCSFlags(), &staticCode)

    guard createStatus == errSecSuccess, let staticCode else {
      return "Unsigned or unreadable"
    }

    let checkStatus = SecStaticCodeCheckValidityWithErrors(staticCode, SecCSFlags(), nil, nil)
    return checkStatus == errSecSuccess ? "Signed" : "Unsigned or invalid"
  }

  private func keepAliveDescription(_ value: Any?) -> String {
    if let bool = value as? Bool {
      return bool ? "Yes" : "No"
    }

    if value is [String: Any] {
      return "Configured"
    }

    return "No"
  }

  private func boolDescription(_ value: Bool?) -> String {
    guard let value else {
      return "No"
    }
    return value ? "Yes" : "No"
  }

  private func startupImpact(runAtLoad: Bool?, keepAlive: String) -> (label: String, status: FindingSeverity, severityScore: Int) {
    if keepAlive == "Yes" || keepAlive == "Configured" {
      return ("Medium", .info, 34)
    }

    if runAtLoad == true {
      return ("Low", .info, 18)
    }

    return ("Low", .good, 8)
  }

  private func displayPath(_ url: URL) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    if url.path.hasPrefix(home) {
      return "~" + url.path.dropFirst(home.count)
    }
    return url.path
  }
}

struct StartupScanLocation {
  var kind: String
  var displayName: String
  var url: URL

  static func defaultLocations() -> [StartupScanLocation] {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return [
      StartupScanLocation(kind: "Launch Agent", displayName: "User LaunchAgents", url: home.appendingPathComponent("Library/LaunchAgents")),
      StartupScanLocation(kind: "Launch Agent", displayName: "System LaunchAgents", url: URL(fileURLWithPath: "/Library/LaunchAgents")),
      StartupScanLocation(kind: "Launch Daemon", displayName: "System LaunchDaemons", url: URL(fileURLWithPath: "/Library/LaunchDaemons"))
    ]
  }
}
