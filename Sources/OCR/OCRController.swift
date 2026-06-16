//
//  OCRController.swift
//  VyroShort
//
//  Runs OCR on an image and presents the result panel.
//

import AppKit
import SwiftUI

@MainActor
final class OCRController {
    private var window: NSWindow?

    func run(on image: NSImage) {
        Task {
            let result = await OCRManager.recognize(in: image)
            if AppSettings.shared.autoCopyOnCapture, !result.isEmpty {
                ClipboardManager.copy(text: result.text)
            }
            present(result)
        }
    }

    private func present(_ result: OCRResult) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.title = "VyroShort — OCR"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: OCRResultView(result: result))
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}
