// Run with ICON_COMPOSER_TOOL=/path/to/ictool swift assets/dspro/export.swift
import AppKit
import Foundation

let fm = FileManager.default
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let tool = ProcessInfo.processInfo.environment["ICON_COMPOSER_TOOL"]
    ?? "/Applications/Icon Composer.app/Contents/Executables/ictool"
let source = root.appendingPathComponent("DevSpacePro.icon").path
let output = root.appendingPathComponent("previews")
let temporary = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try fm.createDirectory(at: output, withIntermediateDirectories: true)
try fm.createDirectory(at: temporary, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: temporary) }

func run(_ executable: String, _ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "IconExport", code: Int(process.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey: "Failed: \(executable) \(arguments)"])
    }
}

func canvas(_ width: Int, _ height: Int, draw: () -> Void) throws -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func write(_ bitmap: NSBitmapImageRep, _ url: URL) throws {
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
}

let renditions = ["Default", "Dark", "ClearLight", "ClearDark", "TintedLight", "TintedDark"]
for rendition in renditions {
    let destination = output.appendingPathComponent("\(rendition).png")
    try run(tool, [source, "--export-image", "--output-file", destination.path,
        "--platform", "macOS", "--rendition", rendition,
        "--width", "1024", "--height", "1024", "--scale", "1"])
    guard let image = NSImage(contentsOf: destination), image.size == NSSize(width: 1024, height: 1024) else {
        fatalError("Missing or invalid \(rendition) export")
    }
}

// The command-line exporter is full bleed. Inset the fallback only; packaged
// Liquid Glass uses the .icon source and actool's native asset catalog.
let fallback = root.appendingPathComponent("dspro-macos-1024.png")
let dark = NSImage(contentsOf: output.appendingPathComponent("Dark.png"))!
try write(canvas(1024, 1024) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = 12
    shadow.shadowOffset = NSSize(width: 0, height: -6)
    shadow.set()
    dark.draw(in: NSRect(x: 100, y: 100, width: 824, height: 824))
}, fallback)

let iconset = temporary.appendingPathComponent("DS.iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = String(size * scale)
        let suffix = scale == 2 ? "@2x" : ""
        try run("/usr/bin/sips", ["-z", pixels, pixels, fallback.path, "--out",
            iconset.appendingPathComponent("icon_\(size)x\(size)\(suffix).png").path])
    }
}
try run("/usr/bin/iconutil", ["-c", "icns", iconset.path, "-o",
    root.appendingPathComponent("DevSpacePro.icns").path])

let labels = ["Light", "Dark", "Clear · Light", "Clear · Dark", "Tinted · Light", "Tinted · Dark"]
try write(canvas(1200, 530) {
    NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 1200, height: 530).fill()
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 27, weight: .semibold), .foregroundColor: NSColor.white]
    ("DevSpace Pro" as NSString).draw(at: NSPoint(x: 40, y: 466), withAttributes: titleAttributes)
    ("Native macOS appearances · DS" as NSString).draw(at: NSPoint(x: 40, y: 432),
        withAttributes: [.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.lightGray])
    for (index, rendition) in renditions.enumerated() {
        let x = 40 + (index % 3) * 390
        let y = index < 3 ? 260 : 60
        let image = NSImage(contentsOf: output.appendingPathComponent("\(rendition).png"))!
        image.draw(in: NSRect(x: x, y: y, width: 140, height: 140))
        (labels[index] as NSString).draw(at: NSPoint(x: x + 160, y: y + 62),
            withAttributes: [.font: NSFont.systemFont(ofSize: 16, weight: .medium),
                            .foregroundColor: NSColor.white])
    }
}, root.appendingPathComponent("appearances.png"))
print("Exported six native appearances, the macOS fallback, and DevSpacePro.icns.")
