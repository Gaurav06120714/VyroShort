//
//  EditorWindowController.swift
//  VyroShort
//
//  Hosts the floating editor in its own window and keeps it alive while open.
//

import AppKit
import SwiftUI

@MainActor
final class EditorWindowController {
    private static var open: [EditorWindowController] = []

    private var window: NSWindow?

    static func present(image: NSImage, title: String, onOCR: @escaping (NSImage) -> Void) {
        let controller = EditorWindowController()
        controller.makeWindow(image: image, title: title, onOCR: onOCR)
        open.append(controller)
    }

    private func makeWindow(image: NSImage, title: String, onOCR: @escaping (NSImage) -> Void) {
        let view = EditorView(image: image, title: title, onOCR: onOCR)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 620),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.title = "VyroShort — \(title)"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.delegate = ProxyDelegate.shared
        ProxyDelegate.shared.register(window) { [weak self] in self?.dismiss() }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    private func dismiss() {
        window = nil
        Self.open.removeAll { $0 === self }
        if Self.open.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    /// Bridges NSWindow close callbacks back to the owning controller.
    @MainActor
    private final class ProxyDelegate: NSObject, NSWindowDelegate {
        static let shared = ProxyDelegate()
        private var handlers: [ObjectIdentifier: () -> Void] = [:]

        func register(_ window: NSWindow, onClose: @escaping () -> Void) {
            handlers[ObjectIdentifier(window)] = onClose
        }

        func windowWillClose(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            handlers.removeValue(forKey: ObjectIdentifier(window))?()
        }
    }
}
