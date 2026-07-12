import Foundation

enum StorageOwnerKind: String, CaseIterable, Sendable {
  case userFiles
  case application
  case applicationSupport
  case developerData
  case cache
  case mediaLibrary
  case systemManaged
  case unknown

  var title: String {
    switch self {
    case .userFiles: corewiseText("User-managed files", comment: "Storage owner kind")
    case .application: corewiseText("Application", comment: "Storage owner kind")
    case .applicationSupport: corewiseText("Application support", comment: "Storage owner kind")
    case .developerData: corewiseText("Developer data", comment: "Storage owner kind")
    case .cache: corewiseText("Cache or temporary", comment: "Storage owner kind")
    case .mediaLibrary: corewiseText("Media library", comment: "Storage owner kind")
    case .systemManaged: corewiseText("System-managed", comment: "Storage owner kind")
    case .unknown: corewiseText("Unknown owner", comment: "Storage owner kind")
    }
  }
}

enum StorageReviewClass: String, Sendable {
  case userReview
  case reviewInOwningApp
  case systemManaged
  case unknown
}

struct StorageAttribution: Equatable, Sendable {
  var ownerKind: StorageOwnerKind
  var explanation: String
  var reviewClass: StorageReviewClass
  var safeActionLabel: String
  var confidence: EvidenceConfidence
}

struct StorageCoverageSummary: Equatable, Sendable {
  var volumeUsedGB: Double
  var classifiedApprovedScopeGB: Double
  var outsideApprovedScopeGB: Double
  var coverageRatio: Double
  var inaccessibleItemCount: Int
  var scopeDescription: String
  var source: String
}
