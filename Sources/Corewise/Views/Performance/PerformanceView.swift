import AppKit
import Charts
import SwiftUI

struct PerformanceView: View {
  var performance: PerformanceHealth
  @ObservedObject var store: HealthDashboardStore
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
  @State private var selectedAIWorkloadID: AIWorkloadID?
  @State private var selectedAIWorkloadSnapshot: AIWorkloadObservation?
  @State private var aiSort: AIWorkloadSort = .memory
  @Environment(AppRouteStore.self) private var routeStore

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
    let presentedAIWorkloads = AIWorkloadPresenter.presented(performance.aiWorkloads, query: query, sort: aiSort)

    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space20) {
        PageHeader(
          title: "Performance",
          subtitle: mode == .aiWorkloads ? "Local AI app footprint, related work, and shared hosts stay explicitly separated." : "CPU activity and memory pressure are separate views of the same live process sample.",
          systemImage: "cpu"
        )

        if mode == .aiWorkloads {
          AIWorkloadsSummaryStrip(
            workloads: performance.aiWorkloads,
            canStartSession: store.focusedCheckSession == nil || store.focusedCheckSession?.phase == .completed,
            startSession: startAISession
          )
          aiSessionSurface
        } else {
          PerformanceSummaryStrip(performance: performance, mode: mode)
        }

        if mode != .aiWorkloads, let focusedCheckSession, !focusedCheckSession.activityGroups.isEmpty {
          AppGroupEvidenceView(
            activityGroups: focusedCheckSession.activityGroups,
            liveGroups: performance.appGroups,
            mode: mode,
            selectedGroupID: selectedGroupID,
            select: { selectedGroupID = $0 }
          )
        }

        HStack(spacing: CorewiseLayout.space8) {
          Picker("Performance focus", selection: modeSelection) {
            ForEach(PerformanceMode.allCases) { mode in
              Text(mode.title).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .frame(maxWidth: 300)

          HStack(spacing: CorewiseLayout.space8) {
            Image(systemName: "magnifyingglass")
              .foregroundStyle(.secondary)
            TextField(mode == .aiWorkloads ? "Filter supported AI tools" : "Filter process, user, path, or PID", text: $query)
              .textFieldStyle(.plain)
          }
          .padding(.horizontal, CorewiseLayout.space8)
          .padding(.vertical, 6)
          .background(CorewiseVisual.contentSurface, in: .rect(cornerRadius: 8))

          Spacer()
          if mode == .aiWorkloads {
            Picker("Sort", selection: $aiSort) {
              ForEach(AIWorkloadSort.allCases) { sort in
                Text(sort.title).tag(sort)
              }
            }
            .frame(width: 144)
            Text("\(presentedAIWorkloads.count) observed")
              .font(.callout)
              .foregroundStyle(.secondary)
              .monospacedDigit()
              .fixedSize()
          } else {
            Picker("Sort", selection: $sort) {
              ForEach(ProcessTablePresenter.availableSorts(for: mode)) { sort in
                Text(sort.rawValue).tag(sort)
              }
            }
            .frame(width: 144)
            Text(processCountLabel(for: presentedRows))
              .font(.callout)
              .foregroundStyle(.secondary)
              .monospacedDigit()
              .fixedSize()
          }
        }
        .controlSize(.small)
        .padding(.horizontal, CorewiseLayout.space12)
        .frame(height: 48)
        .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
        .overlay {
          RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
            .stroke(CorewiseVisual.separator, lineWidth: 1)
        }

        if mode == .aiWorkloads {
          if presentedAIWorkloads.isEmpty {
            AIWorkloadsEmptyState(query: query)
              .frame(maxWidth: .infinity, minHeight: 220)
          } else {
            VStack(spacing: 0) {
              AIWorkloadMemoryMap(workloads: presentedAIWorkloads)
                .padding(CorewiseLayout.space16)
              Divider()
              AIWorkloadTable(
                rows: presentedAIWorkloads,
                sessionSummaries: focusedCheckSession?.aiWorkloads ?? [],
                selection: $selectedAIWorkloadID
              )
              .frame(height: tableHeightForAI(presentedAIWorkloads))
            }
            .background(CorewiseVisual.contentSurface)
            .corewiseTableSurface()
          }
        } else if presentedRows.isEmpty {
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
      if mode == .aiWorkloads, let selectedAIWorkloadSnapshot {
        AIWorkloadInspector(workload: selectedAIWorkloadSnapshot, sessionSummary: focusedCheckSession?.aiWorkloads.first { $0.workloadID == selectedAIWorkloadSnapshot.id })
          .inspectorColumnWidth(min: 300, ideal: 360, max: 440)
      } else if let selectedSnapshot {
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
    .onChange(of: selectedAIWorkloadID) { _, id in
      guard let id, let workload = performance.aiWorkloads.first(where: { $0.id == id }) else { return }
      selectedAIWorkloadSnapshot = workload
      isInspectorPresented = true
    }
    .onChange(of: performance.aiWorkloads.map(\.id)) { _, _ in
      guard let selectedAIWorkloadID, let workload = performance.aiWorkloads.first(where: { $0.id == selectedAIWorkloadID }) else { return }
      selectedAIWorkloadSnapshot = workload
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
    if newMode != .aiWorkloads {
      sort = ProcessTablePresenter.defaultSort(for: newMode)
    }
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

  private func tableHeightForAI(_ rows: [AIWorkloadObservation]) -> Double {
    min(max(Double(rows.count) * 30 + 42, 126), 420)
  }

  private func processCountLabel(for rows: [ProcessObservation]) -> String {
    switch mode {
    case .cpu:
      "\(rows.count) CPU-active"
    case .memory:
      "\(rows.count) memory-significant"
    case .aiWorkloads:
      "\(performance.aiWorkloads.count) observed"
    }
  }

  @ViewBuilder
  private var aiSessionSurface: some View {
    if let session = store.focusedCheckSession, session.intent == .aiWorkloads, session.phase != .completed {
      FocusedCheckProgressView(session: session, cancel: { store.cancelFocusedCheck() }, finish: { store.finishFocusedCheck() })
    } else if let result = store.lastFocusedCheckResult, result.intent == .aiWorkloads {
      FocusedCheckResultView(
        result: result,
        open: routeStore.show,
        copy: { copyAIResult(result, markdown: false) },
        copyMarkdown: { copyAIResult(result, markdown: true) },
        startAnother: store.dismissFocusedCheckResult
      )
    }
  }

  private func startAISession() {
    store.startFocusedCheck(.aiWorkloads)
  }

  private func copyAIResult(_ result: FocusedCheckResult, markdown: Bool) {
    let builder = DiagnosticReportBuilder()
    let value = markdown ? builder.focusedCheckMarkdown(for: result) : builder.focusedCheckSummary(for: result)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
  }
}

private enum AIWorkloadSort: String, CaseIterable, Identifiable {
  case memory
  case cpu
  case related
  case name

  var id: String { rawValue }
  var title: String {
    switch self {
    case .memory: "Observed Memory"
    case .cpu: "CPU Now"
    case .related: "Related Work"
    case .name: "Name"
    }
  }
}

private enum AIWorkloadPresenter {
  static func presented(_ workloads: [AIWorkloadObservation], query: String, sort: AIWorkloadSort) -> [AIWorkloadObservation] {
    let filtered = query.isEmpty ? workloads : workloads.filter { workload in
      workload.name.localizedStandardContains(query)
        || workload.supportLevel.title.localizedStandardContains(query)
        || workload.attributions.contains { $0.process.displayName.localizedStandardContains(query) }
    }
    return filtered.sorted { lhs, rhs in
      switch sort {
      case .memory where lhs.directObservedMemoryBytes != rhs.directObservedMemoryBytes:
        lhs.directObservedMemoryBytes > rhs.directObservedMemoryBytes
      case .cpu where lhs.totalCPUPercent != rhs.totalCPUPercent:
        lhs.totalCPUPercent > rhs.totalCPUPercent
      case .related where lhs.relatedObservedMemoryBytes != rhs.relatedObservedMemoryBytes:
        lhs.relatedObservedMemoryBytes > rhs.relatedObservedMemoryBytes
      default:
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
      }
    }
  }
}

private struct AIWorkloadsSummaryStrip: View {
  var workloads: [AIWorkloadObservation]
  var canStartSession: Bool
  var startSession: () -> Void

  private var directMemory: UInt64 { workloads.reduce(0) { $0 + $1.directObservedMemoryBytes } }
  private var relatedMemory: UInt64 { workloads.reduce(0) { $0 + $1.relatedObservedMemoryBytes } }
  private var cpu: Double { workloads.reduce(0) { $0 + $1.totalCPUPercent } }
  private var lastUpdated: Date? { workloads.map(\.lastUpdated).max() }

  var body: some View {
    OperationalSection(title: "Local AI workloads", subtitle: "Current process attribution on this Mac.", instrument: true) {
      HStack(alignment: .center, spacing: CorewiseLayout.space16) {
        CorewiseBrandGlyph(size: 42, stateColor: CorewiseVisual.accent)
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text("Observed local processes")
            .font(.headline)
          HStack(spacing: CorewiseLayout.space8) {
            Label("\(workloads.count) supported tools", systemImage: "dot.radiowaves.left.and.right")
            if let lastUpdated {
              Text("·")
              Text(lastUpdated.formatted(date: .omitted, time: .shortened))
                .monospacedDigit()
            }
          }
          .font(.callout)
          .foregroundStyle(.secondary)
        }
        Spacer()
        Button("Observe AI Session", systemImage: "record.circle", action: startSession)
          .buttonStyle(.borderedProminent)
          .disabled(!canStartSession)
          .accessibilityHint("Starts a ten minute local, volatile observation with an early result after one minute")
      }
      Divider()

      Grid(alignment: .leading, horizontalSpacing: CorewiseLayout.space24, verticalSpacing: CorewiseLayout.space12) {
        GridRow {
          MetricRow(title: "App footprint", value: corewiseBytes(directMemory))
          MetricRow(title: "Related local work", value: corewiseBytes(relatedMemory))
        }
        Divider()
          .gridCellColumns(2)
        GridRow {
          MetricRow(title: "CPU now", value: corewisePercent(cpu))
          MetricRow(title: "Tools observed", value: String(workloads.count))
        }
      }

      Label(
        "App footprint is directly identified. Related work is attributed separately; shared hosts and cloud activity stay outside the total.",
        systemImage: "scope"
      )
      .font(.callout)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private struct AIWorkloadMemoryMap: View {
  var workloads: [AIWorkloadObservation]

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
      HStack(alignment: .firstTextBaseline, spacing: CorewiseLayout.space16) {
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text("Memory attribution")
            .font(.headline)
          Text("Direct app footprint compared with related local work in the current sample.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: CorewiseLayout.space12)
        HStack(spacing: CorewiseLayout.space12) {
          legend(title: "App footprint", color: CorewiseVisual.accent)
          legend(title: "Related work", color: CorewiseVisual.accentMuted)
        }
      }

      Chart(workloads) { workload in
        BarMark(
          xStart: .value("Start memory", 0),
          xEnd: .value("App footprint", megabytes(workload.directObservedMemoryBytes)),
          y: .value("Tool", workload.name)
        )
        .foregroundStyle(CorewiseVisual.accent)

        BarMark(
          xStart: .value("App footprint", megabytes(workload.directObservedMemoryBytes)),
          xEnd: .value("App footprint and related work", megabytes(workload.directObservedMemoryBytes + workload.relatedObservedMemoryBytes)),
          y: .value("Tool", workload.name)
        )
        .foregroundStyle(CorewiseVisual.accentMuted)
      }
      .chartXAxis(.hidden)
      .chartYAxis {
        AxisMarks(position: .leading) {
          AxisValueLabel()
            .font(.callout.weight(.medium))
        }
      }
      .chartLegend(.hidden)
      .chartPlotStyle { plotArea in
        plotArea
          .background(CorewiseVisual.quietSurface.opacity(0.72), in: .rect(cornerRadius: 8))
      }
      .frame(height: min(max(Double(workloads.count) * 34 + 22, 96), 230))
      .accessibilityLabel("Observed AI memory attribution")
      .accessibilityValue(accessibilitySummary)
    }
  }

  private var accessibilitySummary: String {
    workloads.map { workload in
      "\(workload.name), app footprint \(corewiseBytes(workload.directObservedMemoryBytes)), related work \(corewiseBytes(workload.relatedObservedMemoryBytes))"
    }
    .joined(separator: "; ")
  }

  private func megabytes(_ bytes: UInt64) -> Double {
    Double(bytes) / 1_048_576
  }

  private func legend(title: String, color: Color) -> some View {
    HStack(spacing: CorewiseLayout.space4) {
      RoundedRectangle(cornerRadius: 2)
        .fill(color)
        .frame(width: 14, height: 6)
        .accessibilityHidden(true)
      Text(title)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }
}

private struct AIWorkloadTable: View {
  var rows: [AIWorkloadObservation]
  var sessionSummaries: [AIWorkloadSessionSummary]
  @Binding var selection: AIWorkloadID?

  var body: some View {
    Table(rows, selection: $selection) {
      TableColumn("Tool") { workload in
        HStack(spacing: CorewiseLayout.space8) {
          Image(systemName: symbol(for: workload.category))
            .foregroundStyle(CorewiseVisual.accent)
            .frame(width: 16)
            .accessibilityHidden(true)
          Text(workload.name)
            .fontWeight(.medium)
        }
      }
      TableColumn("Support") { workload in
        Label(
          workload.supportLevel.title,
          systemImage: workload.supportLevel == .verified ? "checkmark.seal" : "scope"
        )
        .foregroundStyle(workload.supportLevel == .verified ? .primary : .secondary)
      }
        .width(min: 82, ideal: 100)
      TableColumn("Activity") { workload in
        AIWorkloadActivityLabel(
          activity: sessionSummaries.first(where: { $0.workloadID == workload.id })?.activity ?? workload.activity
        )
      }
        .width(min: 72, ideal: 88)
      TableColumn("CPU Now") { workload in Text(corewisePercent(workload.totalCPUPercent)).monospacedDigit() }
        .width(min: 72, ideal: 88)
      TableColumn("Observed Memory") { workload in Text(corewiseBytes(workload.directObservedMemoryBytes)).monospacedDigit() }
        .width(min: 112, ideal: 136)
      TableColumn("Related Work") { workload in Text(corewiseBytes(workload.relatedObservedMemoryBytes)).monospacedDigit() }
        .width(min: 104, ideal: 126)
      TableColumn("Processes") { workload in Text(workload.processCount, format: .number).monospacedDigit() }
        .width(min: 68, ideal: 80)
    }
    .scrollContentBackground(.hidden)
    .background(CorewiseVisual.quietSurface)
    .accessibilityLabel("Supported local AI workloads")
  }

  private func symbol(for category: AIWorkloadCategory) -> String {
    switch category {
    case .codingAgent: "terminal"
    case .aiEditor: "cursorarrow.rays"
    case .cliAgent: "chevron.left.forwardslash.chevron.right"
    case .localModelRuntime: "cpu"
    }
  }
}

private struct AIWorkloadActivityLabel: View {
  var activity: AIWorkloadActivity

  var body: some View {
    HStack(spacing: CorewiseLayout.space4) {
      Circle()
        .fill(color)
        .frame(width: 6, height: 6)
        .accessibilityHidden(true)
      Text(activity.title)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Activity: \(activity.title)")
  }

  private var color: Color {
    switch activity {
    case .active: CorewiseVisual.accent
    case .sustained: CorewiseVisual.warning
    case .quiet, .notObserved: .secondary
    }
  }
}

private struct AIWorkloadsEmptyState: View {
  var query: String

  var body: some View {
    if query.isEmpty {
      ContentUnavailableView(
        "No supported local AI workloads are currently observed",
        systemImage: "sparkles.rectangle.stack",
        description: Text("Corewise recognizes Codex, Claude, Cursor, Ollama, Windsurf, LM Studio, Gemini CLI, and Aider. Cloud activity is not included.")
      )
    } else {
      ContentUnavailableView.search(text: query)
    }
  }
}

private struct AIWorkloadInspector: View {
  var workload: AIWorkloadObservation
  var sessionSummary: AIWorkloadSessionSummary?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        PageHeader(title: workload.name, subtitle: "\(workload.supportLevel.title) local attribution", systemImage: "sparkles.rectangle.stack", compact: true)

        OperationalSection(title: "App footprint", instrument: true) {
          MetricRow(title: "Observed memory", value: corewiseBytes(workload.directObservedMemoryBytes))
          Divider()
          MetricRow(title: "Resident memory (RSS)", value: corewiseBytes(workload.directResidentMemoryBytes))
          Divider()
          MetricRow(title: "Physical footprint", value: workload.directPhysicalFootprintBytes.map(corewiseBytes) ?? "Unavailable")
          Divider()
          MetricRow(title: "CPU now", value: corewisePercent(workload.directCPUPercent))
        }

        OperationalSection(title: "Attribution boundary") {
          MetricRow(title: "Related local work", value: "\(corewiseBytes(workload.relatedObservedMemoryBytes)) · \(corewisePercent(workload.relatedCPUPercent)) CPU")
          Divider()
          MetricRow(title: "Shared host excluded", value: corewiseBytes(workload.sharedHostObservedMemoryBytes))
          Divider()
          Text("Cloud activity is not included. Process count is not an agent count.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }

        if let sessionSummary {
          OperationalSection(title: "Current observation", instrument: true) {
            MetricRow(title: "Peak memory", value: corewiseBytes(sessionSummary.peakMemoryBytes))
            Divider()
            MetricRow(title: "Average / peak CPU", value: "\(corewisePercent(sessionSummary.averageCPUPercent)) / \(corewisePercent(sessionSummary.maximumCPUPercent))")
            Divider()
            MetricRow(title: "Peak process count", value: String(sessionSummary.maximumProcessCount))
          }
        }

        OperationalSection(title: "Observed components") {
          ForEach(workload.attributions) { attribution in
            VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
              HStack {
                Text(attribution.process.displayName)
                  .fontWeight(.medium)
                Spacer()
                Text(attribution.role.title)
                  .foregroundStyle(.secondary)
              }
              Text("\(attribution.surface.title) · \(attribution.kind.rawValue) · \(corewiseBytes(attribution.process.observedMemoryBytes))")
                .font(.caption)
                .foregroundStyle(.secondary)
              if let path = attribution.process.path {
                Text(redactedPath(path))
                  .font(.caption.monospaced())
                  .foregroundStyle(.tertiary)
                  .textSelection(.enabled)
              }
            }
            .accessibilityElement(children: .combine)
            if attribution.id != workload.attributions.last?.id { Divider() }
          }
        }

        SourceDisclosure(title: "AI workload attribution", detail: "Exact bundle and executable evidence is evaluated before bounded parent-process ancestry. Shared hosts remain separate; arguments, environment, working directories, prompts, and project names are never read.")
      }
      .padding(CorewiseLayout.space16)
    }
  }

  private func redactedPath(_ path: String) -> String {
    path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
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
    case .aiWorkloads:
      EmptyView()
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
    case .aiWorkloads:
      "AI Workloads separates directly identified processes from attributable descendants and shared hosts."
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
  PerformanceView(performance: PreviewFixtures.performance, store: PreviewFixtures.store, focusedCheckSession: nil, requestedMode: .cpu, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — memory") {
  PerformanceView(performance: PreviewFixtures.performance, store: PreviewFixtures.store, focusedCheckSession: nil, requestedMode: .memory, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — AI Workloads") {
  PerformanceView(performance: PreviewFixtures.performance, store: PreviewFixtures.store, focusedCheckSession: nil, requestedMode: .aiWorkloads, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — active Focused Check") {
  PerformanceView(performance: PreviewFixtures.performance, store: PreviewFixtures.store, focusedCheckSession: PreviewFixtures.focusedSession, requestedMode: .cpu, requestedFocus: nil)
    .frame(width: 1180, height: 800)
}

#Preview("Performance — empty") {
  var performance = PreviewFixtures.performance
  performance.processes = []
  performance.appGroups = []
  return PerformanceView(performance: performance, store: PreviewFixtures.store, focusedCheckSession: nil, requestedMode: .cpu, requestedFocus: nil)
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
