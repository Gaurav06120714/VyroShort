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

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    private var generalTab: some View {
        Form {
            Toggle("Copy to clipboard on capture", isOn: $settings.autoCopyOnCapture)
            Toggle("Play capture sound", isOn: $settings.playCaptureSound)
            Toggle("Show screenshot stack", isOn: $settings.showStackPanel)
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin },
                set: { launchAtLogin = $0; LaunchAtLogin.set($0) }
            ))
            LabeledContent("Version") {
                Text(Self.appVersion).foregroundStyle(VST.Color.secondaryLabel)
            }
        }
        .formStyle(.grouped).padding()
    }

    private func chooseSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.saveFolderURL
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            settings.saveFolderURL = url
        }
    }

    static var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    @State private var screenAccess = ScreenRecordingPermission.isGranted

    private var captureTab: some View {
        Form {
            Section("Permissions") {
                LabeledContent("Screen Recording") {
                    HStack(spacing: VST.Spacing.sm) {
                        Circle()
                            .fill(screenAccess ? VST.Color.success : VST.Color.error)
                            .frame(width: 8, height: 8)
                        Text(screenAccess ? "Granted" : "Not granted")
                            .foregroundStyle(VST.Color.secondaryLabel)
                    }
                }
                if !screenAccess {
                    Text("VyroShort needs Screen Recording to capture. Grant it, then relaunch the app.")
                        .font(VST.Font.caption)
                        .foregroundStyle(VST.Color.secondaryLabel)
                }
                HStack {
                    Button(screenAccess ? "Open Privacy Settings" : "Grant Access…") {
                        ScreenRecordingPermission.request()
                        screenAccess = ScreenRecordingPermission.isGranted
                    }
                    Button("Re-check") { screenAccess = ScreenRecordingPermission.isGranted }
                }
            }
            Section {
                Picker("Capture delay", selection: $settings.captureDelaySeconds) {
                    Text("None").tag(0)
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                }
                LabeledContent("Save to") {
                    HStack {
                        Text(settings.saveFolderURL.lastPathComponent)
                            .foregroundStyle(VST.Color.secondaryLabel)
                        Button("Change…") { chooseSaveFolder() }
                        Button("Reveal") {
                            NSWorkspace.shared.activateFileViewerSelecting([settings.saveFolderURL])
                        }
                    }
                }
                LabeledContent("Stack limit", value: "\(ScreenshotStack.maxItems) screenshots")
                LabeledContent("Formats", value: "PNG · JPG · PDF · TIFF")
            }
        }
        .formStyle(.grouped).padding()
        .onAppear { screenAccess = ScreenRecordingPermission.isGranted }
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
