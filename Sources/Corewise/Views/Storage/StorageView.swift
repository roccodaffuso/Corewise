import AppKit
import SwiftUI

struct StorageView: View {
  var storage: StorageHealth
  @ObservedObject var store: HealthDashboardStore
  var requestedFocus: DashboardFocus? = nil
  @State private var resultMode: StorageResultMode = .categories

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: CorewiseLayout.space24) {
        PageHeader(
          title: "Storage",
          subtitle: "Volume headroom first. File details appear only after an approved read-only scan.",
          systemImage: "internaldrive"
        )

        StorageVolumeSection(storage: storage)
        StorageScanControl(store: store)

        if let session = store.storageScanSession {
          StorageResultsSection(session: session, storage: storage, mode: $resultMode, store: store)
        }

        SourceDisclosure(
          title: "Storage data & privacy",
          detail: "\(storage.sourceNote) Current source: \(store.storageAnalysisSource). \(store.storageAccessSummary)"
        )
      }
      .padding(CorewiseLayout.pagePadding)
      .frame(maxWidth: CorewiseLayout.contentMaxWidth, alignment: .leading)
    }
    .onAppear { apply(requestedFocus) }
    .onChange(of: requestedFocus) { _, focus in apply(focus) }
  }

  private func apply(_ focus: DashboardFocus?) {
    switch focus {
    case .storageCategory:
      resultMode = .categories
    case let .storagePath(path):
      if store.storageScanSession?.result.largestFolders.contains(where: { $0.path == path }) == true {
        resultMode = .folders
      } else {
        resultMode = .files
      }
    case .process, .appGroup, nil:
      break
    }
  }
}

private struct StorageVolumeSection: View {
  var storage: StorageHealth

  var body: some View {
    OperationalSection(title: "Startup volume", subtitle: storage.summary.explanation, instrument: true) {
      HStack(alignment: .center, spacing: CorewiseLayout.space20) {
        ZStack {
          RoundedRectangle(cornerRadius: CorewiseVisual.controlRadius)
            .fill(CorewiseVisual.accent.opacity(0.10))
          Image(systemName: "internaldrive.fill")
            .font(.title2)
            .foregroundStyle(CorewiseVisual.accent)
        }
        .frame(width: 52, height: 52)
        .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text("AVAILABLE")
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
          Text("\(corewiseNumber(storage.availableGB)) GB available")
            .font(.title.monospacedDigit())
            .fontWeight(.semibold)
          Text("\(corewiseNumber(storage.usedGB)) GB used of \(corewiseNumber(storage.totalGB)) GB")
            .foregroundStyle(.secondary)
        }
        Spacer()
        SeverityBadge(severity: storage.summary.status)
      }

      CorewiseUsageBar(
        value: storage.usedGB,
        total: max(storage.totalGB, 1),
        color: CorewiseVisual.color(for: storage.summary.status)
      )
        .accessibilityLabel("Startup volume used space")
        .accessibilityValue("\(corewiseNumber(storage.usedGB)) gigabytes used of \(corewiseNumber(storage.totalGB))")

      HStack {
        Label("Used", systemImage: "circle.fill")
          .foregroundStyle(CorewiseVisual.color(for: storage.summary.status))
        Spacer()
        Text("\(corewiseNumber(storage.totalGB > 0 ? storage.usedGB / storage.totalGB * 100 : 0))% occupied")
          .monospacedDigit()
      }
      .font(.callout)
      .foregroundStyle(.secondary)
    }
  }
}

private struct CorewiseUsageBar: View {
  var value: Double
  var total: Double
  var color: Color

  private var fraction: Double {
    min(max(value / max(total, 1), 0), 1)
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(CorewiseVisual.quietSurface)
        Capsule()
          .fill(color)
          .frame(width: geometry.size.width * fraction)
      }
    }
    .frame(height: 9)
  }
}

private struct StorageScanControl: View {
  @ObservedObject var store: HealthDashboardStore

  var body: some View {
    OperationalSection(title: "Storage analysis", subtitle: "Local, read-only, and limited to approved scopes.", instrument: store.isScanningStorage) {
      switch store.storageScanPhase {
      case let .scanning(progress):
        StorageProgressView(progress: progress, cancel: store.cancelStorageScan)
      case let .failed(message):
        StorageFailedState(message: message) {
          Task { await store.checkStorageAccessAndRescan() }
        }
        Divider()
        accessControls
      case .cancelled:
        StorageCancelledState()
        accessControls
      default:
        accessControls
      }
    }
  }

  @ViewBuilder
  private var accessControls: some View {
    switch store.storageAccessStatus {
    case .fullDiskAccessLikelyGranted:
      StorageAccessStatusView(
        title: "Full Storage Analysis enabled",
        detail: "Corewise can reuse this permission whenever you start a read-only analysis. No folder selection is required.",
        systemImage: "checkmark.shield.fill",
        color: CorewiseVisual.good
      )
      Button(store.storageScanSession == nil ? "Start Analysis" : "Scan Again", systemImage: "internaldrive") {
        Task { await store.checkStorageAccessAndRescan() }
      }
      .buttonStyle(.borderedProminent)

    case .folderScopeGranted:
      StorageAccessStatusView(
        title: "One limited folder is remembered",
        detail: "Corewise will reuse \(store.rememberedStorageScopeTitle ?? "the approved folder") without asking again.",
        systemImage: "folder.badge.checkmark",
        color: CorewiseVisual.accent
      )
      HStack(spacing: CorewiseLayout.space8) {
        Button("Rescan Folder", systemImage: "arrow.clockwise") {
          Task { await store.checkStorageAccessAndRescan() }
        }
        .buttonStyle(.borderedProminent)
        Button("Use Full Disk Access", systemImage: "lock.shield", action: store.requestFullStorageAnalysisAccess)
        Button("Forget Folder", systemImage: "xmark", action: store.forgetLimitedStorageScope)
      }

    case .notRequested, .needsFullDiskAccess, .unavailable:
      FullStorageAccessSetup(store: store)
    }
  }
}

private struct StorageFailedState: View {
  var message: String
  var retry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
      Label(message, systemImage: "exclamationmark.triangle")
        .foregroundStyle(CorewiseVisual.warning)
      Button("Try Again", systemImage: "arrow.clockwise", action: retry)
    }
  }
}

private struct StorageCancelledState: View {
  var body: some View {
    Label("Scan cancelled. The last completed result was kept.", systemImage: "stop.circle")
      .foregroundStyle(.secondary)
  }
}

private struct FullStorageAccessSetup: View {
  @ObservedObject var store: HealthDashboardStore

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space16) {
      StorageAccessStatusView(
        title: store.isAwaitingFullDiskAccess ? "Waiting for one-time access" : "Enable once, scan without prompts",
        detail: store.isAwaitingFullDiskAccess
          ? "Finish enabling Corewise in System Settings, then return here. Corewise checks automatically and starts the analysis."
          : "Full Disk Access lets Corewise analyze its curated standard scopes locally without asking for each folder.",
        systemImage: store.isAwaitingFullDiskAccess ? "hourglass.circle" : "lock.shield",
        color: CorewiseVisual.accent
      )

      HStack(spacing: CorewiseLayout.space8) {
        Button(
          store.isAwaitingFullDiskAccess ? "Open Full Disk Access Again" : "Enable Full Storage Analysis",
          systemImage: "arrow.up.forward.app",
          action: store.requestFullStorageAnalysisAccess
        )
        .buttonStyle(.borderedProminent)

        if store.isAwaitingFullDiskAccess {
          Button("Check Now", systemImage: "arrow.clockwise") {
            Task { await store.checkStorageAccessAndRescan() }
          }
        }
      }

      DisclosureGroup("Prefer limited access?") {
        VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
          Text("Choose one folder once. Corewise stores a security-scoped bookmark and reuses that same read-only scope for later scans.")
            .font(.callout)
            .foregroundStyle(.secondary)
          Button("Choose One Folder Once", systemImage: "folder.badge.plus") {
            Task { await store.chooseLimitedStorageScope() }
          }
        }
        .padding(.top, CorewiseLayout.space8)
      }
    }
  }
}

private struct StorageAccessStatusView: View {
  var title: String
  var detail: String
  var systemImage: String
  var color: Color

  var body: some View {
    HStack(alignment: .top, spacing: CorewiseLayout.space12) {
      Image(systemName: systemImage)
        .font(.title2)
        .foregroundStyle(color)
        .symbolRenderingMode(.hierarchical)
        .frame(width: 34)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
        Text(title)
          .font(.headline)
        Text(detail)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

private struct StorageProgressView: View {
  var progress: StorageScanProgress
  var cancel: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space12) {
      HStack {
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          Text(progress.scopeLabel)
            .font(.headline)
          Text(progress.currentScope)
            .foregroundStyle(.secondary)
        }
        Spacer()
        ProgressView()
          .controlSize(.small)
          .accessibilityLabel("Storage scan in progress")
      }

      HStack(spacing: CorewiseLayout.space24) {
        Label("\(progress.scannedFiles) files", systemImage: "doc")
        Label("\(progress.scannedFolders) folders", systemImage: "folder")
        Label("\(progress.unreadableCount) unreadable", systemImage: "lock")
        Label(Duration.seconds(progress.elapsed).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated)), systemImage: "clock")
      }
      .font(.callout)
      .foregroundStyle(.secondary)
      .monospacedDigit()

      Text("Corewise cannot know the total file count in advance, so it does not show a fabricated percentage.")
        .font(.callout)
        .foregroundStyle(.secondary)

      Button("Cancel Scan", systemImage: "stop", action: cancel)
    }
  }
}

private struct StorageResultsSection: View {
  var session: StorageScanSession
  var storage: StorageHealth
  @Binding var mode: StorageResultMode
  @ObservedObject var store: HealthDashboardStore

  var body: some View {
    let coverage = StorageCoverageResolver.resolve(
      volume: storage,
      result: session.result,
      accessStatus: store.storageAccessStatus,
      source: store.storageAnalysisSource
    )
    OperationalSection(title: "Results", subtitle: "\(session.result.rootPath) · \(session.result.lastUpdated.formatted(date: .abbreviated, time: .shortened))") {
      StorageCoverageStrip(coverage: coverage)

      if !isFullStorageAnalysis {
        ScrollView(.horizontal) {
          HStack(spacing: CorewiseLayout.space4) {
            ForEach(session.breadcrumbs) { breadcrumb in
              Button(breadcrumb.title) {
                Task { await store.scanStorageSessionFolder(breadcrumb.url) }
              }
              .buttonStyle(.link)
              if breadcrumb.id != session.breadcrumbs.last?.id {
                Image(systemName: "chevron.right")
                  .font(.callout)
                  .foregroundStyle(.tertiary)
              }
            }
          }
        }
      }

      Picker("Result group", selection: $mode) {
        ForEach(StorageResultMode.allCases) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)

      switch mode {
      case .categories:
        StorageCategoryRows(categories: session.result.categoryBreakdown)
      case .files:
        StorageItemRows(items: session.result.largestFiles, areFolders: false)
      case .folders:
        StorageItemRows(items: session.result.largestFolders, areFolders: true)
      }

      HStack {
        Text("\(session.result.scannedFileCount) files · \(session.result.scannedFolderCount) folders · \(session.result.inaccessibleItemCount) unreadable")
          .font(.callout)
          .foregroundStyle(.secondary)
          .monospacedDigit()
        Spacer()
        if !isFullStorageAnalysis {
          Button("Parent Folder", systemImage: "arrow.up") {
            Task { await store.scanStorageParentFolder() }
          }
        }
      }
    }
  }

  private var isFullStorageAnalysis: Bool {
    session.result.rootTitle == "Full Storage Analysis"
  }
}

private struct StorageCoverageStrip: View {
  var coverage: StorageCoverageSummary

  var body: some View {
    VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
      HStack {
        MetricRow(title: "Classified in approved scope", value: "\(corewiseNumber(coverage.classifiedApprovedScopeGB)) GB")
        Divider()
        MetricRow(title: "Outside this scan", value: "\(corewiseNumber(coverage.outsideApprovedScopeGB)) GB")
        Divider()
        MetricRow(title: "Inaccessible", value: String(coverage.inaccessibleItemCount))
      }
      ProgressView(value: coverage.classifiedApprovedScopeGB, total: max(coverage.volumeUsedGB, 1))
        .tint(CorewiseVisual.accent)
        .accessibilityLabel("Storage scan coverage")
        .accessibilityValue("\(corewiseNumber(coverage.classifiedApprovedScopeGB)) gigabytes classified of \(corewiseNumber(coverage.volumeUsedGB)) used")
      Text("\(coverage.scopeDescription). Outside this scan means unclassified by this result, not removable. Source: \(coverage.source).")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .padding(CorewiseLayout.space12)
    .background(CorewiseVisual.quietSurface, in: .rect(cornerRadius: CorewiseVisual.controlRadius))
  }
}

private struct StorageCategoryRows: View {
  var categories: [StorageCategorySummary]

  private var maximum: Double {
    max(categories.map(\.sizeGB).max() ?? 1, 1)
  }

  var body: some View {
    if categories.isEmpty {
      ContentUnavailableView("No categories", systemImage: "chart.bar", description: Text("No readable regular files were classified in this scope."))
    } else {
      ForEach(categories) { category in
        let attribution = StorageAttributionResolver.attribution(for: category.category)
        VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
          HStack {
            Text(category.title)
            Spacer()
            Text("\(corewiseNumber(category.sizeGB)) GB")
              .monospacedDigit()
          }
          ProgressView(value: category.sizeGB, total: maximum)
            .tint(categoryColor(category.title))
            .accessibilityLabel("\(category.title) share of classified storage")
            .accessibilityValue("\(corewiseNumber(category.sizeGB)) gigabytes; largest category is \(corewiseNumber(maximum)) gigabytes")
          Text("\(category.fileCount) files · \(category.folderCount) folders")
            .font(.callout)
            .foregroundStyle(.secondary)
          DisclosureGroup("\(attribution.ownerKind.title) · \(attribution.safeActionLabel)") {
            Text(attribution.explanation)
              .font(.callout)
              .foregroundStyle(.secondary)
              .padding(.top, CorewiseLayout.space4)
          }
        }
        .accessibilityElement(children: .contain)
        Divider()
      }
    }
  }

  private func categoryColor(_ title: String) -> Color {
    switch title.lowercased() {
    case let value where value.contains("app"):
      CorewiseVisual.accent
    case let value where value.contains("document"):
      CorewiseVisual.good
    case let value where value.contains("media") || value.contains("video") || value.contains("audio"):
      CorewiseVisual.warning
    case let value where value.contains("system"):
      Color.secondary
    default:
      CorewiseVisual.accentMuted
    }
  }
}

private struct StorageItemRows: View {
  var items: [StorageItem]
  var areFolders: Bool

  var body: some View {
    if items.isEmpty {
      ContentUnavailableView("No readable items", systemImage: "folder", description: Text("This scope did not return items for the selected group."))
    } else {
      ForEach(items) { item in
        let attribution = StorageAttributionResolver.attribution(for: item, isDirectory: areFolders)
        VStack(alignment: .leading, spacing: CorewiseLayout.space8) {
          HStack {
            VStack(alignment: .leading, spacing: CorewiseLayout.space4) {
              Text(item.title)
                .lineLimit(1)
              Text(item.path)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
            Text("\(corewiseNumber(item.sizeGB)) GB")
              .monospacedDigit()
            if FileManager.default.isReadableFile(atPath: fileURL(item.path).path) {
              Button("Reveal \(item.title) in Finder", systemImage: "folder") {
                NSWorkspace.shared.activateFileViewerSelecting([fileURL(item.path)])
              }
              .labelStyle(.iconOnly)
            }
          }
          DisclosureGroup("\(attribution.ownerKind.title) · \(attribution.safeActionLabel)") {
            Text(attribution.explanation)
              .font(.callout)
              .foregroundStyle(.secondary)
              .padding(.top, CorewiseLayout.space4)
          }
        }
        .accessibilityElement(children: .contain)
        Divider()
      }
    }
  }

  private func fileURL(_ path: String) -> URL {
    guard path.hasPrefix("~/") else { return URL(fileURLWithPath: path) }
    return FileManager.default.homeDirectoryForCurrentUser.appending(path: String(path.dropFirst(2)))
  }
}

#Preview("Storage — ready") {
  StorageView(storage: PreviewFixtures.storage, store: PreviewFixtures.store)
    .frame(width: 1180, height: 800)
}

#Preview("Storage — scanning") {
  OperationalSection(title: "Storage analysis", subtitle: "Local, read-only, and limited to approved scopes.", instrument: true) {
    StorageProgressView(
      progress: StorageScanProgress(
        currentScope: "Projects",
        scopeIndex: 2,
        scopeCount: 4,
        scannedFiles: 48_920,
        scannedFolders: 4_210,
        unreadableCount: 7,
        elapsed: 52
      ),
      cancel: {}
    )
  }
  .padding()
  .frame(width: 980)
}

#Preview("Storage — failed") {
  OperationalSection(title: "Storage analysis", subtitle: "The last completed result remains available.") {
    StorageFailedState(message: "The remembered folder could not be opened. The last completed result was kept.", retry: {})
  }
  .padding()
  .frame(width: 980)
}

#Preview("Storage — cancelled") {
  OperationalSection(title: "Storage analysis", subtitle: "Cancellation discards only the partial result.") {
    StorageCancelledState()
  }
  .padding()
  .frame(width: 980)
}

#Preview("Storage — result") {
  StorageResultsPreview()
    .frame(width: 1180, height: 800)
}

private struct StorageResultsPreview: View {
  @State private var mode: StorageResultMode = .categories

  var body: some View {
    ScrollView {
      StorageResultsSection(
        session: PreviewFixtures.storageScanSession,
        storage: PreviewFixtures.storage,
        mode: $mode,
        store: PreviewFixtures.store
      )
      .padding()
    }
  }
}
