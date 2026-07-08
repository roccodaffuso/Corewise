import SwiftUI

enum CorewiseVisual {
  static let accent = Color(red: 0.18, green: 0.49, blue: 0.58)
  static let accentSoft = Color(red: 0.42, green: 0.70, blue: 0.66)
  static let moss = Color(red: 0.39, green: 0.57, blue: 0.43)
  static let amber = Color(red: 0.83, green: 0.58, blue: 0.27)

  static var appBackground: some ShapeStyle {
    LinearGradient(
      colors: [
        accentSoft.opacity(0.16),
        Color.clear,
        moss.opacity(0.08)
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

enum CorewiseLayout {
  static let contentMaxWidth: CGFloat = 1160
  static let contentPadding: CGFloat = 28
  static let pageSpacing: CGFloat = 20
  static let panelSpacing: CGFloat = 14
  static let tileSpacing: CGFloat = 10
  static let panelMinWidth: CGFloat = 380
  static let metricMinWidth: CGFloat = 216
  static let accessMinWidth: CGFloat = 260

  static var panelGrid: [GridItem] {
    [GridItem(.adaptive(minimum: panelMinWidth), spacing: panelSpacing, alignment: .top)]
  }

  static var metricGrid: [GridItem] {
    [GridItem(.adaptive(minimum: metricMinWidth), spacing: tileSpacing, alignment: .top)]
  }

  static var accessGrid: [GridItem] {
    [GridItem(.adaptive(minimum: accessMinWidth), spacing: tileSpacing, alignment: .top)]
  }
}
