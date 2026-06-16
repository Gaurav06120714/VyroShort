//
//  ClipboardHistory.swift
//  VyroShort
//
//  Keeps the last 50 copied captures for quick restore / re-copy.
//

import AppKit

@MainActor
final class ClipboardHistory: ObservableObject {
    static let shared = ClipboardHistory()
    static let maxItems = 50

    struct Entry: Identifiable {
        let id = UUID()
        let image: NSImage
        let date: Date
    }

    @Published private(set) var entries: [Entry] = []

    private init() {}

    func record(_ image: NSImage) {
        entries.insert(Entry(image: image, date: .now), at: 0)
        if entries.count > Self.maxItems {
            entries.removeLast(entries.count - Self.maxItems)
        }
    }

    func restore(_ entry: Entry) {
        ClipboardManager.copy(image: entry.image)
    }

    func clear() {
        entries.removeAll()
    }
}
