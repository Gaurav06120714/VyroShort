//
//  FloatingPanel.swift
//  VyroShort
//
//  A non-activating, always-on-top NSPanel that hosts SwiftUI content.
//  Used for the screenshot stack, floating editor and pinned screenshots.
//

import AppKit
import SwiftUI

final class FloatingPanel<Content: View>: NSPanel {
    init(contentRect: NSRect,
         hidesOnDeactivate: Bool = false,
         @ViewBuilder content: () -> Content) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        // Must be false so drags (e.g. swipe-to-delete) reach the SwiftUI content
        // instead of moving the whole window.
        isMovableByWindowBackground = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        self.hidesOnDeactivate = hidesOnDeactivate

        let host = NSHostingView(rootView: content())
        host.translatesAutoresizingMaskIntoConstraints = false
        contentView = NSView()
        contentView?.addSubview(host)
        if let cv = contentView {
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
                host.topAnchor.constraint(equalTo: cv.topAnchor),
                host.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
            ])
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Positions the panel in the bottom-left of the main screen's visible frame.
    func positionBottomLeft(margin: CGFloat = 20) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        setFrameOrigin(NSPoint(x: vf.minX + margin, y: vf.minY + margin))
    }
}
