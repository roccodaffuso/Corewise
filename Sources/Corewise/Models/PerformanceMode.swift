import Foundation

enum PerformanceMode: String, CaseIterable, Identifiable, Sendable {
  case cpu
  case memory

  var id: String { rawValue }
  var title: String { rawValue.capitalized }
}
