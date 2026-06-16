//
//  AnnotationEngine.swift
//  VyroShort
//
//  Holds the base image, the ordered annotation list, current tool/style,
//  undo/redo history, crop rect, and renders a flattened export image.
//

import AppKit
import CoreImage
import SwiftUI

@MainActor
final class AnnotationEngine: ObservableObject {
    let baseImage: NSImage
    let pixelSize: CGSize

    @Published var annotations: [Annotation] = []
    @Published var tool: EditorTool = .arrow
    @Published var colorHex: String = VST.Color.error.hexString
    @Published var lineWidth: CGFloat = 4
    @Published var opacity: Double = 1
    @Published var selectedID: UUID?
    @Published var cropRect: CGRect?          // image-space; nil = no crop

    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []

    /// Pre-blurred copy of the base image used to render blur annotations.
    private(set) lazy var blurredImage: NSImage = Self.makeBlurred(baseImage)

    init(image: NSImage) {
        self.baseImage = image
        self.pixelSize = image.pixelSize
    }

    // MARK: - History

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    private func checkpoint() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = prev
        selectedID = nil
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
    }

    func clearAll() {
        guard !annotations.isEmpty || cropRect != nil else { return }
        checkpoint()
        annotations.removeAll()
        cropRect = nil
        selectedID = nil
    }

    // MARK: - Editing

    func makeAnnotation(start: CGPoint) -> Annotation {
        Annotation(tool: tool, start: start, end: start,
                   colorHex: colorHex, lineWidth: lineWidth,
                   opacity: tool == .highlight ? min(opacity, 0.4) : opacity)
    }

    func beginAnnotation(_ annotation: Annotation) {
        checkpoint()
        annotations.append(annotation)
        selectedID = annotation.id
    }

    func updateLast(end: CGPoint) {
        guard !annotations.isEmpty else { return }
        annotations[annotations.count - 1].end = end
    }

    func addText(at point: CGPoint, text: String) {
        checkpoint()
        var a = Annotation(tool: .text, start: point, end: point,
                           colorHex: colorHex, lineWidth: lineWidth, opacity: 1)
        a.text = text
        annotations.append(a)
        selectedID = a.id
    }

    func updateText(id: UUID, text: String) {
        guard let i = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[i].text = text
    }

    func deleteSelected() {
        guard let id = selectedID,
              let i = annotations.firstIndex(where: { $0.id == id }) else { return }
        checkpoint()
        annotations.remove(at: i)
        selectedID = nil
    }

    func setCrop(_ rect: CGRect) {
        checkpoint()
        cropRect = rect.intersection(CGRect(origin: .zero, size: pixelSize))
    }

    // MARK: - Export

    /// Flattens base image + annotations (+ crop) into a single NSImage at full resolution
    /// by rendering the same SwiftUI canvas used on screen via ImageRenderer.
    func renderFlattened() -> NSImage {
        let content = CanvasContent(engine: self, displaySize: pixelSize, interactive: false)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        let full = renderer.nsImage ?? baseImage

        guard let crop = cropRect, crop.width > 1, crop.height > 1 else { return full }
        return full.cropped(to: crop)
    }

    private static func makeBlurred(_ image: NSImage) -> NSImage {
        guard let tiff = image.tiffRepresentation,
              let ci = CIImage(data: tiff) else { return image }
        let blurred = ci
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 14])
            .cropped(to: ci.extent)
        let rep = NSCIImageRep(ciImage: blurred)
        let out = NSImage(size: image.pixelSize)
        out.addRepresentation(rep)
        return out
    }
}

extension NSImage {
    func cropped(to rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()
        draw(in: CGRect(origin: .zero, size: rect.size),
             from: CGRect(x: rect.minX, y: pixelSize.height - rect.maxY, width: rect.width, height: rect.height),
             operation: .copy, fraction: 1)
        result.unlockFocus()
        return result
    }
}
