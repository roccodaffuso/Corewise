import Foundation
import UniformTypeIdentifiers

struct StorageCategoryClassifier {
  func category(for url: URL, isDirectory: Bool, isPackage: Bool, contentType: UTType?) -> StorageCategory {
    category(
      normalizedPath: normalizedPath(url),
      pathExtension: url.pathExtension.lowercased(),
      isDirectory: isDirectory,
      isPackage: isPackage,
      contentType: contentType
    )
  }

  func category(
    normalizedPath path: String,
    pathExtension ext: String,
    isDirectory: Bool,
    isPackage: Bool,
    contentType: UTType?
  ) -> StorageCategory {

    if matchesAny(path, Self.developmentPathFragments) ||
      path.hasSuffix("/build") || path.contains("/build/") || path.contains(".xcarchive/") {
      return .development
    }

    if matchesAny(path, Self.cachePathFragments) ||
      path.contains("/library/developer/xcode/deriveddata/") {
      return .cacheTemporary
    }

    if path.hasPrefix("/applications/") || path.contains("/applications/") || ext == "app" || path.contains(".app/") {
      return .applications
    }

    if path.hasPrefix("/system/") || path.contains("/system/library/") || path.contains("/library/application support/") ||
      path.contains("/library/containers/") || path.contains("/library/group containers/") {
      return .systemLike
    }

    if path.contains("/pictures/") || path.contains("/photos library.") {
      return .photos
    }

    if path.contains("/movies/") {
      return .video
    }

    if path.contains("/music/") {
      return .music
    }

    if path.contains("/documents/") || path.contains("/desktop/") || path.contains("/downloads/") {
      if let typeCategory = categoryFromType(contentType) {
        return typeCategory
      }
      return .documents
    }

    if isPackage, ext == "app" {
      return .applications
    }

    if let typeCategory = categoryFromType(contentType) {
      return typeCategory
    }

    if archiveInstallerExtensions.contains(ext) {
      return .archivesInstallers
    }
    if videoExtensions.contains(ext) {
      return .video
    }
    if audioExtensions.contains(ext) {
      return .music
    }
    if imageExtensions.contains(ext) {
      return .photos
    }
    if documentExtensions.contains(ext) {
      return .documents
    }
    if developmentExtensions.contains(ext) {
      return .development
    }

    if isDirectory {
      return .other
    }
    return .other
  }

  private func categoryFromType(_ contentType: UTType?) -> StorageCategory? {
    guard let contentType else {
      return nil
    }

    if contentType.conforms(to: .applicationBundle) {
      return .applications
    }
    if contentType.conforms(to: .image) {
      return .photos
    }
    if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
      return .video
    }
    if contentType.conforms(to: .audio) {
      return .music
    }
    if contentType.conforms(to: .archive) || contentType.conforms(to: .diskImage) {
      return .archivesInstallers
    }
    if contentType.conforms(to: .sourceCode) {
      return .development
    }
    if contentType.conforms(to: .pdf) || contentType.conforms(to: .text) || contentType.conforms(to: .spreadsheet) ||
      contentType.conforms(to: .presentation) || contentType.conforms(to: .content) {
      return .documents
    }
    return nil
  }

  private func normalizedPath(_ url: URL) -> String {
    url.standardizedFileURL.path.lowercased()
  }

  private func matchesAny(_ path: String, _ fragments: [String]) -> Bool {
    fragments.contains { path.contains($0) }
  }

  private static let developmentPathFragments = [
    "/deriveddata/", "/coresimulator/", "/node_modules/", "/pods/", "/.gradle/", "/.swiftpm/", "/.build/"
  ]
  private static let cachePathFragments = ["/caches/", "/tmp/", "/temporaryitems/", "/com.apple.developer.tools/"]

  private let archiveInstallerExtensions: Set<String> = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "pkg", "iso"]
  private let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "mkv", "avi", "webm", "hevc"]
  private let audioExtensions: Set<String> = ["mp3", "wav", "aiff", "aac", "m4a", "flac", "ogg", "caf"]
  private let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "heic", "tiff", "webp", "raw", "svg", "psd"]
  private let documentExtensions: Set<String> = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md", "rtf", "pages", "numbers", "key", "csv", "json"]
  private let developmentExtensions: Set<String> = ["swift", "xcodeproj", "xcworkspace", "playground", "js", "ts", "tsx", "jsx", "py", "rb", "go", "rs", "java", "kt", "c", "cpp", "h", "hpp"]
}
