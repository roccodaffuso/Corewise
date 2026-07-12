import Foundation

enum PerformanceMode: String, CaseIterable, Identifiable, Sendable {
  case cpu
  case memory
  case aiWorkloads

  var id: String { rawValue }
  var title: String {
    switch self {
    case .cpu: "CPU"
    case .memory: "Memory"
    case .aiWorkloads: "AI Workloads"
    }
  }
}
