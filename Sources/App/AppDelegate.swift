//
//  AppDelegate.swift
//  VyroShort
//

import AppKit
import SwiftUI

/// Owns the long-lived app coordinator and bridges AppKit lifecycle into SwiftUI.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.shutdown()
    }
}
