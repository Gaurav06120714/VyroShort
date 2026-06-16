//
//  Models.swift
//  VyroShort
//
//  SwiftData persistence models for screenshots and tags.
//

import Foundation
import SwiftData

@Model
final class ScreenshotItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    /// Relative filename of the full-resolution PNG inside the captures directory.
    var fileName: String
    /// Relative filename of the cached thumbnail PNG.
    var thumbnailName: String?
    var pixelWidth: Int
    var pixelHeight: Int
    var isFavorite: Bool
    var ocrText: String?
    var sortIndex: Int

    @Relationship(deleteRule: .nullify, inverse: \Tag.items)
    var tags: [Tag]

    init(id: UUID = UUID(),
         name: String,
         createdAt: Date = .now,
         fileName: String,
         thumbnailName: String? = nil,
         pixelWidth: Int = 0,
         pixelHeight: Int = 0,
         isFavorite: Bool = false,
         ocrText: String? = nil,
         sortIndex: Int = 0,
         tags: [Tag] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.fileName = fileName
        self.thumbnailName = thumbnailName
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.isFavorite = isFavorite
        self.ocrText = ocrText
        self.sortIndex = sortIndex
        self.tags = tags
    }
}

@Model
final class Tag {
    @Attribute(.unique) var name: String
    var colorHex: String
    var items: [ScreenshotItem]

    init(name: String, colorHex: String = "#5B73FA", items: [ScreenshotItem] = []) {
        self.name = name
        self.colorHex = colorHex
        self.items = items
    }
}
