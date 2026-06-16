//
//  VyroShortApp.swift
//  VyroShort
//
//  The fastest screenshot workflow on macOS.
//  Capture → Annotate → Organize → Copy → Share.
//

import SwiftUI

@main
struct VyroShortApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu-bar driven app (LSUIElement = true, no dock icon).
        MenuBarExtra("VyroShort", systemImage: "camera.viewfinder") {
            MenuBarContent()
                .environmentObject(appDelegate.coordinator)
        }
        .menuBarExtraStyle(.menu)

        // Settings window (⌘,).
        Settings {
            SettingsView()
                .environmentObject(appDelegate.coordinator)
        }
    }
}
