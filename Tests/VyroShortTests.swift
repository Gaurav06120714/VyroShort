//
//  VyroShortTests.swift
//  VyroShortTests
//

import XCTest
@testable import VyroShort

final class VyroShortTests: XCTestCase {
    @MainActor
    func testAppearanceModeColorScheme() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
    }
}
