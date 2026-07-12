import Charts
import SwiftUI

struct PerformanceView: View {
  var performance: PerformanceHealth
  var focusedCheckSession: FocusedCheckSession?
  var requestedMode: PerformanceMode?
  var requestedFocus: DashboardFocus?
  @AppStorage(CorewiseSettingsKeys.performanceDefaultFocus) private var defaultFocus = PerformanceDefaultFocus.cpu.rawValue
  @State private var mode: PerformanceMode = .cpu
  @State private var query = ""
  @State private var selectedPID: Int32?
  @State private var selectedSnapshot: ProcessObservation?
  @State private var isInspectorPresented = false
  @State private var sort: ProcessTablePresenter.Sort = .cpu
  @State private var selectedGroupID: String?

  private var groupFilteredProcesses: [ProcessObservation] {
    guard let selectedGroupID,
          let group = performance.appGroups.first(where: { $0.id == selectedGroupID }) else {
      return performance.processes
    }
    let pids = Set(group.memberPIDs)
    return performance.processes.filter { pids.contains($0.pid) }
  }

  var body: some View {
    let presentedRows = ProcessTablePresenter.presented(groupFilteredProcesses, mode: mode, query: query, sort: sort)

    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space20) {
        PageHeader(
          title: "Performance",
          subtitle: "CPU activity and memory pressure are separate views of the same live process sample.",
          systemImage: "cpu"
        )

        PerformanceSummaryStrip(performance: performance, mode: mode)

        if let focusedCheckSession, !focusedCheckSession.activityGroups.isEmpty {
          AppGroupEvidenceView(
            activityGroups: focusedCheckSession.activityGroups,
            liveGroups: performance.appGroups,
            mode: mode,
            selectedGroupID: selectedGroupID,
            select: { selectedGroupID = $0 }
          )
        }

        HStack {
          Picker("Performance focus", selection: modeSelection) {
            ForEach(PerformanceMode.allCases) { mode in
              Text(mode.title).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 240)

          HStack(spacing: CorewiseLayout.space8) {
            Image(systemName: "magnifyingglass")
              .foregroundStyle(.secondary)
            TextField("Filter process, user, path, or PID", text: $query)
              .textFieldStyle(.plain)
          }
          .padding(.horizontal, CorewiseLayout.space8)
          .padding(.vertical, 6)
          .background(CorewiseVisual.contentSurface, in: .rect(cornerRadius: 8))

          Spacer()
          Picker("Sort", selection: $sort) {
            ForEach(ProcessTablePresenter.availableSorts(for: mode)) { sort in
              Text(sort.rawValue).tag(sort)
            }
          }
          .frame(width: 168)
          Text(processCountLabel(for: presentedRows))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .padding(CorewiseLayout.space12)
        .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
        .overlay {
          RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
            .stroke(CorewiseVisual.separator, lineWidth: 1)
        }

        if presentedRows.isEmpty {
          ContentUnavailableView.search(text: query)
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
          ProcessEvidenceTable(mode: mode, rows: presentedRows, selection: $selectedPID)
          .frame(height: tableHeight(for: presentedRows))
          .corewiseTableSurface()
        }
      }
      .padding(CorewiseLayout.pagePadding)
      .padding(.top, 44)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .inspector(isPresented: $isInspectorPresented) {
      if let selectedSnapshot {
        ProcessInspector(
          process: selectedSnapshot,
          isCurrent: performance.processes.contains { $0.pid == selectedSnapshot.pid },
          mode: mode,
          owningGroup: performance.appGroups.first { $0.memberPIDs.contains(selectedSnapshot.pid) },
          checkActivity: focusedCheckSession?.activityGroups.first { $0.memberPIDs.contains(selectedSnapshot.pid) }
        )
        .inspectorColumnWidth(min: 260, ideal: 320, max: 380)
      } else {
        ContentUnavailableView("Select a process", systemImage: "cursorarrow.click", description: Text("Choose a row to inspect its local metadata."))
          .inspectorColumnWidth(min: 260, ideal: 320, max: 380)
      }
    }
    .onAppear {
      selectMode(requestedMode ?? (PerformanceDefaultFocus(rawValue: defaultFocus) == .memory ? .memory : .cpu))
      apply(requestedFocus)
    }
    .onChange(of: requestedMode) { _, requestedMode in
      if let requestedMode {
        selectMode(requestedMode)
      }
    }
    .onChange(of: requestedFocus) { _, focus in
      apply(focus)
    }
    .onChange(of: selectedPID) { _, pid in
      guard let pid, let process = performance.processes.first(where: { $0.pid == pid }) else { return }
      selectedSnapshot = process
      isInspectorPresented = true
    }
    .onChange(of: performance.processes.map(\.id)) { _, _ in
      guard let selectedPID, let process = performance.processes.first(where: { $0.pid == selectedPID }) else { return }
      selectedSnapshot = process
    }
  }

  private var modeSelection: Binding<PerformanceMode> {
    Binding(
      get: { mode },
      set: { newMode in selectMode(newMode) }
    )
  }

  private func selectMode(_ newMode: PerformanceMode) {
    mode = newMode
    sort = ProcessTablePresenter.defaultSort(for: newMode)
  }

  private func apply(_ focus: DashboardFocus?) {
    switch focus {
    case let .process(pid, focusMode):
      selectMode(focusMode)
      selectedGroupID = nil
      selectedPID = pid
      if let process = performance.processes.first(where: { $0.pid == pid }) {
        selectedSnapshot = process
        isInspectorPresented = true
      }
    case let .appGroup(id, focusMode):
      selectMode(focusMode)
      selectedGroupID = id
    case .storageCategory, .storagePath, nil:
      break
    }
  }

  private func tableHeight(for rows: [ProcessObservation]) -> Double {
    min(max(Double(min(rows.count, 18)) * 28 + 58, 320), 600)
  }

  private func processCountLabel(for rows: [ProcessObservation]) -> String {
    switch mode {
    case .cpu:
      "\(rows.count) CPU-active"
    case .memory:
      "\(rows.count) memory-significant"
    }
  }
}

private struct ProcessEvidenceTable: View {
  var mode: PerformanceMode
  var rows: [ProcessObservation]
  @Binding var selection: Int32?

  @ViewBuilder
  var body: some View {
    switch mode {
    case .cpu:
      Table(rows, selection: $selection) {
        TableColumn("Process", value: \.displayName)
        TableColumn("CPU Now") { process in
          Text(corewisePercent(process.cpuPercent))
            .monospacedDigit()
        }
          .width(min: 76, ideal: 92)
        TableColumn("CPU Time") { process in
          Text(processCPUTime(process.cpuTimeSeconds))
            .monospacedDigit()
        }
          .width(min: 84, ideal: 104)
        TableColumn("Threads") { process in
          Text(process.threadCount, format: .number)
            .monospacedDigit()
        }
          .width(min: 68, ideal: 82)
        TableColumn("User", value: \.user)
          .width(min: 88, ideal: 112)
      }
      .accessibilityLabel("Processes with observed CPU activity")

    case .memory:
      Table(rows, selection: $selection) {
        TableColumn("Process", value: \.displayName)
        TableColumn("Observed Memory") { process in
          Text(corewiseBytes(process.observedMemoryBytes))
            .monospacedDigit()
        }
          .width(min: 118, ideal: 142)
        TableColumn("Footprint") { process in
          Text(process.physicalFootprintBytes.map(corewiseBytes) ?? "Unavailable")
            .monospacedDigit()
        }
          .width(min: 104, ideal: 126)
        TableColumn("RSS") { process in
          Text(corewiseBytes(process.residentMemoryBytes))
            .monospacedDigit()
        }
          .width(min: 88, ideal: 108)
        TableColumn("Page-ins") { process in
          Text(process.pageIns, format: .number)
            .monospacedDigit()
        }
          .width(min: 72, ideal: 88)
      }
      .accessibilityLabel("Processes with significant observed memory")
    }
  }
}

private struct PerformanceSummaryStrip: View {
  var performance: PerformanceHealth
  var mode: PerformanceMode

  var body: some View {
    OperationalSection(title: mode == .cpu ? "CPU pressure" : "Memory context", subtitle: "A rolling 60-point instrument view.", instrument: true) {
      HStack(alignment: .center, spacing: CorewiseLayout.space24) {
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text(mode == .cpu ? "TOTAL CPU" : "MEMORY USED")
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
          Text(mode == .cpu ? corewisePercent(performance.cpu.totalPercent) : "\(corewiseNumber(performance.memory.usedPercent))%")
            .font(.system(.largeTitle, design: .rounded, weight: .semibold).monospacedDigit())
            .foregroundStyle(mode == .cpu ? CorewiseVisual.accentBright : CorewiseVisual.good)
          Text(mode == .cpu ? performance.summary.explanation : performance.memoryContext.detail)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
        .frame(maxWidth: 360, alignment: .leading)

        Chart(performance.history) { point in
          if mode == .cpu, let cpu = point.cpuPercent {
            LineMark(x: .value("Time", point.timestamp), y: .value("CPU", cpu))
              .foregroundStyle(CorewiseVisual.accent)
              .interpolationMethod(.catmullRom)
          } else if mode == .memory {
            AreaMark(x: .value("Time", point.timestamp), y: .value("Memory", point.memoryUsedPercent))
              .foregroundStyle(CorewiseVisual.good.opacity(0.12))
              .interpolationMethod(.catmullRom)
            LineMark(x: .value("Time", point.timestamp), y: .value("Memory", point.memoryUsedPercent))
              .foregroundStyle(CorewiseVisual.good)
              .interpolationMethod(.catmullRom)
          }
        }
        .chartYAxis { AxisMarks(position: .leading) }
        .chartYScale(domain: 0...100)
        .frame(maxWidth: .infinity, minHeight: 96, maxHeight: 120)
        .padding(CorewiseLayout.space8)
        .background {
          ZStack {
            CorewiseVisual.quietSurface.opacity(0.74)
            CorewiseGridTexture(spacing: 20, dotSize: 1)
              .opacity(0.22)
          }
        }
        .clipShape(.rect(cornerRadius: CorewiseVisual.controlRadius))
        .accessibilityLabel("Recent \(mode.title) performance history")
        .accessibilityValue(performanceChartAccessibilityValue(points: performance.history, mode: mode))
      }

      Divider()
      HStack {
        if mode == .cpu {
          MetricRow(title: "User", value: corewisePercent(performance.cpu.userPercent))
          Divider()
          MetricRow(title: "System", value: corewisePercent(performance.cpu.systemPercent))
          Divider()
          MetricRow(title: "Idle", value: corewisePercent(performance.cpu.idlePercent))
        } else {
          MetricRow(title: "App memory", value: corewiseBytes(performance.memory.appMemoryBytes))
          Divider()
          MetricRow(title: "Compressed", value: corewiseBytes(performance.memory.compressedBytes))
          Divider()
          MetricRow(title: "Swap", value: performance.memory.swapUsedBytes.map(corewiseBytes) ?? "Unavailable")
        }
      }
    }
  }

}

private struct ProcessInspector: View {
  var process: ProcessObservation
  var isCurrent: Bool
  var mode: PerformanceMode
  var owningGroup: AppProcessGroup?
  var checkActivity: FocusedCheckActivitySummary?

  var body: some View {
    let interpretation = ProcessInterpretationResolver.interpretation(for: process, activity: checkActivity)
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        PageHeader(
          title: process.displayName,
          subtitle: isCurrent ? "Current sample" : "Process no longer appears in the current sample",
          systemImage: mode == .cpu ? "cpu" : "memorychip",
          compact: true
        )

        if mode == .cpu {
          OperationalSection(title: "CPU evidence", instrument: true) {
            MetricRow(title: "CPU now", value: corewisePercent(process.cpuPercent))
            Divider()
            MetricRow(title: "Accumulated CPU time", value: processCPUTime(process.cpuTimeSeconds))
            Divider()
            MetricRow(title: "Threads", value: String(process.threadCount))
          }
          OperationalSection(title: "Memory reference") {
            MetricRow(title: "Observed memory", value: corewiseBytes(process.observedMemoryBytes))
          }
        } else {
          OperationalSection(title: "Memory evidence", instrument: true) {
            MetricRow(title: "Observed memory", value: corewiseBytes(process.observedMemoryBytes))
            Divider()
            MetricRow(title: "Physical footprint", value: process.physicalFootprintBytes.map(corewiseBytes) ?? "Unavailable")
            Divider()
            MetricRow(title: "Resident memory (RSS)", value: corewiseBytes(process.residentMemoryBytes))
            Divider()
            MetricRow(title: "Page-ins since launch", value: String(process.pageIns))
          }
          OperationalSection(title: "CPU reference") {
            MetricRow(title: "CPU now", value: corewisePercent(process.cpuPercent))
          }
        }

        OperationalSection(title: "Identity") {
          MetricRow(title: "PID", value: String(process.pid))
          Divider()
          MetricRow(title: "User", value: process.user)
          Divider()
          MetricRow(title: "Observed", value: process.lastUpdated.formatted(date: .omitted, time: .standard))
        }

        OperationalSection(title: "What this process usually represents") {
          Text(interpretation.title)
            .font(.headline)
          Text(interpretation.detail)
            .foregroundStyle(.secondary)
          if let ownerName = interpretation.ownerName {
            Divider()
            MetricRow(title: "Likely owner", value: ownerName)
          }
          if !interpretation.expectedContexts.isEmpty {
            Divider()
            Text("Expected contexts")
              .font(.callout.weight(.semibold))
            Text(interpretation.expectedContexts.joined(separator: " · "))
              .font(.callout)
              .foregroundStyle(.secondary)
          }
        }

        OperationalSection(title: "Focused Check context", instrument: checkActivity != nil) {
          MetricRow(title: "Owning app/group", value: owningGroup?.name ?? interpretation.ownerName ?? "Unavailable")
          Divider()
          MetricRow(title: "Observation pattern", value: interpretation.activityPattern.title)
          if let checkActivity {
            Divider()
            MetricRow(title: "Samples", value: "\(checkActivity.sampleCount) total · \(checkActivity.activeCPUSampleCount) CPU-active")
            Divider()
            MetricRow(title: "Peak in check", value: "\(corewisePercent(checkActivity.maximumCPUPercent)) CPU · \(corewiseBytes(checkActivity.peakMemoryBytes)) memory")
          }
          Divider()
          Text(interpretation.safeReviewAction)
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        if let path = process.path {
          OperationalSection(title: "Executable") {
            Text(path)
              .font(.body.monospaced())
              .textSelection(.enabled)
          }
        }

        SourceDisclosure(title: "Interpretation", detail: "\(modeExplanation) \(process.explanation) Source: \(process.source). \(process.confidence).")
      }
      .padding(CorewiseLayout.space16)
    }
  }

  private var modeExplanation: String {
    switch mode {
    case .cpu:
      "CPU Now is a short live interval; CPU Time is cumulative for the process lifetime."
    case .memory:
      "Observed Memory is the larger public value between footprint and RSS. Page-ins are context, not exact process swap ownership."
    }
  }
}

private func processCPUTime(_ seconds: Double) -> String {
  Duration.seconds(seconds).formatted(
    .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated)
  )
}

func performanceChartAccessibilityValue(points: [PerformanceTimePoint], mode: PerformanceMode) -> String {
  let values = mode == .cpu ? points.compactMap(\.cpuPercent) : points.map(\.memoryUsedPercent)
  guard let first = values.first,
        let last = values.last,
        let maximum = values.max(),
        let start = points.first?.timestamp,
        let end = points.last?.timestamp else {
    return corewiseFormat("Collecting recent %@ history", mode.title)
  }

  let elapsed = max(end.timeIntervalSince(start), 0)
  let duration = Duration.seconds(elapsed).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated))
  let delta = last - first
  let trend = if abs(delta) < 0.5 {
    "stable"
  } else if delta > 0 {
    "rising"
  } else {
    "falling"
  }

  return corewiseFormat(
    "%@ points over %@, from %@ to %@ percent, maximum %@ percent, %@ trend",
    String(values.count),
    duration,
    corewiseNumber(first),
    corewiseNumber(last),
    corewiseNumber(maximum),
    trend
  )
}

#Preview("Performance — live") {
  PerformanceView(performance: PreviewFixtures.performance, focusedCheckSession: nil, requestedMode: .cpu, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — memory") {
  PerformanceView(performance: PreviewFixtures.performance, focusedCheckSession: nil, requestedMode: .memory, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — active Focused Check") {
  PerformanceView(performance: PreviewFixtures.performance, focusedCheckSession: PreviewFixtures.focusedSession, requestedMode: .cpu, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — empty") {
  var performance = PreviewFixtures.performance
  performance.processes = []
  performance.appGroups = []
  return PerformanceView(performance: performance, focusedCheckSession: nil, requestedMode: .cpu, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — process no longer current") {
  ProcessInspector(
    process: PreviewFixtures.performance.processes[0],
    isCurrent: false,
    mode: .memory,
    owningGroup: PreviewFixtures.performance.appGroups.first,
    checkActivity: PreviewFixtures.focusedSession.activityGroups.first
  )
  .frame(width: 360, height: 760)
}
