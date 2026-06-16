//
//  StackPanel.swift
//  VyroShort
//
//  Floating bottom-left panel showing recent screenshots as thumbnail cards.
//

import SwiftUI

struct StackPanel: View {
    @ObservedObject var stack: ScreenshotStack
    var onOpen: (ScreenshotItem) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: VST.Spacing.sm) {
            header
            if stack.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: VST.Spacing.sm) {
                        ForEach(stack.filteredItems) { item in
                            StackCard(
                                item: item,
                                thumbnail: stack.thumbnail(for: item),
                                isSelected: stack.selection.contains(item.id),
                                onOpen: { onOpen(item) },
                                onFavorite: { stack.toggleFavorite(item) },
                                onDelete: { stack.delete(item) }
                            )
                            .onTapGesture { toggleSelection(item) }
                        }
                    }
                    .padding(.horizontal, VST.Spacing.sm)
                    .padding(.bottom, VST.Spacing.sm)
                }
            }
        }
        .frame(width: 240, height: 360)
        .glassPanel()
    }

    private var header: some View {
        HStack(spacing: VST.Spacing.sm) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(VST.Color.accent)
            Text("Stack")
                .font(VST.Font.headline)
            Spacer()
            if !stack.selection.isEmpty {
                ToolButton(systemImage: "trash", label: "Delete selected", tint: VST.Color.error) {
                    stack.deleteSelected()
                }
            }
            ToolButton(systemImage: "xmark", label: "Hide stack") { onClose() }
        }
        .padding(.horizontal, VST.Spacing.md)
        .padding(.top, VST.Spacing.md)
    }

    private var emptyState: some View {
        VStack(spacing: VST.Spacing.sm) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 30))
                .foregroundStyle(VST.Color.secondaryLabel)
            Text("No screenshots yet")
                .font(VST.Font.caption)
                .foregroundStyle(VST.Color.secondaryLabel)
            Text("⌘⇧4 to capture")
                .font(VST.Font.caption)
                .foregroundStyle(VST.Color.secondaryLabel.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleSelection(_ item: ScreenshotItem) {
        if stack.selection.contains(item.id) {
            stack.selection.remove(item.id)
        } else {
            stack.selection.insert(item.id)
        }
    }
}

private struct StackCard: View {
    let item: ScreenshotItem
    let thumbnail: NSImage?
    let isSelected: Bool
    var onOpen: () -> Void
    var onFavorite: () -> Void
    var onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
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
            if hovering {
                ToolButton(systemImage: item.isFavorite ? "star.slash" : "star",
                           label: "Favorite") { onFavorite() }
                ToolButton(systemImage: "trash", label: "Delete", tint: VST.Color.error) { onDelete() }
            }
        }
        .padding(VST.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .fill(isSelected ? VST.Color.accentSoft
                      : (hovering ? Color.primary.opacity(0.06) : Color.primary.opacity(0.03)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: VST.Radius.md, style: .continuous)
                .strokeBorder(isSelected ? VST.Color.accent.opacity(0.6) : .clear, lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .onTapGesture(count: 2) { onOpen() }
        .animation(VST.Motion.quick, value: hovering)
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
