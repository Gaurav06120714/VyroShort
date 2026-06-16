//
//  SettingsView.swift
//  VyroShort
//
//  Categorized preferences: General · Capture · Shortcuts · Clipboard · Appearance.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gearshape") }
            captureTab.tabItem { Label("Capture", systemImage: "camera.viewfinder") }
            shortcutsTab.tabItem { Label("Shortcuts", systemImage: "command") }
            clipboardTab.tabItem { Label("Clipboard", systemImage: "doc.on.clipboard") }
            appearanceTab.tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 480, height: 360)
        .font(VST.Font.body)
        .preferredColorScheme(settings.appearanceMode.colorScheme)
    }

    private var generalTab: some View {
        Form {
            Toggle("Copy to clipboard on capture", isOn: $settings.autoCopyOnCapture)
            Toggle("Play capture sound", isOn: $settings.playCaptureSound)
            Toggle("Show screenshot stack", isOn: $settings.showStackPanel)
        }
        .formStyle(.grouped).padding()
    }

    private var captureTab: some View {
        Form {
            Picker("Capture delay", selection: $settings.captureDelaySeconds) {
                Text("None").tag(0)
                Text("3 seconds").tag(3)
                Text("5 seconds").tag(5)
                Text("10 seconds").tag(10)
            }
            LabeledContent("Stack limit", value: "\(ScreenshotStack.maxItems) screenshots")
            LabeledContent("Formats", value: "PNG · JPG · PDF · TIFF")
        }
        .formStyle(.grouped).padding()
    }

    private var shortcutsTab: some View {
        Form {
            shortcut("Capture Region", "⌘ ⇧ Q")
            shortcut("Capture Window", "⌘ ⇧ 2")
            shortcut("Capture Full Screen", "⌘ ⇧ 1")
            shortcut("Copy", "⌘ C")
            shortcut("Save", "⌘ S")
            shortcut("Undo / Redo", "⌘ Z · ⌘ ⇧ Z")
        }
        .formStyle(.grouped).padding()
    }

    private var clipboardTab: some View {
        ClipboardHistoryView()
    }

    private var appearanceTab: some View {
        Form {
            Picker("Appearance", selection: Binding(
                get: { settings.appearanceMode },
                set: { settings.appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped).padding()
    }

    private func shortcut(_ label: String, _ keys: String) -> some View {
        LabeledContent(label) {
            Text(keys).font(VST.Font.mono).foregroundStyle(VST.Color.secondaryLabel)
        }
    }
}

struct ClipboardHistoryView: View {
    @ObservedObject private var history = ClipboardHistory.shared

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: VST.Spacing.sm) {
            HStack {
                Text("Recent copies (last \(ClipboardHistory.maxItems))")
                    .font(VST.Font.caption).foregroundStyle(VST.Color.secondaryLabel)
                Spacer()
                Button("Clear") { history.clear() }.disabled(history.entries.isEmpty)
            }
            if history.entries.isEmpty {
                Spacer()
                Text("Nothing copied yet.").foregroundStyle(VST.Color.secondaryLabel)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(history.entries) { entry in
                            Image(nsImage: entry.image)
                                .resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: VST.Radius.sm))
                                .overlay(RoundedRectangle(cornerRadius: VST.Radius.sm)
                                    .strokeBorder(.white.opacity(0.1)))
                                .onTapGesture { history.restore(entry) }
                                .help("Click to copy again")
                        }
                    }
                }
            }
        }
        .padding()
    }
}
