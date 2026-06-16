//
//  Annotation.swift
//  VyroShort
//
//  Value model for a single annotation drawn on the canvas.
//  Coordinates are stored in image-pixel space so export is resolution-correct.
//

import SwiftUI

enum EditorTool: String, CaseIterable, Identifiable {
    case select, arrow, rectangle, ellipse, line, highlight, text, blur, crop

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .select: return "cursorarrow"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .line: return "line.diagonal"
        case .highlight: return "highlighter"
        case .text: return "textformat"
        case .blur: return "drop.degreesign"
        case .crop: return "crop"
        }
    }

    var label: String {
        switch self {
        case .select: return "Select"
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .line: return "Line"
        case .highlight: return "Highlight"
        case .text: return "Text"
        case .blur: return "Blur"
        case .crop: return "Crop"
        }
    }

    var isDraggableShape: Bool {
        switch self {
        case .select, .text: return false
        default: return true
        }
    }
}

struct Annotation: Identifiable, Equatable {
    let id = UUID()
    var tool: EditorTool
    var start: CGPoint           // image-space
    var end: CGPoint             // image-space
    var colorHex: String
    var lineWidth: CGFloat
    var opacity: Double
    var text: String = ""
    var fontSize: CGFloat = 24

    var rect: CGRect {
        CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
               width: abs(end.x - start.x), height: abs(end.y - start.y))
    }

    var color: Color { Color(hex: colorHex) }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return String(format: "#%02X%02X%02X",
                      Int(ns.redComponent * 255),
                      Int(ns.greenComponent * 255),
                      Int(ns.blueComponent * 255))
    }
}
