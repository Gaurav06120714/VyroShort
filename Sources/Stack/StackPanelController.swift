//
//  StackPanelController.swift
//  VyroShort
//
//  Shows / hides the floating screenshot stack panel.
//

import AppKit
import SwiftUI

@MainActor
final class StackPanelController {
    private var panel: FloatingPanel<StackPanel>?
    private let stack: ScreenshotStack
    private let onOpen: (ScreenshotItem) -> Void

    init(stack: ScreenshotStack, onOpen: @escaping (ScreenshotItem) -> Void) {
        self.stack = stack
        self.onOpen = onOpen
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func show() {
        if panel == nil {
            let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 240, height: 360)) {
                StackPanel(
                    stack: self.stack,
                    onOpen: { [weak self] in self?.onOpen($0) },
                    onClose: { [weak self] in self?.hide() }
                )
            }
            panel.positionBottomLeft()
            panel.alphaValue = 0.86   // see-through, frosted look
            self.panel = panel
        }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        isVisible ? hide() : show()
    }
}
