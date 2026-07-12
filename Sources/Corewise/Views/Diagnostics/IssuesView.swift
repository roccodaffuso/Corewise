import SwiftUI

struct IssuesView: View {
  var appIssues: AppIssuesHealth
  @ObservedObject var store: HealthDashboardStore
  @State private var selectedApp: String?
  @State private var selectedIssue: CrashIssue?
  @State private var isInspectorPresented = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space20) {
        PageHeader(title: "App Issues", subtitle: "Repeated crash metadata from a folder you explicitly choose.", systemImage: "app.badge")

        if store.isScanningReports {
          OperationalSection(title: "Reading reports", subtitle: "Metadata only. No stack traces are shown.") {
            HStack(spacing: CorewiseLayout.space12) {
              ProgressView()
                .controlSize(.small)
              Text("Reading report metadata…")
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
          }
        } else if appIssues.crashes.isEmpty {
          AppIssuesAccessPanel {
            Task { await store.scanCrashReportsFolder() }
          }
        } else {
          Table(appIssues.crashes, selection: $selectedApp) {
            TableColumn("App", value: \.appName)
            TableColumn("7 Days") { issue in
              CrashCountCell(count: issue.crashesLast7Days)
            }
              .width(70)
            TableColumn("30 Days") { issue in
              CrashCountCell(count: issue.crashesLast30Days)
            }
              .width(76)
            TableColumn("Last Occurrence") { issue in
              CrashDateCell(date: issue.lastCrashDate)
            }
              .width(min: 130, ideal: 160)
          }
          .accessibilityLabel("Crash report patterns")
          .frame(height: crashTableHeight)
          .corewiseTableSurface()
        }
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .inspector(isPresented: $isInspectorPresented) {
      if let selectedIssue {
        CrashIssueInspector(issue: selectedIssue)
          .inspectorColumnWidth(min: 260, ideal: 320, max: 380)
      } else {
        ContentUnavailableView("Select an app", systemImage: "cursorarrow.click")
          .inspectorColumnWidth(min: 260, ideal: 320, max: 380)
      }
    }
    .onChange(of: selectedApp) { _, app in
      guard let app, let issue = appIssues.crashes.first(where: { $0.appName == app }) else { return }
      selectedIssue = issue
      isInspectorPresented = true
    }
  }

  private var crashTableHeight: Double {
    min(max(Double(max(appIssues.crashes.count, 1)) * 32 + 54, 220), 520)
  }
}

private struct AppIssuesAccessPanel: View {
  var chooseReports: () -> Void

  var body: some View {
    OperationalSection(title: "Crash reports", subtitle: "Useful after consent. Quiet before that.") {
      HStack(alignment: .center, spacing: CorewiseLayout.space24) {
        ZStack {
          RoundedRectangle(cornerRadius: CorewiseVisual.contentRadius)
            .fill(CorewiseVisual.accent.opacity(0.12))
          Image(systemName: "doc.badge.plus")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(CorewiseVisual.accent)
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
          Text("No report folder selected")
            .font(.title2.weight(.semibold))
          Text("Corewise can summarize repeated crashes after you choose a DiagnosticReports folder. It reads app name, version, dates, and repetition only.")
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          HStack(spacing: CorewiseLayout.space12) {
            Label("No stack traces", systemImage: "text.badge.xmark")
            Label("Local only", systemImage: "lock")
            Label("User-selected", systemImage: "hand.tap")
          }
          .font(.callout)
          .foregroundStyle(.secondary)
        }

        Spacer(minLength: CorewiseLayout.space16)

        Button("Choose Reports", systemImage: "folder.badge.plus", action: chooseReports)
          .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
    }
  }
}

private struct CrashCountCell: View {
  var count: Int

  var body: some View {
    Text(count, format: .number)
      .monospacedDigit()
  }
}

private struct CrashDateCell: View {
  var date: Date

  var body: some View {
    Text(date, format: .dateTime.day().month().hour().minute())
  }
}

private struct CrashIssueInspector: View {
  var issue: CrashIssue

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
        PageHeader(title: issue.appName, subtitle: issue.repeatedCrash ? "Repeated pattern" : "Observed report", systemImage: "app.badge", compact: true)
        OperationalSection(title: "Report metadata") {
          MetricRow(title: "Bundle ID", value: issue.bundleID)
          Divider()
          MetricRow(title: "Version", value: issue.appVersion)
          Divider()
          MetricRow(title: "Last 7 days", value: String(issue.crashesLast7Days), severity: issue.status)
          Divider()
          MetricRow(title: "Last 30 days", value: String(issue.crashesLast30Days))
          Divider()
          MetricRow(title: "Last occurrence", value: issue.lastCrashDate.formatted(date: .abbreviated, time: .shortened))
          Divider()
          MetricRow(title: "Permission", value: issue.diagnosticPermissionState)
        }
        SourceDisclosure(title: "Interpretation", detail: "\(issue.explanation) Source: \(issue.source). \(issue.confidence). Raw crash bodies and stack traces stay out of Corewise.")
      }
      .padding(CorewiseLayout.space16)
    }
  }
}

#Preview("App Issues — permission") {
  IssuesView(appIssues: PreviewFixtures.appIssues, store: PreviewFixtures.store)
    .frame(width: 1180, height: 800)
}
