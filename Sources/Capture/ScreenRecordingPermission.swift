//
//  ScreenRecordingPermission.swift
//  VyroShort
//
//  Centralized Screen Recording (TCC) permission checks and requests.
//

import AppKit
import CoreGraphics

@MainActor
enum ScreenRecordingPermission {
    /// Whether VyroShort currently has Screen Recording access.
    static var isGranted: Bool { CGPreflightScreenCaptureAccess() }

    /// Triggers the system prompt (first time) or opens the Privacy pane.
    /// Returns the resulting access state.
    @discardableResult
    static func request() -> Bool {
        if isGranted { openPrivacySettings(); return true }
        let granted = CGRequestScreenCaptureAccess()
        if !granted { openPrivacySettings() }
        return granted
    }

    static func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
