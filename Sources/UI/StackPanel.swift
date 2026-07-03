//
//  StackPanel.swift
//  VyroShort
//
//  Compact floating widget: the 3 most recent screenshots.
//  Click a card to edit · swipe left to delete.
//

import SwiftUI

struct StackPanel: View {
    @ObservedObject var stack: ScreenshotStack
    var onOpen: (ScreenshotItem) -> Void
    var onClose: () -> Void

    /// Only the most recent few are shown in the widget.
    private var recent: [ScreenshotItem] { Array(stack.items.prefix(3)) }

    var body: some View {
        VStack(alignment: .leading, spacing: VST.Spacing.sm) {
            header
            if recent.isEmpty {
                emptyState
            } else {
                VStack(spacing: VST.Spacing.sm) {
                    ForEach(recent) { item in
                        SwipeCard(
                            item: item,
                            thumbnail: stack.thumbnail(for: item),
                            onOpen: { onOpen(item) },
                            onDelete: { withAnimation(VST.Motion.quick) { stack.delete(item) } }
                        )
                    }
                }
                .padding(.horizontal, VST.Spacing.sm)
                .padding(.bottom, VST.Spacing.sm)
            }
        }
        .frame(width: 260, height: 240, alignment: .top)
        .glassPanel()
    }

    private var header: some View {
        HStack(spacing: VST.Spacing.sm) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(VST.Color.accent)
            Text("Recent")
                .font(VST.Font.headline)
            Spacer()
            Text("swipe to delete")
                .font(VST.Font.caption)
                .foregroundStyle(VST.Color.secondaryLabel)
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
                .foregroundStyle(VST.Color.secondaryLabel)
            Text("No screenshots yet")
                .font(VST.Font.caption)
                .foregroundStyle(VST.Color.secondaryLabel)
            Text("⌘⇧Q to capture")
                .font(VST.Font.caption)
                .foregroundStyle(VST.Color.secondaryLabel.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VST.Spacing.xl)
    }
}

/// A recent-screenshot card that opens on tap and deletes when swiped left.
private struct SwipeCard: View {
    let item: ScreenshotItem
    let thumbnail: NSImage?
    var onOpen: () -> Void
    var onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var hovering = false

    private let deleteThreshold: CGFloat = -60

    var body: some View {
        ZStack(alignment: .trailing) {
            // Red delete track revealed underneath as the card slides left.
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .fill(VST.Color.error.opacity(min(1, Double(-offset) / 80)))
                .overlay(
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .padding(.trailing, VST.Spacing.lg)
                        .opacity(min(1, Double(-offset) / 60)),
                    alignment: .trailing
                )

            card
                .offset(x: offset)
                .highPriorityGesture(swipe)
                .onTapGesture { if offset == 0 { onOpen() } }
        }
        .frame(height: 52)
    }

    private var card: some View {
        HStack(spacing: VST.Spacing.sm) {
            thumb
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(VST.Font.caption)
                    .lineLimit(1)
                Text("\(item.pixelWidth)×\(item.pixelHeight)")
                    .font(VST.Font.caption)
                    .foregroundStyle(VST.Color.secondaryLabel)
            }
            Spacer(minLength: 0)
            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(VST.Color.warning)
            }
            // Always-visible actions so deletion never depends on a finicky swipe.
            if offset == 0 {
                ToolButton(systemImage: "pencil", label: "Edit") { onOpen() }
                    .opacity(hovering ? 1 : 0.55)
                ToolButton(systemImage: "trash", label: "Delete", tint: VST.Color.error) { onDelete() }
                    .opacity(hovering ? 1 : 0.7)
            }
        }
        .padding(VST.Spacing.sm)
        .frame(height: 52)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .fill(hovering ? Color(nsColor: .controlBackgroundColor).opacity(0.9)
                      : Color(nsColor: .controlBackgroundColor).opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .strokeBorder(hovering ? VST.Color.accent.opacity(0.5) : .white.opacity(0.06), lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .help("Click to edit · swipe left to delete")
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                offset = min(0, value.translation.width)   // left only
            }
            .onEnded { value in
                if value.translation.width < deleteThreshold {
                    withAnimation(VST.Motion.quick) { offset = -300 }
                    onDelete()
                } else {
                    withAnimation(VST.Motion.quick) { offset = 0 }
                }
            }
    }

    private var thumb: some View {
        Group {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(Color.primary.opacity(0.1))
            }
        }
        .frame(width: 44, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: VST.Radius.sm, style: .continuous))
    }
}
