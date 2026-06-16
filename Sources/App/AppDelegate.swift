//
//  AppDelegate.swift
//  VyroShort
//

import AppKit
import CoreGraphics
import SwiftUI

/// Owns the long-lived app coordinator and bridges AppKit lifecycle into SwiftUI.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // First-launch: offer to move into /Applications. If accepted, this
        // instance relaunches from there, so stop setting up the current one.
        if MoveToApplications.offerIfNeeded() { return }

        requestScreenRecordingIfNeeded()
        coordinator.start()
    }

    /// Triggers the system Screen Recording prompt and registers VyroShort in the
    /// Privacy list. If access was granted to a *previous* build, this re-prompts.
    private func requestScreenRecordingIfNeeded() {
        if CGPreflightScreenCaptureAccess() { return }
        // Shows the macOS prompt and adds the app to the Privacy list.
        let granted = CGRequestScreenCaptureAccess()
        if !granted {
            DispatchQueue.main.async { self.showRelaunchHint() }
        }
    }

    private func showRelaunchHint() {
        let alert = NSAlert()
        alert.messageText = "Enable Screen Recording for VyroShort"
        alert.informativeText = """
        1. In the list that just opened, turn ON "VyroShort".
        2. Quit VyroShort completely (menu bar icon → Quit).
        3. Reopen VyroShort.

        Permission is tied to this exact copy of the app — always run it from \
        /Applications, not from inside the disk image.
        """
        alert.addButton(withTitle: "Open Privacy Settings")
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.shutdown()
    }
}
