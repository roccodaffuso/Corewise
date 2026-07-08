import Foundation

struct MockSystemHealthCollector: SystemHealthCollecting {
  func currentSnapshot() async throws -> HealthSnapshot {
    let now = Date()
    let instant = await SystemMetricsSampler.sample()
    let cpuValue = instant.cpuPercent.map { number($0) } ?? "N/A"
    let memoryUsedValue = number(instant.usedMemoryGB)
    let memoryTotalValue = number(instant.totalMemoryGB)
    let memoryPercentValue = number(instant.memoryPercent)

    let batteryMetrics = [
      metric("Charge", "74", "%", .good, 4, "The battery has enough charge for normal work.", "Power source snapshot", "Mock / high", "No action needed right now.", now),
      metric("Cycle Count", "412", "cycles", .info, 28, "Cycle count is moderate for a portable Mac and does not suggest immediate battery risk.", "Battery health report", "Mock / medium", "Watch for faster drain or service warnings over time.", now),
      metric("Maximum Capacity", "87", "%", .info, 34, "Capacity is below new-battery level but still within a normal range.", "Battery health report", "Mock / medium", "Consider service only if runtime feels poor or macOS reports service recommended.", now),
      metric("Condition", "Normal", "", .good, 6, "macOS would not currently flag this battery for service.", "Battery health report", "Mock / medium", "Keep using the Mac normally.", now),
      metric("Power Source", "Battery", "", .info, 15, "The Mac is currently modeled as running on battery power.", "Power source snapshot", "Mock / high", "Connect power before long CPU-heavy work.", now),
      metric("Charging State", "Not Charging", "", .info, 18, "The battery is discharging normally in this snapshot.", "Power source snapshot", "Mock / high", "No action unless this differs from what you expect.", now),
      metric("Recent Energy Impact", "Medium", "", .warning, 55, "Developer tools and browser tabs are the main recent energy users.", "Energy impact sample", "Mock / medium", "Close unused simulators or heavy tabs when working unplugged.", now),
      metric("Battery Risk", "Low", "", .good, 18, "Capacity and cycle count do not point to an urgent issue.", "Corewise score", "Mock / medium", "Recheck after a few charge cycles.", now)
    ]

    let storageMetrics = [
      metric("Total Storage", "512", "GB", .info, 0, "Physical volume size used for the storage estimate.", "Volume capacity", "Mock / high", "No action needed.", now),
      metric("Available", "84", "GB", .warning, 58, "Available space is usable but getting close to the point where updates and large builds can feel constrained.", "Volume capacity", "Mock / high", "Review large developer caches and old downloads.", now),
      metric("Used", "428", "GB", .warning, 58, "Most of the internal drive is already allocated.", "Volume capacity", "Mock / high", "Look at the largest space offenders before deleting anything.", now),
      metric("Available", "16.4", "%", .warning, 58, "Below roughly 20%, macOS and developer tools can have less room for temporary work.", "Corewise threshold", "Mock / high", "Aim for 20-25% free space if possible.", now),
      metric("Downloads", "22", "GB", .info, 35, "Downloads often contain installers and archives that are safe to review manually.", "Folder size estimate", "Mock / medium", "Open Downloads and sort by size/date.", now),
      metric("Trash", "5.8", "GB", .info, 25, "Trash has recoverable space, but Corewise will not empty it automatically.", "Folder size estimate", "Mock / medium", "Review Trash yourself before emptying it.", now),
      metric("iOS Backups", "14", "GB", .warning, 48, "Old device backups can occupy meaningful local space.", "MobileSync estimate", "Mock / medium", "Review backups in Finder or device settings.", now),
      metric("Container Data", "28", "GB", .warning, 62, "Container images and volumes can grow quietly when developer tools are installed.", "Container storage estimate", "Mock / medium", "Use the owning developer tool to review unused images and volumes.", now)
    ]

    let storageBreakdown = [
      ChartDatum(title: "Apps", value: 74, unit: "GB", status: .info, detail: "Installed applications"),
      ChartDatum(title: "User Files", value: 196, unit: "GB", status: .info, detail: "Documents, media, desktop files"),
      ChartDatum(title: "Developer", value: 92, unit: "GB", status: .warning, detail: "Xcode, simulators, containers"),
      ChartDatum(title: "Caches", value: 38, unit: "GB", status: .warning, detail: "App, browser, and build caches"),
      ChartDatum(title: "System", value: 28, unit: "GB", status: .good, detail: "macOS and system data"),
      ChartDatum(title: "Available", value: 84, unit: "GB", status: .good, detail: "Free space")
    ]

    let largeFolders = [
      storageItem("Developer", "~/Library/Developer", 42, .warning, 64, "Developer data is the largest folder group in this mock scan.", "Folder scan", "Mock / medium", "Open the folder and review DerivedData, Archives, and simulators.", now),
      storageItem("Movies", "~/Movies", 31, .info, 34, "Media files are large but usually user-owned and intentional.", "Folder scan", "Mock / medium", "Sort by size and archive old exports if you no longer need them.", now),
      storageItem("Downloads", "~/Downloads", 22, .info, 35, "Downloads are a common place for forgotten installers and archives.", "Folder scan", "Mock / medium", "Review manually before removing anything.", now)
    ]

    let developerCaches = [
      storageItem("Xcode DerivedData", "~/Library/Developer/Xcode/DerivedData", 18, .warning, 60, "DerivedData can grow quickly and slow indexing when stale.", "Folder estimate", "Mock / medium", "Use Xcode or Finder to review old project caches.", now),
      storageItem("Simulators", "~/Library/Developer/CoreSimulator", 21, .warning, 66, "Simulator runtimes and device data can be heavy.", "Folder estimate", "Mock / medium", "Remove unused simulator devices from Xcode when ready.", now),
      storageItem("Archives", "~/Library/Developer/Xcode/Archives", 9.5, .info, 32, "Old app archives take space but may be needed for release history.", "Folder estimate", "Mock / medium", "Keep recent releases and archive or delete older ones manually.", now)
    ]

    let browserCaches = [
      storageItem("Safari Cache", "~/Library/Caches/com.apple.Safari", 3.2, .info, 22, "Browser caches are normal and often self-managed.", "Folder estimate", "Mock / low", "Clear from browser settings only if troubleshooting.", now),
      storageItem("Chrome Cache", "~/Library/Caches/Google/Chrome", 4.8, .info, 28, "Chrome cache is noticeable but not alarming.", "Folder estimate", "Mock / low", "Review through Chrome settings if needed.", now)
    ]

    let largeFiles = [
      storageItem("Screen recording", "~/Desktop/demo-recording.mov", 7.4, .info, 30, "Large video exports are easy to identify and move.", "File scan", "Mock / medium", "Open in Finder and decide whether to archive it.", now),
      storageItem("VM disk image", "~/Documents/VMs/test-machine.qcow2", 16, .warning, 54, "Virtual machine disk images can expand quietly.", "File scan", "Mock / medium", "Review whether the VM is still needed.", now)
    ]

    let performanceMetrics = [
      metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpuPercent), cpuSeverity(instant.cpuPercent), "Instant CPU load sampled over a short window from macOS CPU ticks.", "host_statistics CPU_LOAD_INFO", "Live / medium", "Watch sustained high CPU, not a single short spike.", now),
      metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "\(memoryUsedValue) GB of \(memoryTotalValue) GB physical memory is actively used or compressed.", "host_statistics64 VM_INFO64", "Live / medium", "Close heavy apps only if memory pressure or swap also stays high.", now),
      metric("RAM Used Now", memoryPercentValue, "%", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "This is an instant memory-use estimate from active, wired, and compressed pages.", "host_statistics64 VM_INFO64", "Live / medium", "Use this as a direction signal rather than an exact Activity Monitor duplicate.", now),
      metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Live / high", "Use wattage later only if Corewise can obtain it through a safe, user-approved path.", now),
      metric("Memory Pressure", "Moderate", "", .warning, 58, "The Mac has enough memory, but swap and large apps suggest pressure during heavier work.", "Activity sample", "Mock / medium", "Close unused simulators or browser windows before heavy builds.", now),
      metric("Swap Used", "3.1", "GB", .warning, 56, "Swap means macOS is using disk as overflow memory; occasional use is normal, sustained high use can feel slow.", "VM statistics", "Mock / medium", "Watch whether this stays high after closing heavy apps.", now),
      metric("Uptime", "9", "days", .info, 24, "Long uptime is fine, but a restart can clear stuck background work.", "System uptime", "Mock / high", "Restart only if performance feels unusually degraded.", now),
      metric("Sustained High CPU", "18", "min", .warning, 52, "CPU has been elevated long enough to affect battery and heat.", "Process sampling window", "Mock / low", "Check whether indexing, builds, or background tasks are expected.", now),
      metric("WindowServer Impact", "Elevated", "", .info, 38, "WindowServer usage is higher with external displays, screen recording, or many animated windows.", "Process sample", "Mock / medium", "Close unneeded display-heavy apps if UI feels sluggish.", now)
    ]

    let fallbackCPUProcesses = [
      process("Xcode", 31, "% CPU", .warning, 60, "Indexing and builds are currently the largest CPU source.", "Process sample", "Mock / medium", "Let indexing finish or pause heavy builds on battery.", now),
      process("WindowServer", 12, "% CPU", .info, 34, "Window drawing is noticeable but not critical.", "Process sample", "Mock / medium", "Reduce display-heavy work if animations stutter.", now),
      process("Safari", 8, "% CPU", .info, 20, "A few tabs are active.", "Process sample", "Mock / medium", "Close video or heavy web apps if needed.", now)
    ]
    let cpuProcesses = instant.topCPUProcesses.isEmpty ? fallbackCPUProcesses : instant.topCPUProcesses

    let fallbackMemoryProcesses = [
      process("Safari", 2.4, "GB", .info, 36, "Several tabs are active and using memory.", "Process sample", "Mock / medium", "Close unused tabs or windows.", now),
      process("Simulator", 1.8, "GB", .warning, 48, "Simulator sessions are memory-heavy.", "Process sample", "Mock / medium", "Quit unused simulator devices.", now),
      process("Xcode", 1.6, "GB", .info, 35, "Expected for a large workspace.", "Process sample", "Mock / medium", "No action unless memory pressure rises.", now),
    ]
    let memoryProcesses = instant.topMemoryProcesses.isEmpty ? fallbackMemoryProcesses : instant.topMemoryProcesses

    let startupMetrics = [
      metric("Login Items", "5", "items", .info, 32, "A few apps start when you sign in.", "Login item list", "Mock / medium", "Keep the ones you use every day.", now),
      metric("Launch Agents", "14", "items", .warning, 54, "Launch agents can run background work for user apps.", "LaunchAgents folders", "Mock / medium", "Review recently added agents first.", now),
      metric("Launch Daemons", "6", "items", .info, 36, "Daemons are system-wide services and should be handled carefully.", "LaunchDaemons folders", "Mock / low", "Do not remove daemons manually unless you know the vendor.", now),
      metric("Privileged Helpers", "2", "helpers", .warning, 57, "Privileged helpers can run with elevated capabilities.", "Helper tool folders", "Mock / low", "Prefer uninstallers or vendor settings.", now),
      metric("Recently Added", "3", "items", .warning, 48, "Recent startup additions are useful suspects when boot feels slower.", "File metadata", "Mock / low", "Review apps installed in the last week.", now)
    ]

    let loginItems = [
      startupItem("Dropbox", "Login Item", "System Settings > Login Items", "Medium", "Signed", false, .info, 28, "Cloud sync can add startup activity.", "Login items", "Mock / medium", "Disable only if you do not need sync at sign-in.", now),
      startupItem("Developer Helper", "Login Item", "/Applications/ExampleDeveloperTool.app", "Medium", "Signed", true, .info, 34, "Developer tools can start background helpers after login.", "Login items", "Mock / medium", "Start developer tools manually when you need them.", now)
    ]

    let launchAgents = [
      startupItem("Homebrew Services", "Launch Agent", "~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist", "Medium", "Unsigned plist", true, .warning, 50, "Developer services can run even when forgotten.", "LaunchAgents", "Mock / low", "Use `brew services` to review; do not delete plist files blindly.", now),
      startupItem("Rectangle", "Launch Agent", "~/Library/LaunchAgents/com.knollsoft.Rectangle.plist", "Low", "Signed", false, .good, 10, "Window management helper with low expected impact.", "LaunchAgents", "Mock / low", "No action needed if you use it.", now)
    ]

    let thermalMetrics = [
      metric("Thermal State", "Nominal", "", .good, 8, "macOS is not reporting thermal pressure in this snapshot.", "ProcessInfo.thermalState", "Mock / high", "No action needed.", now),
      metric("Low Power Mode", "Off", "", .info, 12, "Low Power Mode is not modeled as active.", "Power settings", "Mock / medium", "Turn it on manually when battery life matters more than peak speed.", now),
      metric("Likely Contributors", "Xcode, builds", "", .warning, 44, "Current heat contributors are likely CPU-heavy developer tools.", "Process correlation", "Mock / low", "Let builds finish or pause background work if fans stay loud.", now)
    ]

    let issueMetrics = [
      metric("Diagnostic Access", "Limited", "", .info, 20, "Corewise can explain crash patterns only from data macOS allows it to read.", "Permission state", "Mock / medium", "Grant access only if you want deeper diagnostics later.", now),
      metric("Crashes Last 7 Days", "6", "crashes", .warning, 52, "One app appears to be failing repeatedly this week.", "Diagnostic reports", "Mock / medium", "Update or reinstall the repeated-crash app first.", now),
      metric("Crashes Last 30 Days", "14", "crashes", .warning, 46, "Crash volume is noticeable but not system-wide critical.", "Diagnostic reports", "Mock / medium", "Look for repeated bundle IDs rather than one-off crashes.", now),
      metric("Repeated Crash Flag", "Yes", "", .warning, 60, "At least one app has multiple recent crashes.", "Corewise score", "Mock / medium", "Focus on the repeated app before broad troubleshooting.", now)
    ]

    let crashes = [
      crash("ExampleApp", "com.example.ExampleApp", "3.4.1", 3, 7, daysAgo(1), true, "Limited", .warning, 60, "This app has repeated crashes and is the clearest issue.", "Diagnostic reports", "Mock / medium", "Update the app, then relaunch and watch whether crashes stop."),
      crash("PhotoTool", "com.vendor.PhotoTool", "9.2", 2, 4, daysAgo(3), false, "Limited", .info, 32, "Crashes are present but not yet clearly repeated.", "Diagnostic reports", "Mock / medium", "Check for an update if you rely on it."),
      crash("HelperService", "com.vendor.HelperService", "1.8", 1, 3, daysAgo(6), false, "Limited", .info, 28, "Background helper crashes can come from stale vendor services.", "Diagnostic reports", "Mock / low", "Use the vendor app or uninstaller rather than deleting helpers.")
    ]

    return HealthSnapshot(
      generatedAt: now,
      healthScore: 74,
      overallStatus: .needsAttention,
      overviewMetrics: [
        metric("Health Score", "74", "/100", .warning, 42, "Corewise sees a mostly healthy Mac with storage and background activity worth reviewing.", "Corewise scoring model", "Mock / medium", "Start with storage and startup items; no destructive action needed.", now),
        metric("CPU Now", cpuValue, "%", cpuStatus(instant.cpuPercent), cpuSeverity(instant.cpuPercent), "Live CPU usage sampled from macOS CPU ticks.", "host_statistics CPU_LOAD_INFO", "Live / medium", "Refresh or wait a few seconds to see whether this is sustained.", now),
        metric("RAM Used Now", memoryUsedValue, "GB", memoryStatus(instant.memoryPercent), memorySeverity(instant.memoryPercent), "\(memoryPercentValue)% of physical memory is estimated as active, wired, or compressed.", "host_statistics64 VM_INFO64", "Live / medium", "Check memory pressure before blaming a single app.", now),
        metric("System Power", "N/A", "W", .info, 0, instant.powerSourceNote, "Safe public API check", "Live / high", "Do not show private-sensor wattage or sudo-only readings in the MVP.", now),
        metric("Main Attention Area", "Storage", "", .warning, 58, "Available space is the strongest current signal.", "Corewise scoring model", "Mock / medium", "Review largest space offenders manually.", now),
        metric("Data Mode", "Mock", "", .info, 0, "This build uses realistic mock data until safe collectors are implemented.", "App build", "High", "Treat values as UI/product scaffolding, not real device diagnostics.", now)
      ],
      battery: BatteryHealth(
        summary: batteryMetrics[7],
        metrics: batteryMetrics,
        findings: [
          DiagnosticFinding(title: "Battery looks serviceable", detail: "Cycle count and capacity do not suggest urgent service.", status: .good, severityScore: 18),
          DiagnosticFinding(title: "Energy use is worth watching", detail: "Recent developer and browser activity can reduce runtime on battery.", status: .warning, severityScore: 55)
        ],
        actions: [
          SafeAction(title: "Review energy-heavy apps", body: "Use Activity Monitor's Energy tab when working unplugged.", systemImage: "bolt.horizontal", status: .info),
          SafeAction(title: "Avoid battery-service claims", body: "Corewise should only explain battery signals and point to macOS service status.", systemImage: "checkmark.shield", status: .good)
        ],
        sourceNote: "Mock data. Real battery metrics should come from safe power-source APIs and documented macOS battery health surfaces where available."
      ),
      storage: StorageHealth(
        summary: storageMetrics[1],
        totalGB: 512,
        availableGB: 84,
        usedGB: 428,
        availablePercent: 16.4,
        metrics: storageMetrics,
        breakdown: storageBreakdown,
        largeFolders: largeFolders,
        largeFiles: largeFiles,
        developerCaches: developerCaches,
        browserCaches: browserCaches,
        spaceOffenders: [
          ChartDatum(title: "Developer", value: 42, unit: "GB", status: .warning, detail: "~/Library/Developer"),
          ChartDatum(title: "Container Data", value: 28, unit: "GB", status: .warning, detail: "Container images and volumes"),
          ChartDatum(title: "Downloads", value: 22, unit: "GB", status: .info, detail: "~/Downloads"),
          ChartDatum(title: "Simulators", value: 21, unit: "GB", status: .warning, detail: "CoreSimulator"),
          ChartDatum(title: "VM Disk", value: 16, unit: "GB", status: .warning, detail: "Virtual machine disk image"),
          ChartDatum(title: "iOS Backups", value: 14, unit: "GB", status: .warning, detail: "MobileSync backups")
        ],
        findings: [
          DiagnosticFinding(title: "Free space is below comfort range", detail: "16.4% free is workable, but large builds and macOS updates have less room.", status: .warning, severityScore: 58),
          DiagnosticFinding(title: "Developer data is the biggest clear category", detail: "Xcode, simulators, and container data account for several top offenders.", status: .warning, severityScore: 64)
        ],
        actions: [
          SafeAction(title: "Open folders, do not auto-delete", body: "Corewise should help you inspect large folders and files without removing anything automatically.", systemImage: "folder", status: .good),
          SafeAction(title: "Use vendor tools for caches", body: "Use Xcode or browser settings for cleanup so each app stays consistent.", systemImage: "wrench.and.screwdriver", status: .info)
        ],
        sourceNote: "Mock data. Real storage scanning must stay read-only, avoid hidden destructive cleanup, and explain permission-limited folders clearly."
      ),
      performance: PerformanceHealth(
        summary: performanceMetrics[0],
        metrics: performanceMetrics,
        cpuProcesses: cpuProcesses,
        memoryProcesses: memoryProcesses,
        findings: [
          DiagnosticFinding(title: "Live process ranking is available", detail: "Top CPU and memory charts are now based on short per-process samples when macOS returns process data.", status: .info, severityScore: 24),
          DiagnosticFinding(title: "Sustained usage matters most", detail: "A process that appears once is not automatically a problem; repeated high values across refreshes are more meaningful.", status: .info, severityScore: 30)
        ],
        actions: [
          SafeAction(title: "Pause unused development services", body: "Stop containers and simulators you are not actively using.", systemImage: "pause.circle", status: .info),
          SafeAction(title: "Restart only when symptoms persist", body: "A restart can clear stuck work, but Corewise should not present it as a magic fix.", systemImage: "power", status: .info)
        ],
        sourceNote: "Mock data. Real performance collectors should sample public process information and present approximations honestly."
      ),
      startup: StartupHealth(
        summary: startupMetrics[1],
        metrics: startupMetrics,
        loginItems: loginItems,
        launchAgents: launchAgents,
        launchDaemons: [
          startupItem("Vendor Licensing Service", "Launch Daemon", "/Library/LaunchDaemons/com.vendor.licensing.plist", "Medium", "Signed", false, .info, 35, "Some pro apps install licensing daemons.", "LaunchDaemons", "Mock / low", "Use the vendor uninstaller if you no longer need it.", now)
        ],
        backgroundItems: [
          startupItem("Adobe Background Service", "Background Item", "System Settings > Login Items", "Medium", "Signed", true, .info, 38, "Background services support updates and sync.", "Background items", "Mock / low", "Disable from System Settings only if you understand the tradeoff.", now)
        ],
        privilegedHelpers: [
          startupItem("Developer Privileged Helper", "Privileged Helper", "/Library/PrivilegedHelperTools/com.example.helper", "High", "Signed", true, .warning, 57, "Some developer tools install helpers for networking or virtualization features.", "Privileged helpers", "Mock / low", "Manage helpers through the owning app, not by deleting helper files.", now)
        ],
        findings: [
          DiagnosticFinding(title: "A few recent startup items deserve review", detail: "Developer helpers and a Homebrew service are plausible startup-impact sources.", status: .warning, severityScore: 54),
          DiagnosticFinding(title: "Signed does not mean lightweight", detail: "Signed items can still have startup impact; unsigned plist metadata only changes trust confidence.", status: .info, severityScore: 26)
        ],
        actions: [
          SafeAction(title: "Use System Settings first", body: "Disable login and background items from macOS settings where possible.", systemImage: "gearshape", status: .good),
          SafeAction(title: "Avoid deleting launch files manually", body: "Launch agents and daemons should be changed through app settings, package managers, or uninstallers.", systemImage: "lock.shield", status: .warning)
        ],
        sourceNote: "Mock data. Real startup diagnostics should explain visibility limits and avoid offering raw file deletion as an MVP action."
      ),
      thermal: ThermalHealth(
        summary: thermalMetrics[0],
        metrics: thermalMetrics,
        contributors: [
          DiagnosticFinding(title: "Thermal state is nominal", detail: "The safe public signal does not indicate throttling.", status: .good, severityScore: 8),
          DiagnosticFinding(title: "Temperature sensors are intentionally absent", detail: "Corewise should not rely on private sensor APIs for a consumer MVP.", status: .info, severityScore: 12),
          DiagnosticFinding(title: "CPU-heavy tools can still create heat", detail: "Xcode, builds, and background developer tasks are likely contributors if fans are audible.", status: .warning, severityScore: 44)
        ],
        actions: [
          SafeAction(title: "Trust macOS thermal pressure", body: "Use ProcessInfo thermal state for safe high-level thermal status.", systemImage: "thermometer.medium", status: .good),
          SafeAction(title: "Reduce sustained load", body: "Pause long builds or containers if the Mac feels hot for a long period.", systemImage: "speedometer", status: .info)
        ],
        sourceNote: "Mock data. Real thermal basics should prefer ProcessInfo.thermalState and avoid private temperature sensor claims."
      ),
      appIssues: AppIssuesHealth(
        summary: issueMetrics[1],
        metrics: issueMetrics,
        crashes: crashes,
        crashesByApp: crashes.map {
          ChartDatum(title: $0.appName, value: Double($0.crashesLast30Days), unit: "crashes", status: $0.status, detail: $0.bundleID)
        },
        findings: [
          DiagnosticFinding(title: "One repeated-crash app stands out", detail: "ExampleApp accounts for half of the recent mock crash volume.", status: .warning, severityScore: 60),
          DiagnosticFinding(title: "Crash data may be permission-limited", detail: "Corewise should disclose when diagnostic reports are incomplete or unavailable.", status: .info, severityScore: 20)
        ],
        actions: [
          SafeAction(title: "Update the repeated-crash app", body: "Start with the app that repeats, not broad system cleanup.", systemImage: "arrow.down.app", status: .info),
          SafeAction(title: "Do not erase logs automatically", body: "Diagnostic data should be read to explain patterns, not cleaned away.", systemImage: "doc.text.magnifyingglass", status: .good)
        ],
        sourceNote: "Mock data. Real crash diagnostics should read only permitted diagnostic reports and clearly show permission state."
      ),
      suggestions: [
        Suggestion(title: "Review large developer storage", body: "Xcode, simulators, and container data explain the clearest space pressure in this snapshot.", severity: .warning),
        Suggestion(title: "Check startup items added recently", body: "Recent background items are better suspects than long-standing trusted utilities.", severity: .warning),
        Suggestion(title: "Treat values as diagnostic context", body: "Corewise explains what is likely happening and leaves all cleanup decisions to you.", severity: .good)
      ]
    )
  }

  private func metric(
    _ title: String,
    _ value: String,
    _ unit: String,
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
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func storageItem(
    _ title: String,
    _ path: String,
    _ sizeGB: Double,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date
  ) -> StorageItem {
    StorageItem(
      title: title,
      path: path,
      sizeGB: sizeGB,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func process(
    _ name: String,
    _ value: Double,
    _ unit: String,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date
  ) -> ProcessSample {
    ProcessSample(
      name: name,
      value: value,
      unit: unit,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func startupItem(
    _ title: String,
    _ kind: String,
    _ path: String,
    _ startupImpact: String,
    _ signedState: String,
    _ recentlyAdded: Bool,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String,
    _ lastUpdated: Date
  ) -> StartupItem {
    StartupItem(
      title: title,
      kind: kind,
      path: path,
      startupImpact: startupImpact,
      signedState: signedState,
      recentlyAdded: recentlyAdded,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction,
      lastUpdated: lastUpdated
    )
  }

  private func crash(
    _ appName: String,
    _ bundleID: String,
    _ appVersion: String,
    _ crashesLast7Days: Int,
    _ crashesLast30Days: Int,
    _ lastCrashDate: Date,
    _ repeatedCrash: Bool,
    _ diagnosticPermissionState: String,
    _ status: FindingSeverity,
    _ severityScore: Int,
    _ explanation: String,
    _ source: String,
    _ confidence: String,
    _ recommendedAction: String
  ) -> CrashIssue {
    CrashIssue(
      appName: appName,
      bundleID: bundleID,
      appVersion: appVersion,
      crashesLast7Days: crashesLast7Days,
      crashesLast30Days: crashesLast30Days,
      lastCrashDate: lastCrashDate,
      repeatedCrash: repeatedCrash,
      diagnosticPermissionState: diagnosticPermissionState,
      status: status,
      severityScore: severityScore,
      explanation: explanation,
      source: source,
      confidence: confidence,
      recommendedAction: recommendedAction
    )
  }

  private func daysAgo(_ days: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
  }

  private func number(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value))
    }
    return String(format: "%.1f", value)
  }

  private func cpuStatus(_ percent: Double?) -> FindingSeverity {
    guard let percent else {
      return .info
    }
    if percent >= 90 {
      return .critical
    }
    if percent >= 65 {
      return .warning
    }
    if percent >= 35 {
      return .info
    }
    return .good
  }

  private func cpuSeverity(_ percent: Double?) -> Int {
    guard let percent else {
      return 0
    }
    return min(max(Int(percent.rounded()), 0), 100)
  }

  private func memoryStatus(_ percent: Double) -> FindingSeverity {
    if percent >= 90 {
      return .critical
    }
    if percent >= 75 {
      return .warning
    }
    if percent >= 55 {
      return .info
    }
    return .good
  }

  private func memorySeverity(_ percent: Double) -> Int {
    min(max(Int(percent.rounded()), 0), 100)
  }
}
