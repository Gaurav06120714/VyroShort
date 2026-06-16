//
//  VyroShortTests.swift
//  VyroShortTests
//

import XCTest
import SwiftData
import SwiftUI
@testable import VyroShort

final class VyroShortTests: XCTestCase {

    @MainActor
    func testAppearanceModeColorScheme() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
    }

    func testColorHexRoundTrip() {
        XCTAssertEqual(Color(hex: "#FF0000").hexString, "#FF0000")
        XCTAssertEqual(Color(hex: "00FF00").hexString, "#00FF00")
    }

    func testAnnotationRectNormalizes() {
        let a = Annotation(tool: .rectangle,
                           start: CGPoint(x: 100, y: 80),
                           end: CGPoint(x: 20, y: 10),
                           colorHex: "#FFFFFF", lineWidth: 3, opacity: 1)
        XCTAssertEqual(a.rect, CGRect(x: 20, y: 10, width: 80, height: 70))
    }

    @MainActor
    func testEngineUndoRedoClear() {
        let engine = AnnotationEngine(image: makeImage())
        XCTAssertFalse(engine.canUndo)

        var a = engine.makeAnnotation(start: .zero)
        a.end = CGPoint(x: 10, y: 10)
        engine.beginAnnotation(a)
        XCTAssertEqual(engine.annotations.count, 1)
        XCTAssertTrue(engine.canUndo)

        engine.undo()
        XCTAssertEqual(engine.annotations.count, 0)
        XCTAssertTrue(engine.canRedo)

        engine.redo()
        XCTAssertEqual(engine.annotations.count, 1)

        engine.clearAll()
        XCTAssertTrue(engine.annotations.isEmpty)
    }

    @MainActor
    func testEngineAddText() {
        let engine = AnnotationEngine(image: makeImage())
        engine.addText(at: CGPoint(x: 5, y: 5), text: "Hello")
        XCTAssertEqual(engine.annotations.first?.text, "Hello")
        XCTAssertEqual(engine.annotations.first?.tool, .text)
    }

    @MainActor
    func testClipboardHistoryCap() {
        let history = ClipboardHistory.shared
        history.clear()
        for _ in 0..<(ClipboardHistory.maxItems + 10) {
            history.record(makeImage())
        }
        XCTAssertEqual(history.entries.count, ClipboardHistory.maxItems)
        history.clear()
    }

    @MainActor
    func testScreenshotStackAddDelete() throws {
        let container = try ModelContainer(
            for: ScreenshotItem.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let stack = ScreenshotStack(context: ModelContext(container))
        XCTAssertTrue(stack.items.isEmpty)

        let item = stack.add(image: makeImage())
        XCTAssertEqual(stack.items.count, 1)

        if let item {
            stack.toggleFavorite(item)
            XCTAssertTrue(stack.items.first?.isFavorite ?? false)
            stack.delete(item)
        }
        XCTAssertTrue(stack.items.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private func makeImage(_ size: CGSize = CGSize(width: 40, height: 30)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
}
