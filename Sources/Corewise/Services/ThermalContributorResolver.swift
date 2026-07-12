import Foundation

enum ThermalContributorResolver {
  static func contributors(
    stateLabel: String,
    status: FindingSeverity,
    severityScore: Int,
    hasSustainedCPU: Bool
  ) -> [DiagnosticFinding] {
    var findings = [
      DiagnosticFinding(
        title: "Thermal state is \(stateLabel.lowercased())",
        detail: "The safe public signal is read from ProcessInfo.",
        status: status,
        severityScore: severityScore
      ),
      DiagnosticFinding(
        title: "Low-level readings are intentionally absent",
        detail: "Corewise avoids unsupported hardware APIs and does not infer temperature.",
        status: .info,
        severityScore: 0
      )
    ]

    if (status == .warning || status == .critical) && hasSustainedCPU {
      findings.append(
        DiagnosticFinding(
          title: "Coincident sustained CPU activity",
          detail: "Repeated CPU activity appeared in the same recent window. This is correlation, not proof of thermal cause.",
          status: .info,
          severityScore: 30
        )
      )
    }
    return findings
  }
}
