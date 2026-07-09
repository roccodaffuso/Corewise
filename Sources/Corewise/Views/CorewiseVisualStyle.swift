import SwiftUI

enum CorewiseVisual {
  static let accent = Color(red: 0.20, green: 0.50, blue: 0.56)
  static let accentSoft = Color(red: 0.50, green: 0.70, blue: 0.68)
  static let moss = Color(red: 0.42, green: 0.58, blue: 0.44)
  static let amber = Color(red: 0.78, green: 0.55, blue: 0.28)
  static let graphite = Color(red: 0.18, green: 0.19, blue: 0.18)
  static let stone = Color(red: 0.57, green: 0.58, blue: 0.55)
  static let critical = Color(red: 0.74, green: 0.27, blue: 0.25)

  static let heroRadius: CGFloat = 16
  static let panelRadius: CGFloat = 13
  static let tileRadius: CGFloat = 11
  static let tableRadius: CGFloat = 9

  static var appBackground: some ShapeStyle {
    LinearGradient(
      colors: [
        accentSoft.opacity(0.10),
        Color.clear,
        moss.opacity(0.055)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static func pageWash(colorScheme: ColorScheme) -> some ShapeStyle {
    LinearGradient(
      colors: colorScheme == .dark
        ? [
          Color.white.opacity(0.020),
          accent.opacity(0.030),
          moss.opacity(0.018)
        ]
        : [
          Color.white.opacity(0.26),
          accentSoft.opacity(0.085),
          moss.opacity(0.045)
        ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static func panelFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.060)
      : Color.white.opacity(0.62)
  }

  static func tileFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.050)
      : Color.white.opacity(0.46)
  }

  static func heroFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.070)
      : Color.white.opacity(0.70)
  }

  static func tableRowFill(colorScheme: ColorScheme, isAlternating: Bool) -> Color {
    guard isAlternating else {
      return .clear
    }
    return colorScheme == .dark
      ? Color.white.opacity(0.034)
      : Color.black.opacity(0.026)
  }

  static func sidebarSelectionFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? accentSoft.opacity(0.115)
      : accent.opacity(0.095)
  }

  static func sidebarHoverFill(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.055)
      : Color.black.opacity(0.035)
  }

  static func hairline(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.white.opacity(0.115)
      : Color.black.opacity(0.080)
  }

  static func softShadow(colorScheme: ColorScheme) -> Color {
    colorScheme == .dark
      ? Color.black.opacity(0.20)
      : Color.black.opacity(0.075)
  }
}

enum CorewiseLayout {
  static let contentMaxWidth: CGFloat = 1160
  static let contentPadding: CGFloat = 28
  static let pageSpacing: CGFloat = 18
  static let panelSpacing: CGFloat = 14
  static let tileSpacing: CGFloat = 10
  static let panelMinWidth: CGFloat = 380
  static let metricMinWidth: CGFloat = 216
  static let accessMinWidth: CGFloat = 260
  static let heroMinHeight: CGFloat = 154
  static let metricMinHeight: CGFloat = 96
  static let metricDetailMinHeight: CGFloat = 136
  static let sidebarRowHeight: CGFloat = 48
  static let tableRowHeight: CGFloat = 44

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
