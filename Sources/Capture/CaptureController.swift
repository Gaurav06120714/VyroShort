//
//  CaptureController.swift
//  VyroShort
//
//  Orchestrates the capture flow: overlay selection → ScreenCaptureKit → ingest.
//

import AppKit

@MainActor
final class CaptureController {
    private let manager = ScreenCaptureManager()
    private let overlay = RegionSelectionOverlay()
    private let onCapture: (NSImage) -> Void

    init(onCapture: @escaping (NSImage) -> Void) {
        self.onCapture = onCapture
    }

    func fullScreen() {
        Task { await run { try await self.manager.captureFullScreen() } }
    }

    func region() {
        overlay.begin(mode: .region) { [weak self] rect in
            guard let self, let rect, rect.width > 1, rect.height > 1 else { return }
            Task { await self.run { try await self.manager.captureRegion(rect) } }
        }
    }

    func window() {
        overlay.begin(mode: .window) { [weak self] rect in
            guard let self, let rect else { return }
            let point = CGPoint(x: rect.minX, y: rect.minY)
            Task { await self.run { try await self.manager.captureWindow(at: point) } }
        }
    }

    func delayed(seconds: Int, _ block: @escaping () -> Void) {
        guard seconds > 0 else { block(); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds), execute: block)
    }

    // MARK: - Private

    private func run(_ capture: @escaping () async throws -> NSImage) async {
        do {
            let image = try await capture()
            playShutterIfEnabled()
            onCapture(image)
        } catch {
            NSLog("VyroShort capture failed: \(error)")
            presentPermissionHintIfNeeded(error)
        }
    }

    private func playShutterIfEnabled() {
        if AppSettings.shared.playCaptureSound {
            NSSound(named: "Grab")?.play()
        }
    }

    private func presentPermissionHintIfNeeded(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Capture failed"
        alert.informativeText = "VyroShort needs Screen Recording permission. Grant it in System Settings → Privacy & Security → Screen Recording, then relaunch."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
