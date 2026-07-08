import Foundation

struct MockSystemHealthCollector: SystemHealthCollecting {
  func currentSnapshot() async throws -> HealthSnapshot {
    HealthSnapshot(
      generatedAt: Date(),
      overallStatus: .needsAttention,
      battery: BatteryHealth(
        cycleCount: 412,
        maximumCapacityPercent: 87,
        condition: "Normal",
        recentEnergyImpact: "Safari and Xcode used the most energy recently.",
        sourceNote: "Mock data. Real battery health can use safe system power sources and IOKit where permitted."
      ),
      storage: StorageHealth(
        freeSpaceDescription: "84 GB available of 512 GB",
        largeFolders: [
          StorageItem(name: "Developer", detail: "~/Library/Developer", sizeDescription: "42 GB", severity: .warning),
          StorageItem(name: "Movies", detail: "~/Movies", sizeDescription: "31 GB", severity: .info)
        ],
        largeCaches: [
          StorageItem(name: "Xcode Derived Data", detail: "~/Library/Developer/Xcode/DerivedData", sizeDescription: "18 GB", severity: .warning),
          StorageItem(name: "Browser caches", detail: "~/Library/Caches", sizeDescription: "6 GB", severity: .info)
        ],
        hugeFiles: [
          StorageItem(name: "Screen recording", detail: "~/Desktop/demo-recording.mov", sizeDescription: "7.4 GB", severity: .info)
        ],
        sourceNote: "Mock data. Real scanning should stay read-only and ask before traversing sensitive folders."
      ),
      performance: PerformanceHealth(
        cpuProcesses: [
          ProcessSample(name: "Xcode", metric: "31% CPU", detail: "Indexing can temporarily raise CPU usage.", severity: .warning),
          ProcessSample(name: "WindowServer", metric: "12% CPU", detail: "Higher usage can follow external display or animation load.", severity: .info)
        ],
        memoryProcesses: [
          ProcessSample(name: "Safari", metric: "2.4 GB", detail: "Several tabs are active.", severity: .info),
          ProcessSample(name: "Simulator", metric: "1.8 GB", detail: "Running device sessions can be memory-heavy.", severity: .warning)
        ],
        sourceNote: "Mock data. Real process sampling can use public process APIs and Activity Monitor-like summaries."
      ),
      startupItems: [
        StartupItem(name: "Dropbox", location: "Login Items", probableImpact: "Medium", severity: .info),
        StartupItem(name: "Docker", location: "Launch Agent", probableImpact: "High", severity: .warning)
      ],
      thermal: ThermalHealth(
        state: "Nominal",
        detail: "No thermal pressure detected in this mock snapshot.",
        sourceNote: "Mock data. MVP should prefer ProcessInfo thermal state over private temperature sensors.",
        severity: .good
      ),
      crashIssues: [
        CrashIssue(appName: "ExampleApp", countDescription: "3 crashes in 7 days", detail: "Readable only from permitted diagnostic data.", severity: .warning)
      ],
      suggestions: [
        Suggestion(
          title: "Review large developer caches",
          body: "Xcode caches can grow quickly. Corewise should explain the folder and let you open it, not delete it automatically.",
          severity: .warning
        ),
        Suggestion(
          title: "Check heavy login items",
          body: "Apps that start at login can make the Mac feel slower after restart. Disable them from System Settings if you do not need them.",
          severity: .info
        )
      ]
    )
  }
}
