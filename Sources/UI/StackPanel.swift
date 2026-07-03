//
//  StackPanel.swift
//  VyroShort
//
//  Compact floating widget: the 3 most recent screenshots.
//  Click a card to edit · trackpad-swipe left OR tap the trash to delete.
//  Uses the native Liquid Glass effect on macOS 26+.
//

import SwiftUI

struct StackPanel: View {
    @ObservedObject var stack: ScreenshotStack
    var onOpen: (ScreenshotItem) -> Void
    var onClose: () -> Void

    private var recent: [ScreenshotItem] { Array(stack.items.prefix(3)) }

    var body: some View {
        VStack(alignment: .leading, spacing: VST.Spacing.sm) {
            header
            if recent.isEmpty {
                emptyState
            } else {
                VStack(spacing: VST.Spacing.sm) {
                    ForEach(recent) { item in
                        SwipeRow(
                            content: StackCardContent(
                                item: item,
                                thumbnail: stack.thumbnail(for: item),
                                onOpen: { onOpen(item) },
                                onDelete: { delete(item) }
                            ),
                            onDelete: { delete(item) }
                        )
                        .frame(height: 52)
                    }
                }
                .padding(.horizontal, VST.Spacing.sm)
                .padding(.bottom, VST.Spacing.sm)
            }
        }
        .frame(width: 260, height: 240, alignment: .top)
        .liquidGlass(cornerRadius: 22)
    }

    private func delete(_ item: ScreenshotItem) {
        withAnimation(VST.Motion.quick) { stack.delete(item) }
    }

    private var header: some View {
        HStack(spacing: VST.Spacing.sm) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(VST.Color.accent)
            Text("Recent")
                .font(VST.Font.headline)
                .foregroundStyle(.primary.opacity(0.85))
            Spacer()
            Text("swipe to delete")
                .font(VST.Font.caption)
                .foregroundStyle(.primary.opacity(0.45))
            ToolButton(systemImage: "xmark", label: "Hide") { onClose() }
        }
        .padding(.horizontal, VST.Spacing.md)
        .padding(.top, VST.Spacing.md)
        .padding(.bottom, recent.isEmpty ? 0 : VST.Spacing.xs)
    }

    private var emptyState: some View {
        VStack(spacing: VST.Spacing.sm) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 26))
                .foregroundStyle(.primary.opacity(0.4))
            Text("No screenshots yet")
                .font(VST.Font.caption)
                .foregroundStyle(.primary.opacity(0.5))
            Text("⌘⇧Q to capture")
                .font(VST.Font.caption)
                .foregroundStyle(.primary.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VST.Spacing.xl)
    }
}

// MARK: - Card visual

private struct StackCardContent: View {
    let item: ScreenshotItem
    let thumbnail: NSImage?
    var onOpen: () -> Void
    var onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: VST.Spacing.sm) {
            thumb
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(VST.Font.caption)
                    .foregroundStyle(.primary.opacity(0.78))
                    .lineLimit(1)
                Text("\(item.pixelWidth)×\(item.pixelHeight)")
                    .font(VST.Font.caption)
                    .foregroundStyle(.primary.opacity(0.5))
            }
            Spacer(minLength: 0)
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(VST.Color.warning)
            }
            ToolButton(systemImage: "pencil", label: "Edit") { onOpen() }
                .opacity(hovering ? 1 : 0.55)
            ToolButton(systemImage: "trash", label: "Delete", tint: VST.Color.error) { onDelete() }
                .opacity(hovering ? 1 : 0.7)
        }
        .padding(VST.Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 52)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .fill(hovering ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .strokeBorder(hovering ? VST.Color.accent.opacity(0.5) : .white.opacity(0.06), lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .onTapGesture { onOpen() }
        .help("Click to edit · swipe left to delete")
    }

    private var thumb: some View {
        Group {
            if let thumbnail {
                Image(nsImage: thumbnail).resizable().aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.primary.opacity(0.1))
            }
        }
        .frame(width: 44, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: VST.Radius.sm, style: .continuous))
    }
}

// MARK: - Trackpad swipe host

/// Hosts the SwiftUI card in an AppKit view so it can receive trackpad
/// two-finger scroll (a real "swipe") to delete — SwiftUI drag gestures don't.
private struct SwipeRow<Content: View>: NSViewRepresentable {
    let content: Content
    let onDelete: () -> Void

    func makeNSView(context: Context) -> SwipeRowView {
        let v = SwipeRowView()
        v.onDelete = onDelete
        v.host(content)
        return v
    }

    func updateNSView(_ nsView: SwipeRowView, context: Context) {
        nsView.onDelete = onDelete
        nsView.update(content)
    }
}

private final class SwipeRowView: NSView {
    var onDelete: (() -> Void)?
    private var hosting: NSHostingView<AnyView>?
    private let track = CALayer()
    private let trash = CATextLayer()
    private var offset: CGFloat = 0
    private var accum: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        track.backgroundColor = NSColor.systemRed.cgColor
        track.cornerRadius = 10
        track.opacity = 0
        layer?.addSublayer(track)
    }
    required init?(coder: NSCoder) { fatalError() }

    func host(_ view: some View) {
        let h = NSHostingView(rootView: AnyView(view))
        h.translatesAutoresizingMaskIntoConstraints = true
        addSubview(h)
        hosting = h
        needsLayout = true
    }

    func update(_ view: some View) { hosting?.rootView = AnyView(view) }

    override func layout() {
        super.layout()
        track.frame = bounds
        hosting?.frame = CGRect(x: offset, y: 0, width: bounds.width, height: bounds.height)
    }

    override func scrollWheel(with event: NSEvent) {
        // Only react to a dominantly-horizontal gesture.
        guard abs(event.scrollingDeltaX) >= abs(event.scrollingDeltaY) else { return }
        if event.phase == .began { accum = 0 }
        accum += event.scrollingDeltaX
        // Leftward travel (negative) reveals the delete; ignore rightward.
        offset = max(-160, accum < 0 ? accum : 0)
        apply(animated: false)

        if event.phase == .ended || event.momentumPhase == .ended || event.phase == .cancelled {
            if offset < -55 {
                offset = -bounds.width
                apply(animated: true)
                onDelete?()
            } else {
                offset = 0
                apply(animated: true)
            }
            accum = 0
        }
    }

    private func apply(animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        hosting?.frame = CGRect(x: offset, y: 0, width: bounds.width, height: bounds.height)
        track.opacity = Float(min(1, -offset / 55))
        CATransaction.commit()
    }
}

// MARK: - Liquid Glass

private extension View {
    /// Native Liquid Glass on macOS 26+, ultraThinMaterial fallback below.
    @ViewBuilder
    func liquidGlass(cornerRadius r: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: r, style: .continuous)
        if #available(macOS 26.0, *) {
            // No manual shadow — it would be clipped by the panel window bounds and
            // show up as sharp dark corners. Liquid Glass provides its own edge.
            self.glassEffect(.regular, in: shape)
                .clipShape(shape)
        } else {
            self.background(shape.fill(.ultraThinMaterial))
                .overlay(shape.strokeBorder(.white.opacity(0.12), lineWidth: 1))
                .clipShape(shape)
        }
    }
}
