import AppKit
import SwiftUI

enum CorewiseVisual {
  static let accent = adaptive(
    name: "CorewiseAccent",
    dark: NSColor(srgbRed: 0.34, green: 0.80, blue: 0.82, alpha: 1),
    light: NSColor(srgbRed: 0.05, green: 0.43, blue: 0.47, alpha: 1)
  )
  static let accentBright = adaptive(
    name: "CorewiseAccentBright",
    dark: NSColor(srgbRed: 0.55, green: 0.91, blue: 0.87, alpha: 1),
    light: NSColor(srgbRed: 0.04, green: 0.53, blue: 0.55, alpha: 1)
  )
  static let accentMuted = adaptive(
    name: "CorewiseAccentMuted",
    dark: NSColor(srgbRed: 0.17, green: 0.48, blue: 0.49, alpha: 1),
    light: NSColor(srgbRed: 0.45, green: 0.72, blue: 0.71, alpha: 1)
  )
  static let good = adaptive(
    name: "CorewiseGood",
    dark: NSColor(srgbRed: 0.43, green: 0.75, blue: 0.52, alpha: 1),
    light: NSColor(srgbRed: 0.18, green: 0.48, blue: 0.27, alpha: 1)
  )
  static let warning = adaptive(
    name: "CorewiseWarning",
    dark: NSColor(srgbRed: 0.92, green: 0.66, blue: 0.32, alpha: 1),
    light: NSColor(srgbRed: 0.67, green: 0.37, blue: 0.08, alpha: 1)
  )
  static let critical = adaptive(
    name: "CorewiseCritical",
    dark: NSColor(srgbRed: 0.91, green: 0.38, blue: 0.36, alpha: 1),
    light: NSColor(srgbRed: 0.68, green: 0.16, blue: 0.15, alpha: 1)
  )
  static let info = accent

  static let windowBackground = adaptive(
    name: "CorewiseWindow",
    dark: NSColor(srgbRed: 0.055, green: 0.071, blue: 0.069, alpha: 1),
    light: NSColor(srgbRed: 0.92, green: 0.94, blue: 0.93, alpha: 1)
  )
  static let contentBackground = adaptive(
    name: "CorewiseContent",
    dark: NSColor(srgbRed: 0.071, green: 0.090, blue: 0.086, alpha: 1),
    light: NSColor(srgbRed: 0.95, green: 0.96, blue: 0.955, alpha: 1)
  )
  static let contentSurface = adaptive(
    name: "CorewiseSurface",
    dark: NSColor(srgbRed: 0.102, green: 0.129, blue: 0.122, alpha: 1),
    light: NSColor(srgbRed: 0.985, green: 0.99, blue: 0.987, alpha: 1)
  )
  static let elevatedSurface = adaptive(
    name: "CorewiseElevated",
    dark: NSColor(srgbRed: 0.135, green: 0.169, blue: 0.157, alpha: 1),
    light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
  )
  static let quietSurface = adaptive(
    name: "CorewiseQuiet",
    dark: NSColor(srgbRed: 0.078, green: 0.098, blue: 0.094, alpha: 1),
    light: NSColor(srgbRed: 0.94, green: 0.955, blue: 0.948, alpha: 1)
  )
  static let separator = adaptive(
    name: "CorewiseSeparator",
    dark: NSColor(white: 1, alpha: 0.105),
    light: NSColor(white: 0, alpha: 0.09)
  )
  static let surfaceHighlight = adaptive(
    name: "CorewiseSurfaceHighlight",
    dark: NSColor(white: 1, alpha: 0.075),
    light: NSColor(white: 1, alpha: 0.78)
  )

  static let contentRadius: Double = 14
  static let controlRadius: Double = 10
  static let transition = Animation.easeOut(duration: 0.20)
  static let quickTransition = Animation.easeOut(duration: 0.15)

  static func instrumentFill(colorScheme: ColorScheme) -> LinearGradient {
    LinearGradient(
      colors: colorScheme == .dark
        ? [elevatedSurface, contentSurface, quietSurface]
        : [elevatedSurface, contentSurface, quietSurface.opacity(0.92)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static func sidebarFill(colorScheme: ColorScheme) -> LinearGradient {
    LinearGradient(
      colors: colorScheme == .dark
        ? [Color.black.opacity(0.34), accent.opacity(0.045), Color.black.opacity(0.18)]
        : [Color.white.opacity(0.82), accent.opacity(0.035), Color.white.opacity(0.62)],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  static func color(for severity: FindingSeverity) -> Color {
    switch severity {
    case .good: good
    case .info: info
    case .warning: warning
    case .critical: critical
    }
  }

  static func color(for state: AttentionState) -> Color {
    switch state {
    case .clear: good
    case .review: warning
    case .critical: critical
    case .unavailable: Color.secondary
    }
  }

  private static func adaptive(name: String, dark: NSColor, light: NSColor) -> Color {
    Color(
      nsColor: NSColor(name: NSColor.Name(name)) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
      }
    )
  }
}

enum CorewiseLayout {
  static let space4: Double = 4
  static let space8: Double = 8
  static let space12: Double = 12
  static let space16: Double = 16
  static let space20: Double = 20
  static let space24: Double = 24
  static let space32: Double = 32
  static let contentMaxWidth: Double = 1180
  static let pagePadding: Double = 28
}
