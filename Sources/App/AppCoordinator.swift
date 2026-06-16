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
    // Modules (populated by later build modules).
    let settings = AppSettings.shared

    @Published private(set) var isReady = false

    func start() {
        isReady = true
    }

    func shutdown() {
        isReady = false
    }

    // MARK: - Capture intents (wired to the capture engine in M4)

    func captureRegion() {
        // Implemented in Capture module.
        NotificationCenter.default.post(name: .vyroCaptureRegion, object: nil)
    }

    func captureWindow() {
        NotificationCenter.default.post(name: .vyroCaptureWindow, object: nil)
    }

    func captureFullScreen() {
        NotificationCenter.default.post(name: .vyroCaptureFullScreen, object: nil)
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
}
