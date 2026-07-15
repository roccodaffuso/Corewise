#!/usr/bin/env swift
// SPDX-License-Identifier: MPL-2.0

import AppKit

private let canvasSize = NSSize(width: 1_200, height: 675)

private struct LaunchCard {
    let filename: String
    let eyebrow: String
    let headline: String
    let body: String
    let chips: [String]
    let screenshot: NSImage
}

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

private func drawSignalField(accentY: CGFloat) {
    for index in 0..<7 {
        let path = NSBezierPath()
        path.lineWidth = index == 3 ? 1.8 : 1
        let baseY = CGFloat(58 + index * 92)
        path.move(to: NSPoint(x: 0, y: baseY))

        for x in stride(from: CGFloat(0), through: canvasSize.width, by: 14) {
            let wave = sin((x / 74) + CGFloat(index) * 0.9) * CGFloat(7 + index)
            let pulse = exp(-pow((x - 420) / 128, 2)) * sin(x / 12) * 24
            path.line(to: NSPoint(x: x, y: baseY + wave + pulse))
        }

        color(0x55D6D9, alpha: index == 3 ? 0.14 : 0.045).setStroke()
        path.stroke()
    }

    let guide = NSBezierPath()
    guide.lineWidth = 1
    guide.setLineDash([3, 7], count: 2, phase: 0)
    guide.move(to: NSPoint(x: 52, y: accentY))
    guide.line(to: NSPoint(x: canvasSize.width - 52, y: accentY))
    color(0x86E7E4, alpha: 0.13).setStroke()
    guide.stroke()
}

private func sourceRect(for image: NSImage, target: NSRect) -> NSRect {
    let sourceRatio = image.size.width / image.size.height
    let targetRatio = target.width / target.height

    if sourceRatio > targetRatio {
        let width = image.size.height * targetRatio
        return NSRect(
            x: (image.size.width - width) / 2,
            y: 0,
            width: width,
            height: image.size.height
        )
    }

    let height = image.size.width / targetRatio
    return NSRect(
        x: 0,
        y: (image.size.height - height) / 2,
        width: image.size.width,
        height: height
    )
}

private func drawScreenshot(_ screenshot: NSImage) {
    let frameRect = NSRect(x: 560, y: 72, width: 710, height: 525)
    let frame = NSBezierPath(roundedRect: frameRect, xRadius: 24, yRadius: 24)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x000000, alpha: 0.72)
    shadow.shadowBlurRadius = 34
    shadow.shadowOffset = NSSize(width: -8, height: -12)
    shadow.set()
    color(0x050B0C).setFill()
    frame.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    frame.addClip()
    screenshot.draw(
        in: frameRect,
        from: sourceRect(for: screenshot, target: frameRect),
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()

    color(0x79E2E0, alpha: 0.28).setStroke()
    frame.lineWidth = 1
    frame.stroke()
}

private func chipWidth(for text: String) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
    ]
    return ceil((text as NSString).size(withAttributes: attributes).width) + 30
}

private func drawChips(_ chips: [String]) {
    var x: CGFloat = 62

    for chip in chips {
        let width = chipWidth(for: chip)
        let rect = NSRect(x: x, y: 68, width: width, height: 38)
        let shape = NSBezierPath(roundedRect: rect, xRadius: 11, yRadius: 11)
        color(0x55D6D9, alpha: 0.085).setFill()
        shape.fill()
        color(0x55D6D9, alpha: 0.23).setStroke()
        shape.lineWidth = 1
        shape.stroke()

        drawText(
            chip,
            in: NSRect(x: x + 15, y: 77, width: width - 30, height: 20),
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: color(0xB2CECC)
        )
        x += width + 10
    }
}

private func render(_ card: LaunchCard, to outputURL: URL) throws {
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
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    NSGradient(
        starting: color(0x050D0E),
        ending: color(0x132625)
    )?.draw(in: NSRect(origin: .zero, size: canvasSize), angle: 0)

    drawSignalField(accentY: 132)

    let glow = NSBezierPath(ovalIn: NSRect(x: 390, y: 84, width: 670, height: 670))
    color(0x55D6D9, alpha: 0.045).setFill()
    glow.fill()

    drawScreenshot(card.screenshot)

    let accentLine = NSBezierPath()
    accentLine.lineWidth = 3
    accentLine.move(to: NSPoint(x: 62, y: 597))
    accentLine.line(to: NSPoint(x: 132, y: 597))
    color(0x55D6D9).setStroke()
    accentLine.stroke()

    drawText(
        card.eyebrow,
        in: NSRect(x: 62, y: 555, width: 460, height: 25),
        font: .systemFont(ofSize: 15, weight: .bold),
        color: color(0x7DDEDC)
    )

    drawText(
        card.headline,
        in: NSRect(x: 58, y: 302, width: 475, height: 225),
        font: .systemFont(ofSize: 54, weight: .semibold),
        color: color(0xF3F7F6),
        lineHeight: 59
    )

    drawText(
        card.body,
        in: NSRect(x: 62, y: 146, width: 430, height: 125),
        font: .systemFont(ofSize: 20, weight: .regular),
        color: color(0xA9B9B8),
        lineHeight: 28
    )

    drawChips(card.chips)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: outputURL, options: .atomic)
}

let arguments = CommandLine.arguments
guard arguments.count == 5 else {
    FileHandle.standardError.write(
        Data("Usage: swift script/generate_launch_assets.swift <overview.png> <ai-workloads.png> <storage.png> <output-directory>\n".utf8)
    )
    exit(64)
}

guard
    let overview = NSImage(contentsOfFile: arguments[1]),
    let aiWorkloads = NSImage(contentsOfFile: arguments[2]),
    let storage = NSImage(contentsOfFile: arguments[3])
else {
    FileHandle.standardError.write(Data("Unable to read one or more Corewise screenshots.\n".utf8))
    exit(66)
}

private let cards = [
    LaunchCard(
        filename: "corewise-launch-overview.jpg",
        eyebrow: "COREWISE  /  PUBLIC BETA",
        headline: "Your Mac, explained locally.",
        body: "Understand performance, storage, thermal signals, startup activity, and recurring app issues without a fake health score.",
        chips: ["macOS 14+", "Signed + notarized", "Open source"],
        screenshot: overview
    ),
    LaunchCard(
        filename: "corewise-launch-ai-workloads.jpg",
        eyebrow: "COREWISE  /  AI WORKLOADS",
        headline: "See what local AI tools use.",
        body: "Observe Codex, Claude, Cursor, and Ollama while keeping app footprint, related work, and shared hosts separate.",
        chips: ["Local processes", "No agent count", "Cloud excluded"],
        screenshot: aiWorkloads
    ),
    LaunchCard(
        filename: "corewise-launch-privacy-open-source.jpg",
        eyebrow: "COREWISE  /  LOCAL BY DESIGN",
        headline: "Your diagnostics stay on your Mac.",
        body: "No account, telemetry, or backend. Corewise never reads prompts, projects, process arguments, or working directories.",
        chips: ["Read-only", "No telemetry", "MPL-2.0"],
        screenshot: storage
    ),
]

let outputDirectory = URL(fileURLWithPath: arguments[4], isDirectory: true)
do {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    for card in cards {
        try render(card, to: outputDirectory.appendingPathComponent(card.filename))
    }
} catch {
    FileHandle.standardError.write(Data("Unable to generate launch assets: \(error)\n".utf8))
    exit(74)
}
