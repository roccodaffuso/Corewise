import AppKit
import SwiftUI

struct MacWindowMaterialView: NSViewRepresentable {
  var material: NSVisualEffectView.Material = .underWindowBackground
  var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    view.wantsLayer = true
    return view
  }

  func updateNSView(_ view: NSVisualEffectView, context: Context) {
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
  }
}

struct WindowTransparencyConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView(frame: .zero)
    DispatchQueue.main.async {
      configure(window: view.window)
    }
    return view
  }

  func updateNSView(_ view: NSView, context: Context) {
    DispatchQueue.main.async {
      configure(window: view.window)
    }
  }

  private func configure(window: NSWindow?) {
    guard let window else {
      return
    }

    window.isOpaque = false
    window.backgroundColor = .clear
    window.titlebarAppearsTransparent = true
  }
}
