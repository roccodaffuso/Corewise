#!/usr/bin/env swift
// SPDX-License-Identifier: MPL-2.0

import AppKit

private let canvasSize = NSSize(width: 1_280, height: 640)

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

private func drawText(
    _ text: String,
    in rect: NSRect,
    font: NSFont,
    color: NSColor,
    lineHeight: CGFloat? = nil
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }

    text.draw(
        in: rect,
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
    )
}

private func drawSignalField() {
    let accent = color(0x55D6D9)

    for index in 0..<6 {
        let path = NSBezierPath()
        path.lineWidth = index == 2 ? 2 : 1
        let baseY = CGFloat(80 + index * 92)
        path.move(to: NSPoint(x: 0, y: baseY))

        for x in stride(from: CGFloat(0), through: canvasSize.width, by: 16) {
            let wave = sin((x / 72) + CGFloat(index) * 0.8) * CGFloat(8 + index * 2)
            let pulse = exp(-pow((x - 470) / 115, 2)) * sin(x / 13) * 30
            path.line(to: NSPoint(x: x, y: baseY + wave + pulse))
        }

        accent.withAlphaComponent(index == 2 ? 0.16 : 0.055).setStroke()
        path.stroke()
    }

    for x in stride(from: CGFloat(44), through: canvasSize.width, by: 84) {
        color(0x9FE9E8, alpha: 0.055).setFill()
        NSBezierPath(ovalIn: NSRect(x: x, y: 30, width: 2, height: 2)).fill()
    }
}

private func drawBadge(_ text: String, x: CGFloat, width: CGFloat) {
    let rect = NSRect(x: x, y: 72, width: width, height: 40)
    let shape = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
    color(0x55D6D9, alpha: 0.09).setFill()
    shape.fill()
    color(0x55D6D9, alpha: 0.24).setStroke()
    shape.lineWidth = 1
    shape.stroke()

    drawText(
        text,
        in: NSRect(x: x + 15, y: 80, width: width - 30, height: 24),
        font: .systemFont(ofSize: 15, weight: .semibold),
        color: color(0xA9C3C2)
    )
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(
        Data("Usage: swift script/generate_social_preview.swift <overview.png> <output.jpg>\n".utf8)
    )
    exit(64)
}

guard let screenshot = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("Unable to read overview screenshot.\n".utf8))
    exit(66)
}

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ),
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
else {
    FileHandle.standardError.write(Data("Unable to create social preview canvas.\n".utf8))
    exit(70)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

NSGradient(
    starting: color(0x061011),
    ending: color(0x102322)
)?.draw(in: NSRect(origin: .zero, size: canvasSize), angle: 0)

drawSignalField()

let glow = NSBezierPath(ovalIn: NSRect(x: 420, y: 130, width: 620, height: 620))
color(0x55D6D9, alpha: 0.045).setFill()
glow.fill()

let screenshotRect = NSRect(x: 590, y: 62, width: 780, height: 542)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = color(0x000000, alpha: 0.7)
shadow.shadowBlurRadius = 32
shadow.shadowOffset = NSSize(width: 0, height: -14)
shadow.set()
let screenshotFrame = NSBezierPath(roundedRect: screenshotRect, xRadius: 25, yRadius: 25)
color(0x071011).setFill()
screenshotFrame.fill()
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.saveGraphicsState()
screenshotFrame.addClip()
screenshot.draw(
    in: screenshotRect,
    from: NSRect(origin: .zero, size: screenshot.size),
    operation: .sourceOver,
    fraction: 1,
    respectFlipped: true,
    hints: [.interpolation: NSImageInterpolation.high]
)
NSGraphicsContext.restoreGraphicsState()

color(0x7AE3E3, alpha: 0.27).setStroke()
screenshotFrame.lineWidth = 1
screenshotFrame.stroke()

let accentLine = NSBezierPath()
accentLine.lineWidth = 3
accentLine.move(to: NSPoint(x: 72, y: 566))
accentLine.line(to: NSPoint(x: 156, y: 566))
color(0x55D6D9).setStroke()
accentLine.stroke()

drawText(
    "COREWISE  /  LOCAL SIGNAL CONSOLE",
    in: NSRect(x: 72, y: 526, width: 460, height: 28),
    font: .systemFont(ofSize: 16, weight: .bold),
    color: color(0x80DCDD)
)

drawText(
    "Know what your Mac is really doing.",
    in: NSRect(x: 68, y: 278, width: 485, height: 225),
    font: .systemFont(ofSize: 58, weight: .semibold),
    color: color(0xF3F7F6),
    lineHeight: 64
)

drawText(
    "Local-first diagnostics for performance, storage, and AI workloads.",
    in: NSRect(x: 72, y: 154, width: 440, height: 82),
    font: .systemFont(ofSize: 22, weight: .regular),
    color: color(0xA9B9B8),
    lineHeight: 30
)

drawBadge("macOS 14+", x: 72, width: 125)
drawBadge("Open source", x: 211, width: 145)
drawBadge("Local by design", x: 370, width: 164)

NSGraphicsContext.restoreGraphicsState()

guard
    let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.88])
else {
    FileHandle.standardError.write(Data("Unable to render social preview.\n".utf8))
    exit(70)
}

do {
    try data.write(to: URL(fileURLWithPath: arguments[2]), options: .atomic)
} catch {
    FileHandle.standardError.write(Data("Unable to write social preview: \(error)\n".utf8))
    exit(74)
}
