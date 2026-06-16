//
//  SettingsView.swift
//  VyroShort
//
//  Minimal settings shell. Full categorized panel built in M7.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 460, height: 280)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private var generalTab: some View {
        Form {
            Picker("Appearance", selection: Binding(
                get: { settings.appearanceMode },
                set: { settings.appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            Toggle("Copy to clipboard on capture", isOn: $settings.autoCopyOnCapture)
            Toggle("Play capture sound", isOn: $settings.playCaptureSound)
            Toggle("Show screenshot stack", isOn: $settings.showStackPanel)
        }
        .font(VST.Font.body)
        .formStyle(.grouped)
        .padding()
    }
}
