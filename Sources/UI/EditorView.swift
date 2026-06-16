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

    init(image: NSImage, title: String, onOCR: @escaping (NSImage) -> Void) {
        _engine = StateObject(wrappedValue: AnnotationEngine(image: image))
        self.title = title
        self.onOCR = onOCR
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
                onCopy: copy,
                onSave: save,
                onShare: share,
                onOCR: { onOCR(engine.renderFlattened()) }
            )
        }
        .padding(VST.Spacing.lg)
        .frame(minWidth: 640, minHeight: 480)
        .background(VST.Color.surface)
        .navigationTitle(title)
    }

    private func copy() {
        ClipboardManager.copy(image: engine.renderFlattened())
    }

    private func save() {
        _ = ShareManager.saveWithPanel(image: engine.renderFlattened(), defaultName: title)
    }

    private func share(from view: NSView) {
        ShareManager.share(image: engine.renderFlattened(), from: view)
    }
}
