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

    /// Warms up ScreenCaptureKit so the first capture isn't slow.
    func warmUp() {
        Task { await manager.warmUp() }
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
        // Only nag about permission when that's actually the cause.
        guard !ScreenRecordingPermission.isGranted else { return }
        let alert = NSAlert()
        alert.messageText = "Screen Recording permission needed"
        alert.informativeText = "VyroShort needs Screen Recording to capture. Grant it in System Settings → Privacy & Security → Screen Recording, then relaunch VyroShort."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            ScreenRecordingPermission.openPrivacySettings()
        }
    }
}
