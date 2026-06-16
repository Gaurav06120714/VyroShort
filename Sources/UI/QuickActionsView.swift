//
//  QuickActionsView.swift
//  VyroShort
//

import SwiftUI

struct QuickActionsView: View {
    @ObservedObject var engine: AnnotationEngine
    var onCopy: () -> Void
    var onSave: () -> Void
    var onShare: (NSView) -> Void
    var onOCR: () -> Void

    var body: some View {
        HStack(spacing: VST.Spacing.sm) {
            ToolButton(systemImage: "arrow.uturn.backward", label: "Undo") { engine.undo() }
                .disabled(!engine.canUndo)
            ToolButton(systemImage: "arrow.uturn.forward", label: "Redo") { engine.redo() }
                .disabled(!engine.canRedo)
            ToolButton(systemImage: "eraser", label: "Clear annotations", tint: VST.Color.error) {
                engine.clearAll()
            }

            Divider().frame(height: 20)

            ToolButton(systemImage: "text.viewfinder", label: "Extract text (OCR)") { onOCR() }

            Spacer(minLength: VST.Spacing.lg)

            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.borderedProminent)
            Button(action: onSave) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            ShareButton(onShare: onShare)
        }
        .padding(.horizontal, VST.Spacing.md)
        .padding(.vertical, VST.Spacing.sm)
        .glassPanel(cornerRadius: VST.Radius.md)
    }
}

/// Anchors the macOS share sheet to a real NSView.
private struct ShareButton: NSViewRepresentable {
    var onShare: (NSView) -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "", image: NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Share")!, target: context.coordinator, action: #selector(Coordinator.share))
        button.bezelStyle = .rounded
        button.imagePosition = .imageOnly
        context.coordinator.onShare = onShare
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.onShare = onShare
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var onShare: ((NSView) -> Void)?
        weak var button: NSButton?
        @objc func share() { if let b = button { onShare?(b) } }
    }
}
