import SwiftUI

enum CorewiseVisual {
  static let accent = Color(red: 0.18, green: 0.49, blue: 0.58)
  static let accentSoft = Color(red: 0.42, green: 0.70, blue: 0.66)
  static let moss = Color(red: 0.39, green: 0.57, blue: 0.43)
  static let amber = Color(red: 0.83, green: 0.58, blue: 0.27)

  static var appBackground: some ShapeStyle {
    LinearGradient(
      colors: [
        Color(nsColor: .windowBackgroundColor),
        Color(nsColor: .controlBackgroundColor).opacity(0.94),
        accentSoft.opacity(0.10)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static func panelFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.055)
      : Color.white.opacity(0.58)
  }

  static func tileFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.045)
      : Color.white.opacity(0.42)
  }

  static func hairline(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.10)
      : Color.black.opacity(0.08)
  }
}
