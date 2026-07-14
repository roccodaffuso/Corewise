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
