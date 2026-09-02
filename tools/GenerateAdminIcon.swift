import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fatalError("Usage: GenerateAdminIcon.swift source.png output-directory")
}

let sourceURL = URL(fileURLWithPath: arguments[1])
let outputDirectory = URL(fileURLWithPath: arguments[2], isDirectory: true)
guard let source = NSImage(contentsOf: sourceURL) else {
    fatalError("Could not read source app icon")
}

let size = NSSize(width: 1024, height: 1024)
var proposedRect = NSRect(origin: .zero, size: size)
guard let sourceImage = source.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil),
      let canvas = CGContext(
        data: nil,
        width: 1024,
        height: 1024,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      ) else {
    fatalError("Could not create app icon canvas")
}

let context = NSGraphicsContext(cgContext: canvas, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

NSColor.white.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
canvas.draw(sourceImage, in: CGRect(origin: .zero, size: size))

let badgeRect = NSRect(x: 190, y: 78, width: 644, height: 170)
let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 62, yRadius: 62)
NSColor(calibratedRed: 0.31, green: 0.16, blue: 0.07, alpha: 0.96).setFill()
badge.fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 82, weight: .heavy),
    .foregroundColor: NSColor.white,
    .kern: 10,
    .paragraphStyle: paragraph
]
let text = NSAttributedString(string: "ADMIN", attributes: attributes)
let textHeight = text.size().height
text.draw(in: NSRect(x: badgeRect.minX, y: badgeRect.midY - textHeight / 2, width: badgeRect.width, height: textHeight))

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let renderedImage = canvas.makeImage(),
      let data = NSBitmapImageRep(cgImage: renderedImage).representation(using: .png, properties: [:]) else {
    fatalError("Could not encode app icon")
}

for name in ["AppIcon-Admin.png", "AppIcon-Admin-Dark.png", "AppIcon-Admin-Tinted.png"] {
    try data.write(to: outputDirectory.appendingPathComponent(name), options: .atomic)
}
