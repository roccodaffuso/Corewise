#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private let fileManager = FileManager.default
private let repositoryRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
private let iconsetURL = repositoryRoot.appendingPathComponent(".build/Corewise.iconset", isDirectory: true)
private let resourceURL = repositoryRoot.appendingPathComponent("Sources/Corewise/Resources/Corewise.icns")
private let previewURL = repositoryRoot.appendingPathComponent("docs/assets/corewise-app-icon.png")

private struct IconVariant {
  let filename: String
  let pixels: Int
}

private let variants = [
  IconVariant(filename: "icon_16x16.png", pixels: 16),
  IconVariant(filename: "icon_16x16@2x.png", pixels: 32),
  IconVariant(filename: "icon_32x32.png", pixels: 32),
  IconVariant(filename: "icon_32x32@2x.png", pixels: 64),
  IconVariant(filename: "icon_128x128.png", pixels: 128),
  IconVariant(filename: "icon_128x128@2x.png", pixels: 256),
  IconVariant(filename: "icon_256x256.png", pixels: 256),
  IconVariant(filename: "icon_256x256@2x.png", pixels: 512),
  IconVariant(filename: "icon_512x512.png", pixels: 512),
  IconVariant(filename: "icon_512x512@2x.png", pixels: 1024),
]

private let icnsChunks: [(type: String, pixels: Int)] = [
  ("icp4", 16),
  ("icp5", 32),
  ("icp6", 64),
  ("ic07", 128),
  ("ic08", 256),
  ("ic09", 512),
  ("ic10", 1024),
]

private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
  CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [red, green, blue, alpha])!
}

private func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
  let control = radius * 0.5522847498
  let path = CGMutablePath()
  path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
  path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
  path.addCurve(
    to: CGPoint(x: rect.maxX, y: rect.minY + radius),
    control1: CGPoint(x: rect.maxX - radius + control, y: rect.minY),
    control2: CGPoint(x: rect.maxX, y: rect.minY + radius - control)
  )
  path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
  path.addCurve(
    to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
    control1: CGPoint(x: rect.maxX, y: rect.maxY - radius + control),
    control2: CGPoint(x: rect.maxX - radius + control, y: rect.maxY)
  )
  path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
  path.addCurve(
    to: CGPoint(x: rect.minX, y: rect.maxY - radius),
    control1: CGPoint(x: rect.minX + radius - control, y: rect.maxY),
    control2: CGPoint(x: rect.minX, y: rect.maxY - radius + control)
  )
  path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
  path.addCurve(
    to: CGPoint(x: rect.minX + radius, y: rect.minY),
    control1: CGPoint(x: rect.minX, y: rect.minY + radius - control),
    control2: CGPoint(x: rect.minX + radius - control, y: rect.minY)
  )
  path.closeSubpath()
  return path
}

private func renderIcon(pixels: Int) throws -> Data {
  let scale = CGFloat(pixels) / 1024
  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
  guard let context = CGContext(
    data: nil,
    width: pixels,
    height: pixels,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  ) else {
    throw CocoaError(.fileWriteUnknown)
  }

  context.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))
  context.scaleBy(x: scale, y: scale)
  context.setAllowsAntialiasing(true)
  context.setShouldAntialias(true)

  let tileRect = CGRect(x: 72, y: 72, width: 880, height: 880)
  let tilePath = roundedRectPath(tileRect, radius: 212)

  context.saveGState()
  context.addPath(tilePath)
  context.clip()
  let backgroundGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0.035, 0.065, 0.075), color(0.055, 0.135, 0.145), color(0.025, 0.050, 0.058)] as CFArray,
    locations: [0, 0.48, 1]
  )!
  context.drawLinearGradient(
    backgroundGradient,
    start: CGPoint(x: 190, y: 910),
    end: CGPoint(x: 840, y: 120),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
  )

  context.restoreGState()

  context.addPath(tilePath)
  context.setStrokeColor(color(0.55, 0.92, 0.92, 0.20))
  context.setLineWidth(8)
  context.strokePath()

  let center = CGPoint(x: 512, y: 512)
  let outerRadius: CGFloat = 278
  context.setStrokeColor(color(0.83, 0.93, 0.93, 0.19))
  context.setLineWidth(18)
  context.strokeEllipse(in: CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2))

  context.saveGState()
  context.setShadow(offset: .zero, blur: 30, color: color(0.22, 0.88, 0.91, 0.34))
  context.setStrokeColor(color(0.25, 0.86, 0.89))
  context.setLineWidth(30)
  context.setLineCap(.round)
  context.addArc(center: center, radius: outerRadius, startAngle: .pi * 0.22, endAngle: .pi * 1.54, clockwise: false)
  context.strokePath()
  context.restoreGState()

  let innerRadius: CGFloat = 210
  context.setFillColor(color(0.025, 0.065, 0.075, 0.92))
  context.fillEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2))
  context.setStrokeColor(color(0.60, 0.95, 0.95, 0.14))
  context.setLineWidth(6)
  context.strokeEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2))

  let waveform = CGMutablePath()
  let points = [
    CGPoint(x: 300, y: 510),
    CGPoint(x: 380, y: 510),
    CGPoint(x: 420, y: 570),
    CGPoint(x: 466, y: 375),
    CGPoint(x: 522, y: 655),
    CGPoint(x: 570, y: 455),
    CGPoint(x: 610, y: 530),
    CGPoint(x: 660, y: 530),
    CGPoint(x: 704, y: 510),
    CGPoint(x: 724, y: 510),
  ]
  waveform.move(to: points[0])
  for point in points.dropFirst() {
    waveform.addLine(to: point)
  }

  context.saveGState()
  context.setShadow(offset: .zero, blur: 24, color: color(0.22, 0.88, 0.91, 0.55))
  context.addPath(waveform)
  context.setStrokeColor(color(0.37, 0.92, 0.93))
  context.setLineWidth(34)
  context.setLineJoin(.round)
  context.setLineCap(.round)
  context.strokePath()
  context.restoreGState()

  guard let image = context.makeImage() else {
    throw CocoaError(.fileWriteUnknown)
  }
  let representation = NSBitmapImageRep(cgImage: image)
  guard let png = representation.representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
  }
  return png
}

private func bigEndianBytes(_ value: Int) -> [UInt8] {
  let number = UInt32(value)
  return [
    UInt8((number >> 24) & 0xff),
    UInt8((number >> 16) & 0xff),
    UInt8((number >> 8) & 0xff),
    UInt8(number & 0xff),
  ]
}

private func makeICNS() throws -> Data {
  var body = Data()
  for chunk in icnsChunks {
    let png = try renderIcon(pixels: chunk.pixels)
    body.append(contentsOf: chunk.type.utf8)
    body.append(contentsOf: bigEndianBytes(png.count + 8))
    body.append(png)
  }

  var container = Data("icns".utf8)
  container.append(contentsOf: bigEndianBytes(body.count + 8))
  container.append(body)
  return container
}

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: previewURL.deletingLastPathComponent(), withIntermediateDirectories: true)

for variant in variants {
  try renderIcon(pixels: variant.pixels).write(to: iconsetURL.appendingPathComponent(variant.filename), options: .atomic)
}

try renderIcon(pixels: 1024).write(to: previewURL, options: .atomic)
try makeICNS().write(to: resourceURL, options: .atomic)

print("Generated \(resourceURL.path)")
print("Generated \(previewURL.path)")
