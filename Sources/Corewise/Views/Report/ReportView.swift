// SPDX-License-Identifier: MPL-2.0

import AppKit
import SwiftUI

private enum ReportViewMode: String, CaseIterable, Identifiable {
  case summary = "Summary"
  case markdown = "Markdown"

  var id: String { rawValue }
}

#Preview("Report — summary") {
  ReportView(snapshot: PreviewFixtures.snapshot, focusedCheckResult: nil)
    .frame(width: 1180, height: 800)
}

struct ReportView: View {
  var snapshot: HealthSnapshot
  var focusedCheckResult: FocusedCheckResult?
  @AppStorage(CorewiseSettingsKeys.reportIncludeStorageScan) private var includeStorageScan = true
  @AppStorage(CorewiseSettingsKeys.reportIncludeCrashSummary) private var includeCrashSummary = true
  @State private var mode: ReportViewMode = .summary
  @State private var copied = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var options: DiagnosticReportOptions {
    DiagnosticReportOptions(includeStorageScan: includeStorageScan, includeCrashSummary: includeCrashSummary)
  }

  private var report: String {
    switch mode {
    case .summary: DiagnosticReportBuilder().summary(for: snapshot, options: options)
    case .markdown: DiagnosticReportBuilder().markdown(for: snapshot, options: options)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space20) {
        PageHeader(title: "Report", subtitle: "A local, copyable explanation without raw crash bodies or file contents.", systemImage: "doc.text.magnifyingglass")

        HStack {
          Picker("Report format", selection: $mode) {
            ForEach(ReportViewMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 260)
          Spacer()
          if copied {
            Label("Copied", systemImage: "checkmark")
              .foregroundStyle(CorewiseVisual.good)
              .transition(.opacity)
              .accessibilityLabel("Copy completed")
          }
          Button("Copy \(mode.rawValue)", systemImage: "doc.on.clipboard", action: copyReport)
          if focusedCheckResult != nil {
            Button("Copy Focused \(mode.rawValue)", systemImage: "scope", action: copyFocusedCheck)
          }
        }
        .padding(CorewiseLayout.space12)
        .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
        .overlay {
          RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
            .stroke(CorewiseVisual.separator, lineWidth: 1)
        }

        ReportDocumentPreview(report: report, mode: mode, generatedAt: snapshot.generatedAt)

        Label("Generated locally from the current snapshot. Nothing is uploaded.", systemImage: "lock.shield")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .animation(reduceMotion ? nil : CorewiseVisual.transition, value: copied)
  }

  private func copyReport() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(report, forType: .string)
    showCopiedFeedback()
  }

  private func copyFocusedCheck() {
    guard let focusedCheckResult else { return }
    let builder = DiagnosticReportBuilder()
    let focusedReport = switch mode {
    case .summary: builder.focusedCheckSummary(for: focusedCheckResult)
    case .markdown: builder.focusedCheckMarkdown(for: focusedCheckResult)
    }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(focusedReport, forType: .string)
    showCopiedFeedback()
  }

  private func showCopiedFeedback() {
    copied = true
    AccessibilityNotification.Announcement("Copied").post()
    Task {
      try? await Task.sleep(for: .seconds(1.5))
      copied = false
    }
  }
}

private struct ReportDocumentPreview: View {
  var report: String
  var mode: ReportViewMode
  var generatedAt: Date

  private var blocks: [String] {
    report
      .components(separatedBy: "\n\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
      HStack {
        Label("COREWISE / \(mode.rawValue.uppercased())", systemImage: "doc.text")
          .font(.caption.weight(.semibold))
          .tracking(0.7)
          .foregroundStyle(CorewiseVisual.accent)
        Spacer()
        Text(generatedAt.formatted(date: .abbreviated, time: .shortened))
          .font(.callout.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      Divider()

      ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
        ReportBlock(block: block, monospaced: mode == .markdown)
      }
    }
    .padding(CorewiseLayout.space24)
    .frame(maxWidth: 820, alignment: .leading)
    .frame(maxWidth: .infinity, alignment: .center)
    .corewisePanel()
    .textSelection(.enabled)
  }
}

private struct ReportBlock: View {
  var block: String
  var monospaced: Bool

  private var lines: [String] {
    block.components(separatedBy: .newlines)
  }

  private var heading: String? {
    guard let first = lines.first, !first.hasPrefix("-"), !first.hasPrefix("#") else { return nil }
    return first
  }

  private var bodyLines: [String] {
    heading == nil ? lines : Array(lines.dropFirst())
  }

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
      if let heading {
        Text(heading)
          .font(.headline)
      }
      if !bodyLines.isEmpty {
        Text(bodyLines.joined(separator: "\n"))
          .font(monospaced ? .body.monospaced() : .body)
          .lineSpacing(monospaced ? 3 : 6)
          .foregroundStyle(heading == nil ? .primary : .secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}
