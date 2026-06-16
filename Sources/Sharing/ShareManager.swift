//
//  ShareManager.swift
//  VyroShort
//
//  Save / export and system share-sheet helpers.
//

import AppKit
import UniformTypeIdentifiers

@MainActor
enum ShareManager {
    enum ExportFormat: String, CaseIterable {
        case png, jpg, pdf, tiff
        var utType: UTType {
            switch self {
            case .png: return .png
            case .jpg: return .jpeg
            case .pdf: return .pdf
            case .tiff: return .tiff
            }
        }
    }

    static func share(image: NSImage, from view: NSView) {
        let picker = NSSharingServicePicker(items: [image])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    /// Presents a save panel and writes the image in the chosen format.
    @discardableResult
    static func saveWithPanel(image: NSImage, defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg, .pdf, .tiff]
        panel.nameFieldStringValue = "\(defaultName).png"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let format = ExportFormat(rawValue: url.pathExtension.lowercased()) ?? .png
        if let data = encode(image: image, as: format) {
            try? data.write(to: url)
            return url
        }
        return nil
    }

    static func encode(image: NSImage, as format: ExportFormat) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        switch format {
        case .png: return rep.representation(using: .png, properties: [:])
        case .jpg: return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
        case .tiff: return tiff
        case .pdf: return pdfData(image: image)
        }
    }

    private static func pdfData(image: NSImage) -> Data? {
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: image.pixelSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        ctx.beginPDFPage(nil)
        ctx.draw(cg, in: mediaBox)
        ctx.endPDFPage()
        ctx.closePDF()
        return data as Data
    }
}
