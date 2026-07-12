import SwiftUI

struct CorewiseBackdrop: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    ZStack {
      CorewiseVisual.contentBackground

      if !reduceTransparency {
        Circle()
          .fill(CorewiseVisual.accent.opacity(colorScheme == .dark ? 0.075 : 0.05))
          .frame(width: 620, height: 620)
          .blur(radius: 110)
          .offset(x: 420, y: -330)

        Circle()
          .fill(CorewiseVisual.good.opacity(colorScheme == .dark ? 0.035 : 0.025))
          .frame(width: 460, height: 460)
          .blur(radius: 120)
          .offset(x: -360, y: 420)
      }

      CorewiseGridTexture(spacing: 32, dotSize: 1.15)
        .opacity(colorScheme == .dark ? 0.22 : 0.12)
        .mask {
          LinearGradient(colors: [.clear, .black, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
  }
}

struct CorewiseGridTexture: View {
  var spacing: Double = 24
  var dotSize: Double = 1

  var body: some View {
    Canvas { context, size in
      var x = 0.0
      while x <= size.width {
        var y = 0.0
        while y <= size.height {
          let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
          context.fill(Path(ellipseIn: rect), with: .color(CorewiseVisual.separator))
          y += spacing
        }
        x += spacing
      }
    }
    .accessibilityHidden(true)
  }
}

struct CorewiseBrandGlyph: View {
  var size: Double = 42
  var stateColor: Color = CorewiseVisual.accent

  var body: some View {
    ZStack {
      Circle()
        .stroke(CorewiseVisual.separator, lineWidth: 1)
      Circle()
        .trim(from: 0.08, to: 0.72)
        .stroke(stateColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .rotationEffect(.degrees(-55))
      Circle()
        .fill(CorewiseVisual.elevatedSurface)
        .padding(size * 0.16)
      Image(systemName: "waveform.path.ecg")
        .font(.system(size: size * 0.31, weight: .semibold))
        .foregroundStyle(stateColor)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

struct CorewisePanelModifier: ViewModifier {
  var instrument: Bool
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.colorSchemeContrast) private var colorSchemeContrast

  func body(content: Content) -> some View {
    content
      .background {
        if instrument {
          CorewiseVisual.instrumentFill(colorScheme: colorScheme)
        } else {
          CorewiseVisual.contentSurface
        }
      }
      .clipShape(.rect(cornerRadius: CorewiseVisual.contentRadius))
      .overlay {
        RoundedRectangle(cornerRadius: CorewiseVisual.contentRadius)
          .stroke(borderColor, lineWidth: colorSchemeContrast == .increased ? 1.25 : 0.75)
      }
      .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.07), radius: 7, y: 3)
  }

  private var borderColor: Color {
    colorSchemeContrast == .increased ? Color.primary.opacity(0.34) : CorewiseVisual.surfaceHighlight
  }
}

struct CorewiseTableSurfaceModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.colorSchemeContrast) private var colorSchemeContrast

  func body(content: Content) -> some View {
    content
      .clipShape(.rect(cornerRadius: CorewiseVisual.contentRadius))
      .overlay {
        RoundedRectangle(cornerRadius: CorewiseVisual.contentRadius)
          .stroke(borderColor, lineWidth: colorSchemeContrast == .increased ? 1.25 : 0.75)
          .allowsHitTesting(false)
      }
      .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06), radius: 6, y: 3)
  }

  private var borderColor: Color {
    colorSchemeContrast == .increased ? Color.primary.opacity(0.34) : CorewiseVisual.surfaceHighlight
  }
}

extension View {
  func corewisePanel(instrument: Bool = false) -> some View {
    modifier(CorewisePanelModifier(instrument: instrument))
  }

  func corewiseTableSurface() -> some View {
    modifier(CorewiseTableSurfaceModifier())
  }
}
