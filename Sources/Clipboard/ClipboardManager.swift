//
//  ClipboardManager.swift
//  VyroShort
//
//  Writes captures to the system pasteboard. Clipboard history lives in M7.
//

import AppKit

@MainActor
enum ClipboardManager {
    static func copy(image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
        ClipboardHistory.shared.record(image)
    }

    static func copy(text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
