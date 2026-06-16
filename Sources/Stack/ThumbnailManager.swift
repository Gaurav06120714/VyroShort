//
//  ThumbnailManager.swift
//  VyroShort
//

import AppKit

enum ThumbnailManager {
    /// Produces a proportionally scaled thumbnail no larger than `maxDimension` on its long edge.
    static func makeThumbnail(from image: NSImage, maxDimension: CGFloat) -> NSImage? {
        let size = image.pixelSize
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = NSSize(width: floor(size.width * scale), height: floor(size.height * scale))

        let thumb = NSImage(size: target)
        thumb.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: target),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1)
        thumb.unlockFocus()
        return thumb
    }
}
