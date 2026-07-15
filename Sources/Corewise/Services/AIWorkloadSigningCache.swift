// SPDX-License-Identifier: MPL-2.0

import Foundation
import Security

actor AIWorkloadSigningCache {
  static let shared = AIWorkloadSigningCache()

  private struct CacheEntry: Sendable {
    var identifier: String?
  }

  private var entries: [String: CacheEntry] = [:]

  func identifiers(for paths: Set<String>) -> [String: String] {
    var result: [String: String] = [:]
    for path in paths {
      let target = AppProcessGroupingResolver.bundlePath(from: path) ?? path
      let entry: CacheEntry
      if let cached = entries[target] {
        entry = cached
      } else {
        entry = CacheEntry(identifier: Self.signingIdentifier(at: target))
        entries[target] = entry
      }
      if let identifier = entry.identifier {
        result[path] = identifier
      }
    }
    return result
  }

  private nonisolated static func signingIdentifier(at path: String) -> String? {
    var staticCode: SecStaticCode?
    guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, SecCSFlags(), &staticCode) == errSecSuccess,
          let staticCode else {
      return nil
    }
    var information: CFDictionary?
    guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
          let dictionary = information as? [CFString: Any] else {
      return nil
    }
    return dictionary[kSecCodeInfoIdentifier] as? String
  }
}
