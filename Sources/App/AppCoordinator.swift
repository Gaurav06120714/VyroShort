//
//  AppCoordinator.swift
//  VyroShort
//
//  Central coordinator wiring together capture, stack, clipboard, OCR and editor.
//  Modules register here as they come online.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    // Modules.
    let settings = AppSettings.shared
    let stack = ScreenshotStack()

    private(set) lazy var stackPanel = StackPanelController(stack: stack) { [weak self] item in
        self?.openEditor(for: item)
    }

    private(set) lazy var capture = CaptureController { [weak self] image in
        self?.ingest(image: image)
    }

    let ocr = OCRController()

    @Published private(set) var isReady = false

    func start() {
        isReady = true
        if settings.showStackPanel {
            stackPanel.show()
        }
    }

    func shutdown() {
        isReady = false
    }

    // MARK: - Stack

    func toggleStack() {
        stackPanel.toggle()
    }

    /// Adds a freshly captured image to the stack, copies it, and opens the editor.
    func ingest(image: NSImage) {
        if settings.autoCopyOnCapture {
            ClipboardManager.copy(image: image)
        }
        let item = stack.add(image: image)
        if settings.showStackPanel {
            stackPanel.show()
        }
        openEditor(image: image, title: item?.name ?? "Screenshot")
    }

    func openEditor(for item: ScreenshotItem) {
        guard let image = stack.image(for: item) else { return }
        openEditor(image: image, title: item.name)
    }

    private func openEditor(image: NSImage, title: String) {
        EditorWindowController.present(image: image, title: title) { [weak self] flattened in
            self?.runOCR(on: flattened)
        }
    }

    /// Runs Vision OCR on the given image and presents the result panel.
    func runOCR(on image: NSImage) {
        ocr.run(on: image)
    }

    // MARK: - Capture intents (wired to the capture engine in M4)

    func captureRegion() {
        capture.delayed(seconds: settings.captureDelaySeconds) { [weak self] in
            self?.capture.region()
        }
    }

    func captureWindow() {
        capture.delayed(seconds: settings.captureDelaySeconds) { [weak self] in
            self?.capture.window()
        }
    }

    func captureFullScreen() {
        capture.delayed(seconds: settings.captureDelaySeconds) { [weak self] in
            self?.capture.fullScreen()
        }
    }

    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    func quit() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let vyroCaptureRegion = Notification.Name("vyro.capture.region")
    static let vyroCaptureWindow = Notification.Name("vyro.capture.window")
    static let vyroCaptureFullScreen = Notification.Name("vyro.capture.fullscreen")
    static let vyroRunOCR = Notification.Name("vyro.ocr.run")
}
