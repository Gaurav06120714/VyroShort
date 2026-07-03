//
//  ScreenshotStack.swift
//  VyroShort
//
//  Observable store backing the floating screenshot stack. Persists with SwiftData,
//  caps at 100 items, and exposes add / rename / delete / favorite / reorder.
//

import AppKit
import SwiftData
import SwiftUI

@MainActor
final class ScreenshotStack: ObservableObject {
    static let maxItems = 100

    @Published private(set) var items: [ScreenshotItem] = []
    @Published var selection: Set<UUID> = []
    @Published var searchText: String = ""

    private let context: ModelContext

    init(context: ModelContext = ModelContext(CaptureStorage.container)) {
        self.context = context
        reload()
    }

    var filteredItems: [ScreenshotItem] {
        guard !searchText.isEmpty else { return items }
        let q = searchText.lowercased()
        return items.filter {
            $0.name.lowercased().contains(q) ||
            ($0.ocrText?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.name.lowercased().contains(q) }
        }
    }

    func reload() {
        let descriptor = FetchDescriptor<ScreenshotItem>(
            sortBy: [SortDescriptor(\.sortIndex, order: .reverse),
                     SortDescriptor(\.createdAt, order: .reverse)]
        )
        items = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Mutations

    @discardableResult
    func add(image: NSImage, name: String? = nil) -> ScreenshotItem? {
        guard let stored = CaptureStorage.persist(image: image) else { return nil }
        let index = (items.map(\.sortIndex).max() ?? 0) + 1
        let item = ScreenshotItem(
            name: name ?? Self.defaultName(),
            fileName: stored.fileName,
            thumbnailName: stored.thumbName,
            pixelWidth: Int(stored.size.width),
            pixelHeight: Int(stored.size.height),
            sortIndex: index
        )
        context.insert(item)
        save()
        reload()
        enforceLimit()
        return item
    }

    func rename(_ item: ScreenshotItem, to newName: String) {
        item.name = newName.isEmpty ? Self.defaultName() : newName
        save()
        reload()
    }

    func toggleFavorite(_ item: ScreenshotItem) {
        item.isFavorite.toggle()
        save()
        reload()
    }

    func delete(_ item: ScreenshotItem) {
        CaptureStorage.delete(fileName: item.fileName, thumbnailName: item.thumbnailName)
        context.delete(item)
        selection.remove(item.id)
        save()
        reload()
    }

    func deleteSelected() {
        items.filter { selection.contains($0.id) }.forEach { item in
            CaptureStorage.delete(fileName: item.fileName, thumbnailName: item.thumbnailName)
            context.delete(item)
        }
        selection.removeAll()
        save()
        reload()
    }

    func image(for item: ScreenshotItem) -> NSImage? {
        NSImage(contentsOf: CaptureStorage.fileURL(for: item.fileName))
    }

    func thumbnail(for item: ScreenshotItem) -> NSImage? {
        if let name = item.thumbnailName,
           let img = NSImage(contentsOf: CaptureStorage.thumbnailURL(for: name)) {
            return img
        }
        return image(for: item)
    }

    // MARK: - Private

    private func enforceLimit() {
        guard items.count > Self.maxItems else { return }
        let overflow = items
            .filter { !$0.isFavorite }
            .sorted { $0.createdAt < $1.createdAt }
            .prefix(items.count - Self.maxItems)
        overflow.forEach(delete)
    }

    private func save() {
        try? context.save()
    }

    static func defaultName() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d 'at' h.mm.ss a"
        return "Screenshot \(fmt.string(from: .now))"
    }
}
