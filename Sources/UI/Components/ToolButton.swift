//
//  ToolButton.swift
//  VyroShort
//
//  Shared icon button used by the floating toolbar and quick actions.
//

import SwiftUI

struct ToolButton: View {
    let systemImage: String
    var label: String? = nil
    var isActive: Bool = false
    var tint: Color = VST.Color.label
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 30, height: 30)
                .foregroundStyle(isActive ? VST.Color.accent : tint)
                .background(
                    RoundedRectangle(cornerRadius: VST.Radius.sm, style: .continuous)
                        .fill(isActive ? VST.Color.accentSoft
                              : (hovering ? Color.primary.opacity(0.08) : .clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label ?? "")
        .onHover { hovering = $0 }
        .animation(VST.Motion.quick, value: hovering)
        .animation(VST.Motion.quick, value: isActive)
    }
}
