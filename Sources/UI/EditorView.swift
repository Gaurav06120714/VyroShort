//
//  EditorView.swift
//  VyroShort
//
//  Floating editor: toolbar (top) · canvas (center) · quick actions (bottom).
//

import SwiftUI

struct EditorView: View {
    @StateObject private var engine: AnnotationEngine
    private let title: String
    private let onOCR: (NSImage) -> Void
    private let onClose: () -> Void

    init(image: NSImage,
         title: String,
         onOCR: @escaping (NSImage) -> Void,
         onClose: @escaping () -> Void = {}) {
        _engine = StateObject(wrappedValue: AnnotationEngine(image: image))
        self.title = title
        self.onOCR = onOCR
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: VST.Spacing.md) {
            FloatingToolbar(engine: engine)

            CanvasView(engine: engine)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: VST.Radius.md)
                        .fill(Color.black.opacity(0.2))
                )

            QuickActionsView(
                engine: engine,
                onCopy: copyAndClose,
                onSave: save,
                onShare: share,
                onOCR: { onOCR(engine.renderFlattened()) }
            )
        }
        .padding(VST.Spacing.lg)
        .frame(minWidth: 640, minHeight: 480)
        .background(VST.Color.surface)
        .navigationTitle(title)
        .background(keyboardShortcuts)
    }

    /// Hidden buttons that bind ⌘Z / ⌘⇧Z / ⌘C / ⌫ while the window is key.
    private var keyboardShortcuts: some View {
        ZStack {
            Button("") { engine.undo() }.keyboardShortcut("z", modifiers: .command)
            Button("") { engine.redo() }.keyboardShortcut("z", modifiers: [.command, .shift])
            Button("") { copyAndClose() }.keyboardShortcut("c", modifiers: .command)
            Button("") { engine.deleteSelected() }.keyboardShortcut(.delete, modifiers: [])
        }
        .opacity(0)
        .allowsHitTesting(false)
    }

    /// Copy to the clipboard, then close the editor window (per user request).
    private func copyAndClose() {
        ClipboardManager.copy(image: engine.renderFlattened())
        onClose()
    }

    private func save() {
        _ = ShareManager.saveWithPanel(image: engine.renderFlattened(), defaultName: title)
    }

    private func share(from view: NSView) {
        ShareManager.share(image: engine.renderFlattened(), from: view)
    }
}
