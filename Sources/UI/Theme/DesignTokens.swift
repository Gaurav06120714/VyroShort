//
//  DesignTokens.swift
//  VyroShort
//
//  Central design system: spacing, radius, typography, color, motion.
//  Inspired by Raycast / Arc / Linear / CleanShot X. Glassmorphism-first.
//

import SwiftUI

enum VST {
    // MARK: - Spacing (4pt grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Color (semantic, adapts to light/dark)
    enum Color {
        static let accent = SwiftUI.Color(red: 0.36, green: 0.45, blue: 0.98)        // VyroShort indigo
        static let accentSoft = SwiftUI.Color(red: 0.36, green: 0.45, blue: 0.98).opacity(0.16)
        static let success = SwiftUI.Color(red: 0.20, green: 0.78, blue: 0.45)
        static let warning = SwiftUI.Color(red: 0.98, green: 0.71, blue: 0.18)
        static let error = SwiftUI.Color(red: 0.96, green: 0.32, blue: 0.36)
        static let info = SwiftUI.Color(red: 0.30, green: 0.66, blue: 0.96)

        static let surface = SwiftUI.Color(nsColor: .windowBackgroundColor)
        static let surfaceRaised = SwiftUI.Color(nsColor: .controlBackgroundColor)
        static let label = SwiftUI.Color(nsColor: .labelColor)
        static let secondaryLabel = SwiftUI.Color(nsColor: .secondaryLabelColor)
        static let separator = SwiftUI.Color(nsColor: .separatorColor)

        /// Annotation tool palette.
        static let toolPalette: [SwiftUI.Color] = [
            error, warning, success, info, accent,
            .white, .black, SwiftUI.Color(red: 0.6, green: 0.2, blue: 0.9)
        ]
    }

    // MARK: - Typography
    enum Font {
        static let title = SwiftUI.Font.system(size: 15, weight: .semibold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 13, weight: .semibold, design: .rounded)
        static let body = SwiftUI.Font.system(size: 12, weight: .regular)
        static let caption = SwiftUI.Font.system(size: 11, weight: .medium)
        static let mono = SwiftUI.Font.system(size: 12, weight: .regular, design: .monospaced)
    }

    // MARK: - Motion
    enum Motion {
        static let quick = SwiftUI.Animation.spring(response: 0.28, dampingFraction: 0.82)
        static let smooth = SwiftUI.Animation.spring(response: 0.42, dampingFraction: 0.85)
        static let pop = SwiftUI.Animation.spring(response: 0.34, dampingFraction: 0.66)
    }

    // MARK: - Elevation
    enum Shadow {
        static let panel = (color: SwiftUI.Color.black.opacity(0.28), radius: CGFloat(22), y: CGFloat(10))
        static let card = (color: SwiftUI.Color.black.opacity(0.18), radius: CGFloat(10), y: CGFloat(4))
    }
}
