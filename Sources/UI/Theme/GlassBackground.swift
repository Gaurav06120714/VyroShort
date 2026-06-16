//
//  GlassBackground.swift
//  VyroShort
//
//  Reusable glassmorphism surfaces and modifiers.
//

import SwiftUI

/// A frosted, vibrant material backing used by floating panels and toolbars.
struct GlassBackground: View {
    var cornerRadius: CGFloat = VST.Radius.lg
    var material: NSVisualEffectView.Material = .hudWindow

    var body: some View {
        VisualEffectBlur(material: material, blendingMode: .behindWindow)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// AppKit NSVisualEffectView bridged into SwiftUI.
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension View {
    /// Wraps content in a floating glass card with VyroShort elevation.
    func glassPanel(cornerRadius: CGFloat = VST.Radius.lg,
                    material: NSVisualEffectView.Material = .hudWindow) -> some View {
        background(GlassBackground(cornerRadius: cornerRadius, material: material))
            .shadow(color: VST.Shadow.panel.color,
                    radius: VST.Shadow.panel.radius,
                    y: VST.Shadow.panel.y)
    }
}
