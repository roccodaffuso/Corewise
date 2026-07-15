// SPDX-License-Identifier: MPL-2.0

import Foundation
import Testing
@testable import Corewise

@Suite("AI workload attribution")
struct AIWorkloadAttributionTests {
  @Test func codexBarIsNotClassifiedAsCodex() {
    let processes = [process(pid: 10, name: "CodexBar", path: "/Applications/CodexBar.app/Contents/MacOS/CodexBar")]
    #expect(AIWorkloadResolver.resolve(processes: processes).isEmpty)
  }

  @Test func embeddedCodexAndSharedChatGPTHostRemainSeparate() throws {
    let processes = [
      process(pid: 10, name: "ChatGPT", path: "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT", memoryMB: 200),
      process(pid: 11, parentPID: 10, name: "Codex (Renderer)", path: "/Applications/ChatGPT.app/Contents/Frameworks/Codex Framework.framework/Helpers/Codex (Renderer).app/Contents/MacOS/Codex (Renderer)", memoryMB: 500)
    ]

    let codex = try #require(AIWorkloadResolver.resolve(processes: processes).first)
    #expect(codex.id == .codex)
    #expect(codex.directObservedMemoryBytes == 500 * 1024 * 1024)
    #expect(codex.sharedHostObservedMemoryBytes == 200 * 1024 * 1024)
    #expect(codex.attributions.first(where: { $0.process.pid == 10 })?.kind == .sharedHost)
  }

  @Test func nearestDirectAncestorOwnsRelatedWork() throws {
    let processes = [
      process(pid: 20, name: "codex", path: "/Applications/ChatGPT.app/Contents/Resources/codex"),
      process(pid: 21, parentPID: 20, name: "zsh", path: "/bin/zsh"),
      process(pid: 22, parentPID: 21, name: "swiftc", path: "/usr/bin/swiftc", memoryMB: 80)
    ]

    let codex = try #require(AIWorkloadResolver.resolve(processes: processes).first)
    #expect(codex.attributions.first(where: { $0.process.pid == 22 })?.kind == .descendant)
    #expect(codex.relatedObservedMemoryBytes >= 80 * 1024 * 1024)
  }

  @Test func directOllamaIdentityWinsOverCodexAncestry() throws {
    let processes = [
      process(pid: 30, name: "codex", path: "/Applications/ChatGPT.app/Contents/Resources/codex"),
      process(pid: 31, parentPID: 30, name: "ollama", path: "/usr/local/bin/ollama", memoryMB: 900)
    ]
    let workloads = AIWorkloadResolver.resolve(processes: processes)
    let ollama = try #require(workloads.first { $0.id == .ollama })
    let codex = try #require(workloads.first { $0.id == .codex })
    #expect(ollama.attributions.map(\.process.pid) == [31])
    #expect(!codex.attributions.contains { $0.process.pid == 31 })
  }

  @Test func missingParentAndCycleDoNotCreateAttribution() {
    let processes = [
      process(pid: 40, parentPID: 41, name: "swiftc", path: "/usr/bin/swiftc"),
      process(pid: 41, parentPID: 40, name: "zsh", path: "/bin/zsh")
    ]
    #expect(AIWorkloadResolver.resolve(processes: processes).isEmpty)
  }

  @Test func signingIdentityCanStrengthenVerifiedMatch() throws {
    var signed = process(pid: 42, name: "unknown", path: "/tmp/unknown")
    signed.signingIdentifier = "com.openai.codex"
    let codex = try #require(AIWorkloadResolver.resolve(processes: [signed]).first)
    #expect(codex.id == .codex)
    #expect(codex.attributions.first?.confidence == .high)
  }

  @Test func longParentChainResolvesWithoutRepeatedOwnershipScans() throws {
    var processes = [process(pid: 100, name: "codex", path: "/Applications/ChatGPT.app/Contents/Resources/codex")]
    for offset in 1...2_000 {
      processes.append(process(pid: Int32(100 + offset), parentPID: Int32(99 + offset), name: "tool\(offset)", path: "/usr/bin/tool\(offset)", memoryMB: 1))
    }
    let codex = try #require(AIWorkloadResolver.resolve(processes: processes).first)
    #expect(codex.processCount == 2_001)
  }
}

@Suite("AI workload observation")
struct AIWorkloadObservationTests {
  @Test func sessionIsBoundedAndChronological() throws {
    let start = Date(timeIntervalSince1970: 10_000)
    let tracker = FocusedCheckTracker()
    tracker.start(intent: .aiWorkloads, now: start)
    for index in 0...300 {
      let date = start.addingTimeInterval(Double(index * 2))
      tracker.ingest(sample(date: date, memoryMB: UInt64(100 + index)))
    }
    let summary = try #require(tracker.summary(now: start.addingTimeInterval(600)))
    let codex = try #require(summary.aiWorkloads.first)
    #expect(codex.sampleCount == 300)
    #expect(codex.firstObservedAt < codex.lastObservedAt)
    #expect(codex.peakMemoryBytes == 400 * 1024 * 1024)
  }

  @Test func disappearingToolEndsAtZeroWithoutLosingPeak() throws {
    let start = Date(timeIntervalSince1970: 20_000)
    let tracker = FocusedCheckTracker()
    tracker.start(intent: .aiWorkloads, now: start)
    tracker.ingest(sample(date: start, memoryMB: 600))
    tracker.ingest(FocusedCheckSample(timestamp: start.addingTimeInterval(60), cpuPercent: 10, memoryUsedPercent: 50, thermalLevel: .nominal, aiWorkloads: []))
    let summary = try #require(tracker.summary(now: start.addingTimeInterval(60)))
    let codex = try #require(summary.aiWorkloads.first)
    #expect(codex.peakMemoryBytes == 600 * 1024 * 1024)
    #expect(codex.finalMemoryBytes == 0)
  }

  @Test func resolverUsesNonCausalThermalLanguage() throws {
    let start = Date(timeIntervalSince1970: 30_000)
    let tracker = FocusedCheckTracker()
    tracker.start(intent: .aiWorkloads, now: start)
    for index in 0..<6 {
      var value = sample(date: start.addingTimeInterval(Double(index * 15)), memoryMB: 500)
      value.thermalLevel = .serious
      tracker.ingest(value)
    }
    let result = FocusedCheckResolver.resolve(try #require(tracker.summary(now: start.addingTimeInterval(75))))
    #expect(result.detail.localizedCaseInsensitiveContains("coincided"))
    #expect(!result.detail.localizedCaseInsensitiveContains("caused"))
  }

  @Test func copiedResultOmitsProcessIdentityAndPaths() {
    let start = Date(timeIntervalSince1970: 40_000)
    let summary = AIWorkloadSessionSummary(
      workloadID: .codex,
      name: "Codex",
      sampleCount: 30,
      firstObservedAt: start,
      lastObservedAt: start.addingTimeInterval(60),
      averageCPUPercent: 20,
      maximumCPUPercent: 50,
      initialMemoryBytes: 100,
      finalMemoryBytes: 200,
      peakMemoryBytes: 300,
      peakRelatedMemoryBytes: 50,
      maximumProcessCount: 5,
      activity: .sustained
    )
    let result = FocusedCheckResult(
      intent: .aiWorkloads,
      state: .review,
      headline: "Observed Codex",
      detail: "Cloud activity is not included.",
      evidence: [],
      primaryAction: FocusedCheckAction(title: "Review", detail: "Review AI Workloads", destination: nil),
      observationStartedAt: start,
      observationEndedAt: start.addingTimeInterval(60),
      coverage: "Local only",
      generatedAt: start.addingTimeInterval(60),
      aiWorkloads: [summary]
    )
    let report = DiagnosticReportBuilder().focusedCheckMarkdown(for: result)
    #expect(report.contains("Codex"))
    #expect(!report.contains("PID"))
    #expect(!report.contains("/Users/"))
    #expect(!report.contains("project"))
  }


  @Test @MainActor func aiSessionAutoCompletesAtTenMinutesEvenWhenNoToolIsObserved() {
    let start = Date(timeIntervalSince1970: 50_000)
    let session = FocusedCheckSession(intent: .aiWorkloads, now: start)
    let summary = FocusedCheckAggregateSummary(intent: .aiWorkloads, startedAt: start, endedAt: start.addingTimeInterval(600))
    #expect(HealthDashboardStore.shouldAutoCompleteFocusedCheck(session: session, summary: summary, state: .unavailable))
    let early = FocusedCheckAggregateSummary(intent: .aiWorkloads, startedAt: start, endedAt: start.addingTimeInterval(599))
    #expect(!HealthDashboardStore.shouldAutoCompleteFocusedCheck(session: session, summary: early, state: .unavailable))
  }
}

private func process(
  pid: Int32,
  parentPID: Int32 = 1,
  name: String,
  path: String,
  cpu: Double = 1,
  memoryMB: UInt64 = 32
) -> ProcessObservation {
  ProcessObservation(
    pid: pid,
    processName: name,
    displayName: name,
    appName: nil,
    path: path,
    user: "tester",
    parentPID: parentPID,
    cpuSampleAvailable: true,
    cpuPercent: cpu,
    cpuTimeSeconds: 1,
    threadCount: 1,
    residentMemoryBytes: memoryMB * 1024 * 1024,
    physicalFootprintBytes: memoryMB * 1024 * 1024,
    pageIns: 0,
    dataMode: .live,
    status: .info,
    severityScore: 1,
    explanation: "Fixture",
    source: "Sanitized fixture",
    confidence: "Live / high",
    recommendedAction: "Review",
    lastUpdated: Date(timeIntervalSince1970: 1)
  )
}

private func sample(date: Date, memoryMB: UInt64) -> FocusedCheckSample {
  let workload = AIWorkloadResolver.resolve(processes: [
    process(pid: 50, name: "codex", path: "/Applications/ChatGPT.app/Contents/Resources/codex", cpu: 30, memoryMB: memoryMB)
  ])
  return FocusedCheckSample(timestamp: date, cpuPercent: 30, memoryUsedPercent: 50, thermalLevel: .nominal, aiWorkloads: workload)
}
