//
//  MenuBarContent.swift
//  VyroShort
//

import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Button("Capture Region") { coordinator.captureRegion() }
            .keyboardShortcut("2", modifiers: [.command, .shift])

        Button("Capture Window") { coordinator.captureWindow() }
            .keyboardShortcut("3", modifiers: [.command, .shift])

        Button("Capture Full Screen") { coordinator.captureFullScreen() }
            .keyboardShortcut("4", modifiers: [.command, .shift])

        Divider()

        Button("Toggle Screenshot Stack") { coordinator.toggleStack() }

        Divider()

        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit VyroShort") { coordinator.quit() }
            .keyboardShortcut("q", modifiers: .command)
    }
}
