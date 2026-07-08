import Darwin.Mach
import Foundation

struct InstantSystemMetrics {
  var cpuPercent: Double?
  var usedMemoryGB: Double
  var totalMemoryGB: Double
  var memoryPercent: Double
  var topCPUProcesses: [ProcessSample]
  var topMemoryProcesses: [ProcessSample]
  var systemWatts: Double?
  var powerSourceNote: String
}

enum SystemMetricsSampler {
  static func sample() async -> InstantSystemMetrics {
    async let cpu = sampleCPUPercent()
    async let processes = sampleProcesses()
    let memory = sampleMemory()

    return await InstantSystemMetrics(
      cpuPercent: cpu,
      usedMemoryGB: memory.usedGB,
      totalMemoryGB: memory.totalGB,
      memoryPercent: memory.percent,
      topCPUProcesses: processes.cpu,
      topMemoryProcesses: processes.memory,
      systemWatts: nil,
      powerSourceNote: "macOS does not expose reliable whole-system wattage through a safe public API. Corewise can show battery or power-source context later, but should not invent watts."
    )
  }

  private static func sampleCPUPercent() async -> Double? {
    guard let first = cpuTicks() else {
      return nil
    }

    try? await Task.sleep(nanoseconds: 250_000_000)

    guard let second = cpuTicks() else {
      return nil
    }

    let userDelta = second.user - first.user
    let systemDelta = second.system - first.system
    let niceDelta = second.nice - first.nice
    let idleDelta = second.idle - first.idle
    let totalDelta = userDelta + systemDelta + niceDelta + idleDelta

    guard totalDelta > 0 else {
      return nil
    }

    let activeDelta = totalDelta - idleDelta
    return Double(activeDelta) / Double(totalDelta) * 100
  }

  private static func cpuTicks() -> CPUTicks? {
    var info = host_cpu_load_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)

    let result = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
      }
    }

    guard result == KERN_SUCCESS else {
      return nil
    }

    return CPUTicks(
      user: UInt64(info.cpu_ticks.0),
      system: UInt64(info.cpu_ticks.1),
      idle: UInt64(info.cpu_ticks.2),
      nice: UInt64(info.cpu_ticks.3)
    )
  }

  private static func sampleMemory() -> (usedGB: Double, totalGB: Double, percent: Double) {
    let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
    let pageSize = Double(vmPageSize())

    var stats = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

    let result = withUnsafeMutablePointer(to: &stats) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
        host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
      }
    }

    guard result == KERN_SUCCESS, totalBytes > 0 else {
      let totalGB = totalBytes / bytesPerGB
      return (0, totalGB, 0)
    }

    let usedPages = Double(stats.active_count + stats.wire_count + stats.compressor_page_count)
    let usedBytes = min(usedPages * pageSize, totalBytes)
    let usedGB = usedBytes / bytesPerGB
    let totalGB = totalBytes / bytesPerGB
    let percent = usedBytes / totalBytes * 100

    return (usedGB, totalGB, percent)
  }

  private static func sampleProcesses() async -> (cpu: [ProcessSample], memory: [ProcessSample]) {
    let first = processStats()
    let start = Date()

    try? await Task.sleep(nanoseconds: 350_000_000)

    let second = processStats()
    let elapsed = max(Date().timeIntervalSince(start), 0.1)
    let now = Date()

    var cpuByProcess: [String: ProcessAggregate] = [:]

    for (pid, current) in second {
      guard shouldIncludeProcess(current), let previous = first[pid] else {
        continue
      }

      let displayName = normalizedProcessName(current)
      guard !displayName.isEmpty else {
        continue
      }

      let deltaNanoseconds = current.cpuNanoseconds > previous.cpuNanoseconds
        ? current.cpuNanoseconds - previous.cpuNanoseconds
        : 0
      let cpuPercent = Double(deltaNanoseconds) / 1_000_000_000 / elapsed * 100

      guard cpuPercent >= 0.05 else {
        continue
      }

      cpuByProcess[displayName, default: ProcessAggregate(name: displayName, value: 0)].value += cpuPercent
    }

    let cpuSamples = cpuByProcess.values.map { aggregate in
      ProcessSample(
        name: aggregate.name,
        value: aggregate.value,
        unit: "% CPU",
        status: cpuProcessStatus(aggregate.value),
        severityScore: severity(aggregate.value),
        explanation: "Live CPU usage over the last short sampling window.",
        source: "proc_pidinfo PROC_PIDTASKINFO",
        confidence: "Live / medium",
        recommendedAction: "If this process stays high across refreshes, inspect it before quitting anything.",
        lastUpdated: now
      )
    }
    .sorted { $0.value > $1.value }
    .prefix(8)

    var memoryByProcess: [String: ProcessAggregate] = [:]

    for stat in second.values where shouldIncludeProcess(stat) && stat.residentBytes > 0 {
      let displayName = normalizedProcessName(stat)
      guard !displayName.isEmpty else {
        continue
      }

      let memoryGB = Double(stat.residentBytes) / bytesPerGB
      memoryByProcess[displayName, default: ProcessAggregate(name: displayName, value: 0)].value += memoryGB
    }

    let memorySamples = memoryByProcess.values
      .sorted { $0.value > $1.value }
      .prefix(8)
      .map { aggregate in
        ProcessSample(
          name: aggregate.name,
          value: aggregate.value,
          unit: "GB",
          status: memoryProcessStatus(aggregate.value),
          severityScore: severity(aggregate.value * 20),
          explanation: "Resident memory currently held by this process group.",
          source: "proc_pidinfo PROC_PIDTASKINFO",
          confidence: "Live / medium",
          recommendedAction: "Use this with memory pressure; high RAM alone is not automatically bad.",
          lastUpdated: now
        )
      }

    return (Array(cpuSamples), Array(memorySamples))
  }

  private static func shouldIncludeProcess(_ stat: ProcessStat) -> Bool {
    let currentPID = pid_t(ProcessInfo.processInfo.processIdentifier)
    let name = normalizedProcessName(stat)

    return stat.pid != currentPID && name != "Corewise"
  }

  private static func normalizedProcessName(_ stat: ProcessStat) -> String {
    if let appName = appBundleName(from: stat.path) {
      return appName
    }

    return normalizedProcessName(stat.name)
  }

  private static func appBundleName(from path: String?) -> String? {
    guard let path else {
      return nil
    }

    let components = path.split(separator: "/")
    guard let appComponent = components.first(where: { $0.hasSuffix(".app") }) else {
      return nil
    }

    let appName = appComponent.dropLast(4)
    return appName.isEmpty ? nil : String(appName)
  }

  private static func normalizedProcessName(_ rawName: String) -> String {
    let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

    if name.isEmpty {
      return ""
    }

    if name.localizedCaseInsensitiveContains("Google Chrome") {
      return "Google Chrome"
    }

    if name.localizedCaseInsensitiveContains("Safari") && name.localizedCaseInsensitiveContains("Web") {
      return "Safari"
    }

    if name.localizedCaseInsensitiveContains("Firefox") {
      return "Firefox"
    }

    if name.localizedCaseInsensitiveContains("Microsoft Edge") {
      return "Microsoft Edge"
    }

    if name.localizedCaseInsensitiveContains("Code Helper") {
      return "Visual Studio Code"
    }

    if name.localizedCaseInsensitiveContains("Electron") {
      return "Electron App"
    }

    if let helperRange = name.range(of: " Helper") {
      return String(name[..<helperRange.lowerBound])
    }

    if let parenRange = name.range(of: " (") {
      return String(name[..<parenRange.lowerBound])
    }

    return name
  }

  private static func processStats() -> [Int32: ProcessStat] {
    let pidCount = proc_listallpids(nil, 0)
    guard pidCount > 0 else {
      return [:]
    }

    var pids = Array(repeating: pid_t(0), count: Int(pidCount))
    let bytes = pids.count * MemoryLayout<pid_t>.stride
    let actualBytes = pids.withUnsafeMutableBytes { buffer in
      proc_listallpids(buffer.baseAddress, Int32(bytes))
    }
    let actualCount = max(0, Int(actualBytes) / MemoryLayout<pid_t>.stride)
    var stats: [Int32: ProcessStat] = [:]

    for pid in pids.prefix(actualCount) where pid > 0 {
      var taskInfo = proc_taskinfo()
      let infoSize = MemoryLayout<proc_taskinfo>.stride
      let result = withUnsafeMutablePointer(to: &taskInfo) { pointer in
        pointer.withMemoryRebound(to: UInt8.self, capacity: infoSize) { reboundPointer in
          proc_pidinfo(pid, PROC_PIDTASKINFO, 0, reboundPointer, Int32(infoSize))
        }
      }

      guard result == Int32(infoSize) else {
        continue
      }

      let name = processName(pid: pid)
      let path = processPath(pid: pid)
      let cpuNanoseconds = taskInfo.pti_total_user + taskInfo.pti_total_system
      let residentBytes = UInt64(taskInfo.pti_resident_size)

      stats[pid] = ProcessStat(
        pid: pid,
        name: name,
        path: path,
        cpuNanoseconds: cpuNanoseconds,
        residentBytes: residentBytes
      )
    }

    return stats
  }

  private static func processName(pid: pid_t) -> String {
    var buffer = [CChar](repeating: 0, count: Int(2 * MAXCOMLEN))
    let capacity = UInt32(buffer.count)
    let count = buffer.withUnsafeMutableBufferPointer { pointer in
      proc_name(pid, pointer.baseAddress, capacity)
    }

    if count > 0 {
      return String(cString: buffer)
    }

    return "pid \(pid)"
  }

  private static func processPath(pid: pid_t) -> String? {
    var buffer = [CChar](repeating: 0, count: 4096)
    let capacity = UInt32(buffer.count)
    let count = buffer.withUnsafeMutableBufferPointer { pointer in
      proc_pidpath(pid, pointer.baseAddress, capacity)
    }

    guard count > 0 else {
      return nil
    }

    return String(cString: buffer)
  }

  private static func cpuProcessStatus(_ percent: Double) -> FindingSeverity {
    if percent >= 200 {
      return .critical
    }
    if percent >= 75 {
      return .warning
    }
    if percent >= 25 {
      return .info
    }
    return .good
  }

  private static func memoryProcessStatus(_ gb: Double) -> FindingSeverity {
    if gb >= 8 {
      return .critical
    }
    if gb >= 3 {
      return .warning
    }
    if gb >= 1 {
      return .info
    }
    return .good
  }

  private static func severity(_ value: Double) -> Int {
    min(max(Int(value.rounded()), 0), 100)
  }

  private static func vmPageSize() -> vm_size_t {
    var size: vm_size_t = 0
    host_page_size(mach_host_self(), &size)
    return size
  }

  private static let bytesPerGB = 1024.0 * 1024.0 * 1024.0
}

private struct CPUTicks {
  var user: UInt64
  var system: UInt64
  var idle: UInt64
  var nice: UInt64
}

private struct ProcessStat {
  var pid: pid_t
  var name: String
  var path: String?
  var cpuNanoseconds: UInt64
  var residentBytes: UInt64
}

private struct ProcessAggregate {
  var name: String
  var value: Double
}
