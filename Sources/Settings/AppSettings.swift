//
//  AppSettings.swift
//  VyroShort
//
//  Persisted user preferences backed by UserDefaults. Expanded in M7.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("appearanceMode") var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("autoCopyOnCapture") var autoCopyOnCapture: Bool = true
    @AppStorage("playCaptureSound") var playCaptureSound: Bool = true
    @AppStorage("showStackPanel") var showStackPanel: Bool = true
    @AppStorage("captureDelaySeconds") var captureDelaySeconds: Int = 0

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    private init() {}
}
