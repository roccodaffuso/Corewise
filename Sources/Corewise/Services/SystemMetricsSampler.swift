import Darwin
import Darwin.Mach
import Foundation

struct InstantSystemMetrics {
  var cpu: SystemCPUReading
  var memory: SystemMemoryReading
  var processes: [ProcessObservation]
  var appGroups: [AppProcessGroup]
  var systemWatts: Double?
  var powerSourceNote: String
}

enum SystemMetricsSampler {
  static func sample() async -> InstantSystemMetrics {
    async let cpu = sampleCPU()
    async let processSample = sampleProcesses()
    let memory = sampleMemory()

    let sampledProcesses = await processSample
    let processes = sampledProcesses.processes
    let appGroups = groupProcesses(processes, now: sampledProcesses.now)

    return await InstantSystemMetrics(
      cpu: cpu,
      memory: memory,
      processes: processes,
      appGroups: appGroups,
      systemWatts: nil,
      powerSourceNote: "macOS does not expose reliable whole-system wattage through a safe public API. Corewise can show battery or power-source context later, but should not invent watts."
    )
  }

  static func memoryPressureEstimate(memoryPercent: Double, swapUsedGB: Double?) -> DiagnosticMetric {
    let now = Date()
    return DiagnosticMetric(
      title: "Memory Pressure",
      value: "Unavailable",
      unit: "",
      dataMode: .unavailable,
      status: .info,
      severityScore: 0,
      explanation: "Corewise does not expose a live memory-pressure number until it can use a public source that matches macOS semantics reliably.",
      source: "No reliable public parity source selected",
      confidence: "Unavailable / high",
      recommendedAction: "Use the real memory, footprint, and swap values as context instead.",
      lastUpdated: now
    )
  }

  static func processStatus(cpuPercent: Double, memoryBytes: UInt64) -> FindingSeverity {
    if cpuPercent >= 200 {
      return .critical
    }
    if cpuPercent >= 75 || memoryBytes >= 8 * bytesPerGBInt {
      return .warning
    }
    if cpuPercent >= 25 || memoryBytes >= 1 * bytesPerGBInt {
      return .info
    }
    return .good
  }

  static func processSeverity(cpuPercent: Double, memoryBytes: UInt64) -> Int {
    let memoryGB = Double(memoryBytes) / bytesPerGB
    return min(max(Int(max(cpuPercent, memoryGB * 18).rounded()), 0), 100)
  }

  private static func sampleCPU() async -> SystemCPUReading {
    let now = Date()
    guard let first = cpuTicks() else {
      return unavailableCPU(now: now)
    }

    try? await Task.sleep(nanoseconds: 1_000_000_000)

    guard let second = cpuTicks() else {
      return unavailableCPU(now: Date())
    }

    let userDelta = second.user - first.user
    let systemDelta = second.system - first.system
    let niceDelta = second.nice - first.nice
    let idleDelta = second.idle - first.idle
    let totalDelta = userDelta + systemDelta + niceDelta + idleDelta

    guard totalDelta > 0 else {
      return unavailableCPU(now: Date())
    }

    let total = Double(totalDelta)
    let idlePercent = Double(idleDelta) / total * 100
    let userPercent = Double(userDelta) / total * 100
    let systemPercent = Double(systemDelta) / total * 100
    let nicePercent = Double(niceDelta) / total * 100

    return SystemCPUReading(
      totalPercent: max(0, 100 - idlePercent),
      userPercent: userPercent,
      systemPercent: systemPercent,
      idlePercent: idlePercent,
      nicePercent: nicePercent,
      dataMode: .live,
      source: "host_statistics HOST_CPU_LOAD_INFO",
      confidence: "Live / medium",
      lastUpdated: Date()
    )
  }

  private static func unavailableCPU(now: Date) -> SystemCPUReading {
    SystemCPUReading(
      totalPercent: nil,
      userPercent: nil,
      systemPercent: nil,
      idlePercent: nil,
      nicePercent: nil,
      dataMode: .unavailable,
      source: "host_statistics HOST_CPU_LOAD_INFO",
      confidence: "Unavailable / medium",
      lastUpdated: now
    )
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

  private static func sampleMemory() -> SystemMemoryReading {
    let now = Date()
    let physicalBytes = UInt64(ProcessInfo.processInfo.physicalMemory)
    let pageSize = UInt64(vmPageSize())

    var stats = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

    let result = withUnsafeMutablePointer(to: &stats) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
        host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
      }
    }

    guard result == KERN_SUCCESS else {
      return SystemMemoryReading(
        physicalBytes: physicalBytes,
        usedBytes: 0,
        freeBytes: 0,
        appMemoryBytes: 0,
        cachedFilesBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0,
        swapUsedBytes: sampleSwapUsedBytes(),
        dataMode: .unavailable,
        source: "host_statistics64 HOST_VM_INFO64",
        confidence: "Unavailable / medium",
        lastUpdated: now
      )
    }

    let freeBytes = UInt64(stats.free_count) * pageSize
    let wiredBytes = UInt64(stats.wire_count) * pageSize
    let compressedBytes = UInt64(stats.compressor_page_count) * pageSize
    let appMemoryBytes = UInt64(stats.internal_page_count) * pageSize
    let cachedFilesBytes = UInt64(stats.external_page_count) * pageSize
    let usedBytes = min(appMemoryBytes + wiredBytes + compressedBytes, physicalBytes)

    return SystemMemoryReading(
      physicalBytes: physicalBytes,
      usedBytes: usedBytes,
      freeBytes: freeBytes,
      appMemoryBytes: appMemoryBytes,
      cachedFilesBytes: cachedFilesBytes,
      wiredBytes: wiredBytes,
      compressedBytes: compressedBytes,
      swapUsedBytes: sampleSwapUsedBytes(),
      dataMode: .live,
      source: "host_statistics64 HOST_VM_INFO64",
      confidence: "Live / medium",
      lastUpdated: now
    )
  }

  private static func sampleSwapUsedBytes() -> UInt64? {
    var usage = xsw_usage()
    var size = MemoryLayout<xsw_usage>.stride
    let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)

    guard result == 0 else {
      return nil
    }

    return UInt64(usage.xsu_used)
  }

  private static func sampleProcesses() async -> (processes: [ProcessObservation], now: Date) {
    let first = processStats()
    let start = Date()

    try? await Task.sleep(nanoseconds: 1_000_000_000)

    let second = processStats()
    let elapsed = max(Date().timeIntervalSince(start), 0.2)
    let now = Date()

    let observations = second.values.compactMap { current -> ProcessObservation? in
      guard let previous = first[current.pid] else {
        return nil
      }

      let deltaNanoseconds = current.cpuNanoseconds > previous.cpuNanoseconds
        ? current.cpuNanoseconds - previous.cpuNanoseconds
        : 0
      let cpuPercent = Double(deltaNanoseconds) / 1_000_000_000 / elapsed * 100
      let footprint = current.physicalFootprintBytes
      let observedMemory = max(footprint ?? 0, current.residentBytes)
      let status = processStatus(cpuPercent: cpuPercent, memoryBytes: observedMemory)
      let severity = processSeverity(cpuPercent: cpuPercent, memoryBytes: observedMemory)
      let appName = appBundleName(from: current.path)

      return ProcessObservation(
        pid: current.pid,
        processName: current.name,
        displayName: current.name,
        appName: appName,
        path: current.path,
        user: current.user,
        cpuPercent: cpuPercent,
        cpuTimeSeconds: Double(current.cpuNanoseconds) / 1_000_000_000,
        threadCount: current.threadCount,
        residentMemoryBytes: current.residentBytes,
        physicalFootprintBytes: footprint,
        dataMode: .live,
        status: status,
        severityScore: severity,
        explanation: "Live process row sampled from public process APIs over a 1 second window.",
        source: footprint == nil ? "proc_pidinfo PROC_PIDTASKINFO" : "proc_pidinfo + proc_pid_rusage RUSAGE_INFO_V4",
        confidence: footprint == nil ? "Live / medium" : "Live / high",
        recommendedAction: "Use repeated CPU, observed memory, and process identity before deciding whether to quit anything.",
        lastUpdated: now
      )
    }

    let readable = observations
      .filter { $0.cpuPercent >= 0.05 || $0.observedMemoryBytes >= 20 * 1024 * 1024 }

    let topCPU = readable
      .sorted { $0.cpuPercent > $1.cpuPercent }
      .prefix(80)
    let topMemory = readable
      .sorted { $0.observedMemoryBytes > $1.observedMemoryBytes }
      .prefix(80)

    var merged: [Int32: ProcessObservation] = [:]
    for process in topCPU {
      merged[process.pid] = process
    }
    for process in topMemory {
      merged[process.pid] = process
    }

    let sorted = merged.values.sorted {
      ($0.cpuPercent, $0.observedMemoryBytes) > ($1.cpuPercent, $1.observedMemoryBytes)
    }

    return (Array(sorted), now)
  }

  private static func processStats() -> [Int32: ProcessStat] {
    let pids = allProcessIDs()
    guard !pids.isEmpty else {
      return [:]
    }
    var stats: [Int32: ProcessStat] = [:]

    for pid in pids where pid > 0 {
      guard let taskInfo = taskInfo(pid: pid) else {
        continue
      }

      let name = processName(pid: pid)
      let path = processPath(pid: pid)
      let user = userName(pid: pid)
      let cpuNanoseconds = machTicksToNanoseconds(taskInfo.pti_total_user + taskInfo.pti_total_system)

      stats[pid] = ProcessStat(
        pid: pid,
        name: name,
        path: path,
        user: user,
        cpuNanoseconds: cpuNanoseconds,
        threadCount: taskInfo.pti_threadnum,
        residentBytes: UInt64(taskInfo.pti_resident_size),
        physicalFootprintBytes: physicalFootprint(pid: pid)
      )
    }

    return stats
  }

  private static func allProcessIDs() -> [pid_t] {
    let sysctlPIDs = sysctlProcessIDs()
    if !sysctlPIDs.isEmpty {
      return sysctlPIDs
    }

    return listAllProcessIDs()
  }

  private static func sysctlProcessIDs() -> [pid_t] {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
    var size = 0

    guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0, size > 0 else {
      return []
    }

    var processes = Array(repeating: kinfo_proc(), count: size / MemoryLayout<kinfo_proc>.stride)
    guard sysctl(&mib, u_int(mib.count), &processes, &size, nil, 0) == 0 else {
      return []
    }

    let count = min(size / MemoryLayout<kinfo_proc>.stride, processes.count)
    return Array(Set(processes.prefix(count).map(\.kp_proc.p_pid).filter { $0 > 0 }))
  }

  private static func listAllProcessIDs() -> [pid_t] {
    let estimatedCount = Int(proc_listallpids(nil, 0))
    guard estimatedCount > 0 else {
      return []
    }

    var capacity = max(estimatedCount * 4, 4096)
    let stride = MemoryLayout<pid_t>.stride

    for _ in 0..<4 {
      var pids = Array(repeating: pid_t(0), count: capacity)
      let bufferBytes = pids.count * stride
      let actualBytes = pids.withUnsafeMutableBytes { buffer in
        proc_listallpids(buffer.baseAddress, Int32(bufferBytes))
      }

      guard actualBytes > 0 else {
        return []
      }

      let actualCount = min(Int(actualBytes) / stride, pids.count)
      if Int(actualBytes) < bufferBytes {
        return Array(pids.prefix(actualCount)).filter { $0 > 0 }
      }

      capacity *= 2
    }

    return []
  }

  private static func taskInfo(pid: pid_t) -> proc_taskinfo? {
    var taskInfo = proc_taskinfo()
    let infoSize = MemoryLayout<proc_taskinfo>.stride
    let result = withUnsafeMutablePointer(to: &taskInfo) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: infoSize) { reboundPointer in
        proc_pidinfo(pid, PROC_PIDTASKINFO, 0, reboundPointer, Int32(infoSize))
      }
    }

    guard result == Int32(infoSize) else {
      return nil
    }

    return taskInfo
  }

  static func machTicksToNanoseconds(_ ticks: UInt64) -> UInt64 {
    var timebase = mach_timebase_info_data_t()
    guard mach_timebase_info(&timebase) == KERN_SUCCESS, timebase.denom > 0 else {
      return ticks
    }

    let converted = Double(ticks) * Double(timebase.numer) / Double(timebase.denom)
    return UInt64(converted)
  }

  private static func physicalFootprint(pid: pid_t) -> UInt64? {
    guard pid > 0 else {
      return nil
    }

    var info = rusage_info_v4()
    let result = withUnsafeMutablePointer(to: &info) { pointer -> Int32 in
      UnsafeMutableRawPointer(pointer).withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { reboundPointer in
        proc_pid_rusage(pid, RUSAGE_INFO_V4, reboundPointer)
      }
    }

    guard result == 0, info.ri_phys_footprint > 0 else {
      return nil
    }

    return info.ri_phys_footprint
  }

  private static func userName(pid: pid_t) -> String {
    var info = proc_bsdshortinfo()
    let infoSize = MemoryLayout<proc_bsdshortinfo>.stride
    let result = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: UInt8.self, capacity: infoSize) { reboundPointer in
        proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, 0, reboundPointer, Int32(infoSize))
      }
    }

    guard result == Int32(infoSize) else {
      return "unknown"
    }

    guard let entry = getpwuid(info.pbsi_uid), let name = entry.pointee.pw_name else {
      return "\(info.pbsi_uid)"
    }

    return String(cString: name)
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

  private static func groupProcesses(_ processes: [ProcessObservation], now: Date) -> [AppProcessGroup] {
    var grouped: [String: [ProcessObservation]] = [:]

    for process in processes {
      let name = process.appName ?? process.processName
      grouped[name, default: []].append(process)
    }

    return grouped.map { name, rows in
      let cpu = rows.reduce(0) { $0 + $1.cpuPercent }
      let resident = rows.reduce(UInt64(0)) { $0 + $1.residentMemoryBytes }
      let footprints = rows.compactMap(\.physicalFootprintBytes)
      let footprint = footprints.isEmpty ? nil : footprints.reduce(UInt64(0), +)
      let observedMemory = max(footprint ?? 0, resident)
      let status = processStatus(cpuPercent: cpu, memoryBytes: observedMemory)

      return AppProcessGroup(
        name: name,
        processCount: rows.count,
        cpuPercent: cpu,
        residentMemoryBytes: resident,
        physicalFootprintBytes: footprint,
        dataMode: .live,
        status: status,
        severityScore: processSeverity(cpuPercent: cpu, memoryBytes: observedMemory),
        source: "Derived from live process rows",
        confidence: footprint == nil ? "Live / medium" : "Live / high",
        lastUpdated: now
      )
    }
    .sorted {
      ($0.cpuPercent, $0.observedMemoryBytes) > ($1.cpuPercent, $1.observedMemoryBytes)
    }
  }

  private static func vmPageSize() -> vm_size_t {
    var size: vm_size_t = 0
    host_page_size(mach_host_self(), &size)
    return size
  }

  static let bytesPerGB = 1024.0 * 1024.0 * 1024.0
  static let bytesPerGBInt = UInt64(1024 * 1024 * 1024)
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
  var user: String
  var cpuNanoseconds: UInt64
  var threadCount: Int32
  var residentBytes: UInt64
  var physicalFootprintBytes: UInt64?
}
