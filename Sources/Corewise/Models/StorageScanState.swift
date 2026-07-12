import Foundation

enum StorageResultMode: String, CaseIterable, Identifiable, Sendable {
  case categories = "What Uses Space"
  case files = "Largest Files"
  case folders = "Largest Folders"

  var id: String { rawValue }
}

struct StorageScanProgress: Equatable, Sendable {
  var currentScope: String
  var scopeIndex: Int
  var scopeCount: Int
  var scannedFiles: Int
  var scannedFolders: Int
  var unreadableCount: Int
  var elapsed: TimeInterval

  var scopeLabel: String {
    "Scope \(scopeIndex) of \(max(scopeCount, 1))"
  }
}

enum StorageScanPhase: Equatable, Sendable {
  case idle
  case accessRequired
  case ready
  case scanning(StorageScanProgress)
  case result
  case failed(String)
  case cancelled
}
