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
            let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 260, height: 240)) {
                StackPanel(
                    stack: self.stack,
                    onOpen: { [weak self] in self?.onOpen($0) },
                    onClose: { [weak self] in self?.hide() }
                )
            }
            panel.positionBottomLeft()
            panel.alphaValue = 1.0    // keep text crisp; transparency comes from the material
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
