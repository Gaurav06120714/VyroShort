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

    private var window: OverlayWindow?
    private var view: SelectionView?
    private var lastUnionFrame: CGRect = .zero
    private var completion: ((CGRect?) -> Void)?

    func begin(mode: Mode, completion: @escaping (CGRect?) -> Void) {
        self.completion = completion

        let unionFrame = NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }

        // Reuse the overlay window/view across captures — building a full-screen
        // window each time is what made ⌘⇧Q feel slow.
        let window: OverlayWindow
        let view: SelectionView
        if let w = self.window, let v = self.view, lastUnionFrame == unionFrame {
            window = w; view = v
        } else {
            self.window?.orderOut(nil)
            window = OverlayWindow(contentRect: unionFrame, styleMask: .borderless,
                                   backing: .buffered, defer: false)
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            view = SelectionView(frame: NSRect(origin: .zero, size: unionFrame.size))
            view.wantsLayer = true
            window.contentView = view
            self.window = window
            self.view = view
            lastUnionFrame = unionFrame
        }

        view.reset()
        view.mode = mode
        view.originOffset = unionFrame.origin
        view.onFinish = { [weak self] rect in self?.finish(rect) }
        view.onCancel = { [weak self] in self?.finish(nil) }

        // Activate so mouse/keyboard route to the overlay immediately (responsive),
        // then show it. The reused window keeps this fast; the editor no longer
        // toggles activation policy, so this won't flash the desktop.
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
    }

    private func finish(_ rect: CGRect?) {
        window?.orderOut(nil)      // keep window alive for reuse
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

/// Layer-backed selection view. Uses CALayers repositioned on each mouse move
/// (instead of repainting the whole screen) so selection stays smooth on large
/// / Retina displays.
private final class SelectionView: NSView {
    var mode: RegionSelectionOverlay.Mode = .region
    var originOffset: CGPoint = .zero
    var onFinish: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentRect: CGRect = .zero
    private var mouseLocation: CGPoint = .zero

    private let dimTop = CALayer()
    private let dimBottom = CALayer()
    private let dimLeft = CALayer()
    private let dimRight = CALayer()
    private let vLine = CALayer()
    private let hLine = CALayer()
    private let selBorder = CALayer()
    private let label = CATextLayer()

    private let accent = NSColor(red: 0.36, green: 0.45, blue: 0.98, alpha: 1)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupLayers()
    }
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    private func setupLayers() {
        let dim = NSColor.black.withAlphaComponent(0.32).cgColor
        for d in [dimTop, dimBottom, dimLeft, dimRight] {
            d.backgroundColor = dim
            layer?.addSublayer(d)
        }
        let line = NSColor.white.withAlphaComponent(0.35).cgColor
        vLine.backgroundColor = line
        hLine.backgroundColor = line
        layer?.addSublayer(vLine)
        layer?.addSublayer(hLine)

        selBorder.borderColor = accent.cgColor
        selBorder.borderWidth = 1.5
        selBorder.backgroundColor = NSColor.clear.cgColor
        selBorder.isHidden = true
        layer?.addSublayer(selBorder)

        label.fontSize = 11
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        label.foregroundColor = NSColor.white.cgColor
        label.backgroundColor = accent.withAlphaComponent(0.92).cgColor
        label.cornerRadius = 4
        label.alignmentMode = .center
        label.isHidden = true
        layer?.addSublayer(label)
    }

    /// Clears state so a reused overlay starts fresh.
    func reset() {
        startPoint = nil
        currentRect = .zero
        mouseLocation = .zero
        updateLayers()
    }

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }

    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
        label.contentsScale = window?.backingScaleFactor ?? 2
        updateLayers()
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if mode == .window {
            onFinish?(CGRect(x: p.x + originOffset.x, y: p.y + originOffset.y, width: 0, height: 0))
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
        updateLayers()
    }

    override func mouseMoved(with event: NSEvent) {
        mouseLocation = convert(event.locationInWindow, from: nil)
        updateLayers()
    }

    override func mouseUp(with event: NSEvent) {
        defer { startPoint = nil }
        guard currentRect.width > 2, currentRect.height > 2 else { onCancel?(); return }
        onFinish?(CGRect(x: currentRect.minX + originOffset.x,
                         y: currentRect.minY + originOffset.y,
                         width: currentRect.width, height: currentRect.height))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() } // ESC
    }

    // MARK: - Layout (cheap, no redraw)

    private func updateLayers() {
        let b = bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if currentRect.width > 0 {
            dimTop.frame = CGRect(x: 0, y: currentRect.maxY, width: b.width, height: max(0, b.maxY - currentRect.maxY))
            dimBottom.frame = CGRect(x: 0, y: 0, width: b.width, height: max(0, currentRect.minY))
            dimLeft.frame = CGRect(x: 0, y: currentRect.minY, width: max(0, currentRect.minX), height: currentRect.height)
            dimRight.frame = CGRect(x: currentRect.maxX, y: currentRect.minY, width: max(0, b.maxX - currentRect.maxX), height: currentRect.height)
            selBorder.frame = currentRect.insetBy(dx: -0.5, dy: -0.5)
            selBorder.isHidden = false

            let text = "\(Int(currentRect.width)) × \(Int(currentRect.height))"
            label.string = text
            let w = CGFloat(text.count) * 8 + 14
            label.frame = CGRect(x: currentRect.minX, y: min(currentRect.maxY + 6, b.maxY - 20), width: w, height: 18)
            label.isHidden = false
        } else {
            dimTop.frame = b
            dimBottom.frame = .zero; dimLeft.frame = .zero; dimRight.frame = .zero
            selBorder.isHidden = true
            label.isHidden = true
        }

        vLine.frame = CGRect(x: mouseLocation.x, y: 0, width: 1, height: b.height)
        hLine.frame = CGRect(x: 0, y: mouseLocation.y, width: b.width, height: 1)

        CATransaction.commit()
    }
}
