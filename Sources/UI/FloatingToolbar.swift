//
//  FloatingToolbar.swift
//  VyroShort
//
//  Tool selection + style controls for the editor.
//

import SwiftUI

struct FloatingToolbar: View {
    @ObservedObject var engine: AnnotationEngine

    var body: some View {
        HStack(spacing: VST.Spacing.sm) {
            ForEach(EditorTool.allCases) { tool in
                ToolButton(systemImage: tool.systemImage,
                           label: tool.label,
                           isActive: engine.tool == tool) {
                    engine.tool = tool
                }
            }

            Divider().frame(height: 20)

            // Color palette.
            HStack(spacing: 4) {
                ForEach(Array(VST.Color.toolPalette.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth:
                            color.hexString == engine.colorHex ? 2 : 0))
                        .onTapGesture { engine.colorHex = color.hexString }
                }
            }

            Divider().frame(height: 20)

            // Thickness.
            HStack(spacing: VST.Spacing.xs) {
                Image(systemName: "lineweight").font(.system(size: 11))
                Slider(value: $engine.lineWidth, in: 1...20).frame(width: 80)
            }
        }
        .padding(.horizontal, VST.Spacing.md)
        .padding(.vertical, VST.Spacing.sm)
        .glassPanel(cornerRadius: VST.Radius.md)
    }
}
