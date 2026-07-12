import Foundation

enum StorageAttributionResolver {
  static func attribution(for category: StorageCategory) -> StorageAttribution {
    switch category {
    case .applications:
      StorageAttribution(ownerKind: .application, explanation: corewiseText("Installed app bundles and files inside application paths. Review the app and its uninstaller before changing bundle contents.", comment: "Storage attribution explanation"), reviewClass: .reviewInOwningApp, safeActionLabel: corewiseText("Review app", comment: "Storage safe action"), confidence: .high)
    case .development:
      StorageAttribution(ownerKind: .developerData, explanation: corewiseText("Build products, dependencies, simulators, or source-related data. Review them in the tool or project that created them.", comment: "Storage attribution explanation"), reviewClass: .reviewInOwningApp, safeActionLabel: corewiseText("Review in developer tool", comment: "Storage safe action"), confidence: .medium)
    case .documents, .archivesInstallers:
      StorageAttribution(ownerKind: .userFiles, explanation: corewiseText("Files commonly managed directly by the user. Confirm their contents and backups in Finder.", comment: "Storage attribution explanation"), reviewClass: .userReview, safeActionLabel: corewiseText("Review in Finder", comment: "Storage safe action"), confidence: .medium)
    case .photos, .video, .music:
      StorageAttribution(ownerKind: .mediaLibrary, explanation: corewiseText("Media may belong to a Photos, Music, or video library. Review it in the owning app when it is library-managed.", comment: "Storage attribution explanation"), reviewClass: .reviewInOwningApp, safeActionLabel: corewiseText("Review in owning app", comment: "Storage safe action"), confidence: .medium)
    case .cacheTemporary:
      StorageAttribution(ownerKind: .cache, explanation: corewiseText("The path resembles cache or temporary data. Its category does not establish that removal is appropriate.", comment: "Storage attribution explanation"), reviewClass: .unknown, safeActionLabel: corewiseText("Inspect context", comment: "Storage safe action"), confidence: .medium)
    case .systemLike:
      StorageAttribution(ownerKind: .systemManaged, explanation: corewiseText("The path is managed by macOS or an app container. Corewise does not recommend modifying it directly.", comment: "Storage attribution explanation"), reviewClass: .systemManaged, safeActionLabel: corewiseText("Leave to macOS or owning app", comment: "Storage safe action"), confidence: .medium)
    case .other, .unreadable:
      StorageAttribution(ownerKind: .unknown, explanation: corewiseText("Corewise cannot assign a reliable owner from the available metadata. Inspect the path before making any change.", comment: "Storage attribution explanation"), reviewClass: .unknown, safeActionLabel: corewiseText("Inspect manually", comment: "Storage safe action"), confidence: .low)
    }
  }

  static func attribution(for item: StorageItem, isDirectory: Bool = false) -> StorageAttribution {
    let normalizedPath = expandedURL(item.path).standardizedFileURL.path.lowercased()
    if normalizedPath.contains("/library/application support/")
      || normalizedPath.contains("/library/containers/")
      || normalizedPath.contains("/library/group containers/") {
      return StorageAttribution(
        ownerKind: .applicationSupport,
        explanation: corewiseText("This path is managed as support or container data for an application. Review it through the owning app or its documented uninstall flow.", comment: "Storage attribution explanation"),
        reviewClass: .reviewInOwningApp,
        safeActionLabel: corewiseText("Review in owning app", comment: "Storage safe action"),
        confidence: .high
      )
    }
    let category = StorageCategoryClassifier().category(
      for: URL(fileURLWithPath: normalizedPath),
      isDirectory: isDirectory,
      isPackage: item.path.localizedCaseInsensitiveContains(".app"),
      contentType: nil
    )
    return attribution(for: category)
  }

  private static func expandedURL(_ path: String) -> URL {
    guard path.hasPrefix("~/") else {
      return URL(fileURLWithPath: path)
    }
    return FileManager.default.homeDirectoryForCurrentUser.appending(path: String(path.dropFirst(2)))
  }
}
