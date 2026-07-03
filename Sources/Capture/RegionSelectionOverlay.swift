//
//  RegionSelectionOverlay.swift
//  VyroShort
//
//  Full-screen dimmed overlay with crosshair, live dimensions and drag-to-select.
//  Returns the chosen rectangle in global (AppKit, bottom-left origin) coordinates.
//

import AppKit

@MainActor
final class RegionSelectionOverlay {
    enum Mode { case region, window }

    private var window: NSWindow?
    private var completion: ((CGRect?) -> Void)?

    func begin(mode: Mode, completion: @escaping (CGRect?) -> Void) {
        self.completion = completion

        let unionFrame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
        let window = OverlayWindow(contentRect: unionFrame, styleMask: .borderless,
                                   backing: .buffered, defer: false)
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = SelectionView(frame: NSRect(origin: .zero, size: unionFrame.size))
        view.mode = mode
        view.originOffset = unionFrame.origin
        view.onFinish = { [weak self] rect in self?.finish(rect) }
        view.onCancel = { [weak self] in self?.finish(nil) }
        window.contentView = view

        self.window = window
        // Show immediately without the (slow) full app activation animation; the
        // overlay is above everything and becomes key so it still receives ESC.
        window.orderFrontRegardless()
        window.makeKey()
        window.makeFirstResponder(view)
    }

    private func finish(_ rect: CGRect?) {
        window?.orderOut(nil)
        window = nil
        let c = completion
        completion = nil
        c?(rect)
    }
}

/// Borderless windows can't become key by default, which would swallow ESC and
/// other key events. This subclass opts in so the overlay can be dismissed.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class SelectionView: NSView {
    var mode: RegionSelectionOverlay.Mode = .region
    var originOffset: CGPoint = .zero          // global origin of the overlay window
    var onFinish: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentRect: CGRect = .zero
    private var mouseLocation: CGPoint = .zero

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if mode == .window {
            // A single click picks the window under the cursor (zero-size rect = point).
            let global = CGRect(x: p.x + originOffset.x, y: p.y + originOffset.y, width: 0, height: 0)
            onFinish?(global)
            return
        }
        startPoint = p
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let p = convert(event.locationInWindow, from: nil)
        mouseLocation = p
        currentRect = CGRect(x: min(start.x, p.x), y: min(start.y, p.y),
                             width: abs(p.x - start.x), height: abs(p.y - start.y))
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        mouseLocation = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer { startPoint = nil }
        guard currentRect.width > 2, currentRect.height > 2 else { onCancel?(); return }
        let global = CGRect(x: currentRect.minX + originOffset.x,
                            y: currentRect.minY + originOffset.y,
                            width: currentRect.width, height: currentRect.height)
        onFinish?(global)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() } // ESC
    }

    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
    }

    override func draw(_ dirtyRect: NSRect) {
        // Dim the whole screen.
        NSColor.black.withAlphaComponent(0.32).setFill()
        bounds.fill()

        // Crosshair guides.
        NSColor.white.withAlphaComponent(0.35).setStroke()
        let crosshair = NSBezierPath()
        crosshair.move(to: CGPoint(x: mouseLocation.x, y: 0))
        crosshair.line(to: CGPoint(x: mouseLocation.x, y: bounds.height))
        crosshair.move(to: CGPoint(x: 0, y: mouseLocation.y))
        crosshair.line(to: CGPoint(x: bounds.width, y: mouseLocation.y))
        crosshair.lineWidth = 1
        crosshair.stroke()

        guard currentRect.width > 0 else { return }

        // Punch out the selection (show the live screen content).
        NSColor.clear.setFill()
        let blend = NSGraphicsContext.current?.compositingOperation
        NSGraphicsContext.current?.compositingOperation = .clear
        currentRect.fill()
        NSGraphicsContext.current?.compositingOperation = blend ?? .sourceOver

        // Selection border.
        let accent = NSColor(red: 0.36, green: 0.45, blue: 0.98, alpha: 1)
        accent.setStroke()
        let border = NSBezierPath(rect: currentRect)
        border.lineWidth = 1.5
        border.stroke()

        // Live dimensions label.
        let label = "\(Int(currentRect.width)) × \(Int(currentRect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let textSize = label.size(withAttributes: attrs)
        let pad: CGFloat = 6
        let bg = CGRect(x: currentRect.minX,
                        y: currentRect.maxY + 6,
                        width: textSize.width + pad * 2,
                        height: textSize.height + pad)
        accent.withAlphaComponent(0.92).setFill()
        NSBezierPath(roundedRect: bg, xRadius: 4, yRadius: 4).fill()
        label.draw(at: CGPoint(x: bg.minX + pad, y: bg.minY + pad / 2), withAttributes: attrs)
    }
}
