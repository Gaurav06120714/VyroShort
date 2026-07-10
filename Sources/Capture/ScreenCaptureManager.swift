//
//  ScreenCaptureManager.swift
//  VyroShort
//
//  ScreenCaptureKit wrapper for full-screen, region and window capture.
//

import AppKit
import ScreenCaptureKit

enum CaptureError: Error {
    case noContent
    case captureFailed
    case noDisplay
    case cancelled
}

@MainActor
final class ScreenCaptureManager {

    /// Captures an entire display (defaults to the one under the cursor).
    func captureFullScreen() async throws -> NSImage {
        let content = try await shareableContent()
        let display = displayUnderCursor(in: content) ?? content.displays.first
        guard let display else { throw CaptureError.noDisplay }

        let filter = SCContentFilter(display: display, excludingWindows: ownWindows(in: content))
        let config = configuration(width: display.width, height: display.height)
        return try await capture(filter: filter, config: config)
    }

    /// Captures a single window by its on-screen frame point (e.g. a click location).
    func captureWindow(at point: CGPoint) async throws -> NSImage {
        let content = try await shareableContent()
        guard let window = topWindow(at: point, in: content) else {
            throw CaptureError.noContent
        }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let frame = window.frame
        let config = configuration(width: Int(frame.width), height: Int(frame.height))
        config.ignoreShadowsSingleWindow = false
        return try await capture(filter: filter, config: config)
    }

    /// Captures a rectangular region (in global/AppKit coordinates) of its display.
    func captureRegion(_ rect: CGRect) async throws -> NSImage {
        let content = try await shareableContent()
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(rect) }) ?? NSScreen.main,
              let displayID = screen.displayID,
              let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.noDisplay
        }

        // Convert global (bottom-left origin) rect to display-local (top-left origin) pixels.
        let scale = screen.backingScaleFactor
        let local = CGRect(
            x: (rect.minX - screen.frame.minX),
            y: (screen.frame.maxY - rect.maxY),
            width: rect.width,
            height: rect.height
        )

        let filter = SCContentFilter(display: display, excludingWindows: ownWindows(in: content))
        let config = configuration(width: Int(local.width * scale), height: Int(local.height * scale))
        config.sourceRect = local
        config.scalesToFit = false
        return try await capture(filter: filter, config: config)
    }

    /// VyroShort's own on-screen windows (stack panel, editor, overlays) so they
    /// are never baked into a capture.
    private func ownWindows(in content: SCShareableContent) -> [SCWindow] {
        let bundleID = Bundle.main.bundleIdentifier
        return content.windows.filter { $0.owningApplication?.bundleIdentifier == bundleID }
    }

    // MARK: - Core

    private func capture(filter: SCContentFilter, config: SCStreamConfiguration) async throws -> NSImage {
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    private func configuration(width: Int, height: Int) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        config.width = max(width, 1)
        config.height = max(height, 1)
        config.showsCursor = false
        config.capturesAudio = false
        config.colorSpaceName = CGColorSpace.sRGB
        return config
    }

    private var cachedContent: SCShareableContent?
    private var cachedAt: Date = .distantPast
    private let cacheTTL: TimeInterval = 10

    /// Pre-loads shareable content so the first real capture doesn't pay the
    /// cold-start cost of spinning up ScreenCaptureKit.
    func warmUp() async {
        _ = try? await shareableContent()
    }

    private func shareableContent() async throws -> SCShareableContent {
        // Reuse recently-fetched content — enumerating windows is the slow part.
        if let cached = cachedContent, Date().timeIntervalSince(cachedAt) < cacheTTL {
            return cached
        }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        cachedContent = content
        cachedAt = .now
        return content
    }

    private func displayUnderCursor(in content: SCShareableContent) -> SCDisplay? {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }),
              let displayID = screen.displayID else { return content.displays.first }
        return content.displays.first { $0.displayID == displayID }
    }

    private func topWindow(at point: CGPoint, in content: SCShareableContent) -> SCWindow? {
        // SCWindow.frame is in top-left global coordinates; convert AppKit point.
        let height = NSScreen.screens.map(\.frame.maxY).max() ?? 0
        let flipped = CGPoint(x: point.x, y: height - point.y)
        let ownBundle = Bundle.main.bundleIdentifier
        // content.windows is front-to-back, so the first match under the cursor is
        // the topmost window. Accept ANY real window (no title requirement) except
        // VyroShort's own overlay, and skip tiny/utility windows.
        return content.windows.first { win in
            win.isOnScreen
            && win.frame.contains(flipped)
            && win.frame.width > 40 && win.frame.height > 40
            && win.owningApplication?.bundleIdentifier != ownBundle
        }
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
