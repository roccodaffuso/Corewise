// SPDX-License-Identifier: MPL-2.0

import Foundation

struct CrashReportDiagnosticsCollector {
  private var fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  func unavailableAppIssues(now: Date) -> AppIssuesHealth {
    let metrics = unavailableMetrics(now: now)
    return AppIssuesHealth(
      summary: metrics[0],
      metrics: metrics,
      crashes: [],
      crashesByApp: [],
      findings: [
        DiagnosticFinding(title: "Diagnostic reports not read yet", detail: "Choose a report folder before Corewise can show crash patterns.", status: .info, severityScore: 0),
        DiagnosticFinding(title: "No app crash rows are invented", detail: "This page stays empty until real report metadata is available.", status: .good, severityScore: 0)
      ],
      actions: [
        SafeAction(title: "Choose reports manually", body: "Use a read-only folder picker when you want Corewise to inspect crash metadata.", systemImage: "folder.badge.questionmark", status: .info),
        SafeAction(title: "Use app updates first", body: "If you already know an app is crashing, update that app before broad troubleshooting.", systemImage: "arrow.down.app", status: .info)
      ],
      sourceNote: "Unavailable data. Corewise reads crash reports only after a user-selected folder scan, so it does not invent crash rows or counts."
    )
  }

  func currentAppIssues(reportDirectory: URL, now: Date) -> AppIssuesHealth {
    let records = readRecords(reportDirectory: reportDirectory, now: now)
    let grouped = Dictionary(grouping: records, by: \.appName)
    let issues = grouped.map { appName, records in
      crashIssue(appName: appName, records: records, now: now)
    }
    .sorted { $0.crashesLast30Days > $1.crashesLast30Days }

    let charts = issues.map {
      ChartDatum(title: $0.appName, value: Double($0.crashesLast30Days), unit: "crashes", dataMode: .live, status: $0.status, detail: $0.bundleID)
    }

    let metrics = liveMetrics(issueCount: issues.count, records: records, now: now)

    return AppIssuesHealth(
      summary: metrics[0],
      metrics: metrics,
      crashes: issues,
      crashesByApp: charts,
      findings: findings(issueCount: issues.count, records: records),
      actions: [
        SafeAction(title: "Update repeated crashers first", body: "Repeated crashes are usually best handled through app updates or vendor support.", systemImage: "arrow.down.app", status: .info),
        SafeAction(title: "Keep reports read-only", body: "Corewise summarizes report metadata and does not erase diagnostic files.", systemImage: "doc.text.magnifyingglass", status: .good)
      ],
      sourceNote: "Live user-selected data. Corewise parsed crash report metadata from a folder chosen by the user and did not load stack traces into the UI."
    )
  }

  private func readRecords(reportDirectory: URL, now: Date) -> [CrashReportRecord] {
    guard let urls = try? fileManager.contentsOfDirectory(
      at: reportDirectory,
      includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    return urls
      .filter { ["crash", "ips", "diag"].contains($0.pathExtension.lowercased()) }
      .compactMap { record(from: $0, now: now) }
  }

  private func record(from url: URL, now: Date) -> CrashReportRecord? {
    guard let handle = try? FileHandle(forReadingFrom: url) else {
      return nil
    }
    defer { try? handle.close() }

    guard let data = try? handle.read(upToCount: 96 * 1024) else {
      return nil
    }

    guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
      return nil
    }

    let fallbackDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? now
    let appName = cleanAppName(firstValue(in: text, prefixes: ["Process:", "\"procName\" : ", "\"procName\":"]) ?? appNameFromFilename(url))
    let bundleID = firstValue(in: text, prefixes: ["Identifier:", "\"bundleID\" : ", "\"bundleID\":"]) ?? "Unavailable"
    let version = firstValue(in: text, prefixes: ["Version:", "\"app_version\" : ", "\"app_version\":"]) ?? "Unavailable"
    let date = crashDate(in: text) ?? fallbackDate

    guard !appName.isEmpty else {
      return nil
    }

    return CrashReportRecord(appName: appName, bundleID: bundleID, appVersion: version, date: date)
  }

  private func crashIssue(appName: String, records: [CrashReportRecord], now: Date) -> CrashIssue {
    let sorted = records.sorted { $0.date > $1.date }
    let latest = sorted.first?.date ?? now
    let crashes7 = records.filter { now.timeIntervalSince($0.date) <= 7 * day }.count
    let crashes30 = records.filter { now.timeIntervalSince($0.date) <= 30 * day }.count
    let repeated = crashes30 >= 2
    let status: FindingSeverity = repeated ? .warning : .info

    return CrashIssue(
      appName: appName,
      bundleID: sorted.first?.bundleID ?? "Unavailable",
      appVersion: sorted.first?.appVersion ?? "Unavailable",
      crashesLast7Days: crashes7,
      crashesLast30Days: crashes30,
      lastCrashDate: latest,
      repeatedCrash: repeated,
      diagnosticPermissionState: "User-selected folder",
      dataMode: .live,
      status: status,
      severityScore: min(crashes30 * 18, 100),
      explanation: repeated ? "This app appears more than once in the selected reports." : "A single crash can be normal; repetition matters more.",
      source: "User-selected crash reports",
      confidence: "Live / medium",
      recommendedAction: "Update or reinstall the owning app before deeper troubleshooting."
    )
  }

  private func unavailableMetrics(now: Date) -> [DiagnosticMetric] {
    [
      metric("Diagnostic Access", "Not Selected", "", .unavailable, .info, 0, "Crash reports are read only after you choose a folder.", "Crash report folder picker", "Unavailable / high", "Choose a reports folder only when you want crash review.", now),
      metric("Crashes Last 7 Days", "Unavailable", "crashes", .unavailable, .info, 0, "Crash counts are unavailable until a report folder is selected.", "Crash report collector", "Unavailable / high", "Use Console if you need crash review before scanning.", now),
      metric("Crashes Last 30 Days", "Unavailable", "crashes", .unavailable, .info, 0, "Crash counts are unavailable until a report folder is selected.", "Crash report collector", "Unavailable / high", "Look for repeated crashes manually only if troubleshooting a specific app.", now),
      metric("Repeated Crash Flag", "Planned", "", .planned, .info, 0, "Repeated crash detection needs real report metadata before it can be trusted.", "Crash pattern collector", "Planned / medium", "Do not treat App Issues as diagnostic until reports are selected.", now)
    ]
  }

  private func liveMetrics(issueCount: Int, records: [CrashReportRecord], now: Date) -> [DiagnosticMetric] {
    let crashes7 = records.filter { now.timeIntervalSince($0.date) <= 7 * day }.count
    let crashes30 = records.filter { now.timeIntervalSince($0.date) <= 30 * day }.count
    let repeatedApps = Dictionary(grouping: records, by: \.appName).values.filter { $0.count >= 2 }.count

    return [
      metric("Diagnostic Access", "Selected", "", .live, .good, 0, "A folder was selected manually for read-only crash metadata parsing.", "User-selected crash reports", "Live / medium", "Use this as troubleshooting context, not cleanup guidance.", now),
      metric("Crashes Last 7 Days", "\(crashes7)", "crashes", .live, crashes7 > 0 ? .info : .good, min(crashes7 * 12, 100), "Crash reports dated within the last 7 days in the selected folder.", "User-selected crash reports", "Live / medium", "Repeated crashes matter more than one report.", now),
      metric("Crashes Last 30 Days", "\(crashes30)", "crashes", .live, crashes30 > 0 ? .info : .good, min(crashes30 * 8, 100), "Crash reports dated within the last 30 days in the selected folder.", "User-selected crash reports", "Live / medium", "Review apps with repeated reports first.", now),
      metric("Repeated Apps", "\(repeatedApps)", "apps", .live, repeatedApps > 0 ? .warning : .good, min(repeatedApps * 24, 100), "\(issueCount) apps appeared in the selected reports.", "Crash pattern collector", "Live / medium", "Update repeated crashers before changing system settings.", now)
    ]
  }

  private func findings(issueCount: Int, records: [CrashReportRecord]) -> [DiagnosticFinding] {
    if records.isEmpty {
      return [
        DiagnosticFinding(title: "No readable reports found", detail: "The selected folder did not contain readable crash, ips, or diagnostic report files.", status: .info, severityScore: 0)
      ]
    }

    let repeated = Dictionary(grouping: records, by: \.appName).values.filter { $0.count >= 2 }.count
    return [
      DiagnosticFinding(title: "\(records.count) reports parsed", detail: "\(issueCount) apps were found in the selected report folder.", status: .info, severityScore: min(records.count * 4, 100)),
      DiagnosticFinding(title: repeated == 0 ? "No repeated crashers found" : "\(repeated) repeated crashers found", detail: "Repeated reports are more useful than isolated one-offs.", status: repeated == 0 ? .good : .warning, severityScore: min(repeated * 24, 100))
    ]
  }

  private func firstValue(in text: String, prefixes: [String]) -> String? {
    for line in text.split(separator: "\n", omittingEmptySubsequences: true).prefix(120) {
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      for prefix in prefixes where trimmed.hasPrefix(prefix) {
        let raw = trimmed.dropFirst(prefix.count)
          .trimmingCharacters(in: CharacterSet(charactersIn: " \t\""))
        let value = raw.split(separator: "\t").first.map(String.init) ?? raw
        return value.trimmingCharacters(in: CharacterSet(charactersIn: " \","))
      }
    }
    return nil
  }

  private func crashDate(in text: String) -> Date? {
    if let value = firstValue(in: text, prefixes: ["Date/Time:", "\"captureTime\" : ", "\"captureTime\":"]) {
      return dateFormatter.date(from: value) ?? isoFormatter.date(from: value)
    }
    return nil
  }

  private func appNameFromFilename(_ url: URL) -> String {
    let name = url.deletingPathExtension().lastPathComponent
    return name.split(separator: "_").first.map(String.init) ?? name
  }

  private func cleanAppName(_ value: String) -> String {
    if let range = value.range(of: " [") {
      return String(value[..<range.lowerBound])
    }
    return value
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

  private let day: TimeInterval = 24 * 60 * 60
  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
    return formatter
  }()
  private let isoFormatter = ISO8601DateFormatter()
}

private struct CrashReportRecord {
  var appName: String
  var bundleID: String
  var appVersion: String
  var date: Date
}
