// Generates the VyroShort app icon (1024×1024 PNG) using CoreGraphics.
// Run: swift scripts/make_icon.swift <output.png>
import AppKit

let size = 1024.0
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Rounded-rect (squircle) background with indigo→violet gradient.
let rect = CGRect(x: 0, y: 0, width: size, height: size)
let corner = size * 0.2237
let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
ctx.addPath(path)
ctx.clip()

let colors = [
    CGColor(red: 0.42, green: 0.40, blue: 0.99, alpha: 1),   // indigo
    CGColor(red: 0.36, green: 0.45, blue: 0.98, alpha: 1),   // blue-indigo
    CGColor(red: 0.55, green: 0.30, blue: 0.95, alpha: 1)    // violet
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                          locations: [0, 0.5, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: size, y: 0),
                       options: [])

// Soft top highlight.
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.10))
ctx.fillEllipse(in: CGRect(x: -size*0.2, y: size*0.45, width: size*1.0, height: size*0.9))

// --- Stacked screenshot cards motif (back two cards) ---
func roundedCard(_ r: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}
let cardW = size * 0.42, cardH = size * 0.34, cr = size * 0.05
let cx = size/2, cy = size/2

ctx.saveGState()
ctx.translateBy(x: cx, y: cy)
// back card
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.28))
ctx.rotate(by: 0.20)
ctx.addPath(roundedCard(CGRect(x: -cardW/2, y: -cardH/2, width: cardW, height: cardH), radius: cr))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.translateBy(x: cx, y: cy)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.5))
ctx.rotate(by: 0.10)
ctx.addPath(roundedCard(CGRect(x: -cardW/2, y: -cardH/2, width: cardW, height: cardH), radius: cr))
ctx.fillPath()
ctx.restoreGState()

// --- Viewfinder corner brackets (foreground) ---
let vSize = size * 0.46
let v = CGRect(x: cx - vSize/2, y: cy - vSize/2, width: vSize, height: vSize)
let arm = vSize * 0.30
let lw = size * 0.045
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.setLineWidth(lw)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

func bracket(_ corner: CGPoint, dx: CGFloat, dy: CGFloat) {
    ctx.move(to: CGPoint(x: corner.x + dx*arm, y: corner.y))
    ctx.addLine(to: corner)
    ctx.addLine(to: CGPoint(x: corner.x, y: corner.y + dy*arm))
    ctx.strokePath()
}
bracket(CGPoint(x: v.minX, y: v.maxY), dx: 1, dy: -1)   // top-left
bracket(CGPoint(x: v.maxX, y: v.maxY), dx: -1, dy: -1)  // top-right
bracket(CGPoint(x: v.minX, y: v.minY), dx: 1, dy: 1)    // bottom-left
bracket(CGPoint(x: v.maxX, y: v.minY), dx: -1, dy: 1)   // bottom-right

// Center dot.
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
let dot = size * 0.052
ctx.fillEllipse(in: CGRect(x: cx - dot/2, y: cy - dot/2, width: dot, height: dot))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("Failed to render icon\n".data(using: .utf8)!)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("Wrote \(outPath)")
