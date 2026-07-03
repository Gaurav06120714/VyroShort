//
//  CanvasView.swift
//  VyroShort
//
//  Renders the base screenshot plus annotations. `CanvasContent` is the pure,
//  reusable renderer (also used by ImageRenderer for export); `CanvasView`
//  adds interactive drawing gestures and text editing.
//

import SwiftUI

/// Pure renderer — base image + annotations drawn to `displaySize`.
struct CanvasContent: View {
    @ObservedObject var engine: AnnotationEngine
    let displaySize: CGSize
    var interactive: Bool

    private var scale: CGFloat {
        engine.pixelSize.width > 0 ? displaySize.width / engine.pixelSize.width : 1
    }

    var body: some View {
        ZStack {
            Image(nsImage: engine.baseImage)
                .resizable()
                .frame(width: displaySize.width, height: displaySize.height)

            Canvas { context, _ in
                for a in engine.annotations {
                    draw(a, in: &context)
                }
            }
            .frame(width: displaySize.width, height: displaySize.height)
        }
        .frame(width: displaySize.width, height: displaySize.height)
    }

    private func p(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale, y: point.y * scale)
    }

    private func draw(_ a: Annotation, in context: inout GraphicsContext) {
        let r = CGRect(x: a.rect.minX * scale, y: a.rect.minY * scale,
                       width: a.rect.width * scale, height: a.rect.height * scale)
        let lw = a.lineWidth * scale
        let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)

        switch a.tool {
        case .rectangle:
            context.stroke(Path(roundedRect: r, cornerRadius: 4 * scale), with: .color(a.color.opacity(a.opacity)), style: stroke)
        case .ellipse:
            context.stroke(Path(ellipseIn: r), with: .color(a.color.opacity(a.opacity)), style: stroke)
        case .line:
            var path = Path()
            path.move(to: p(a.start)); path.addLine(to: p(a.end))
            context.stroke(path, with: .color(a.color.opacity(a.opacity)), style: stroke)
        case .arrow:
            drawArrow(from: p(a.start), to: p(a.end), color: a.color.opacity(a.opacity), lineWidth: lw, in: &context)
        case .highlight:
            context.fill(Path(roundedRect: r, cornerRadius: 2 * scale), with: .color(a.color.opacity(max(a.opacity, 0.25))))
        case .blur:
            var clipped = context
            clipped.clip(to: Path(roundedRect: r, cornerRadius: 4 * scale))
            let img = Image(nsImage: engine.blurredImage)
            clipped.draw(img, in: CGRect(origin: .zero, size: displaySize))
        case .text:
            let text = Text(a.text.isEmpty ? " " : a.text)
                .font(.system(size: a.fontSize * scale, weight: .semibold))
                .foregroundColor(a.color)
            context.draw(text, at: p(a.start), anchor: .topLeading)
        case .crop, .select:
            break
        }
    }

    private func drawArrow(from: CGPoint, to: CGPoint, color: Color, lineWidth: CGFloat, in context: inout GraphicsContext) {
        var shaft = Path()
        shaft.move(to: from); shaft.addLine(to: to)
        context.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

        let angle = atan2(to.y - from.y, to.x - from.x)
        let headLength = max(lineWidth * 3.5, 12)
        let spread = CGFloat.pi / 7
        var head = Path()
        head.move(to: to)
        head.addLine(to: CGPoint(x: to.x - headLength * cos(angle - spread),
                                 y: to.y - headLength * sin(angle - spread)))
        head.move(to: to)
        head.addLine(to: CGPoint(x: to.x - headLength * cos(angle + spread),
                                 y: to.y - headLength * sin(angle + spread)))
        context.stroke(head, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

/// Interactive editor canvas.
struct CanvasView: View {
    @ObservedObject var engine: AnnotationEngine
    @State private var editingTextID: UUID?
    @State private var editingText: String = ""
    @FocusState private var textFocused: Bool
    @State private var move: MoveState?
    @State private var activeDrawID: UUID?     // set while a shape is being drawn

    private struct MoveState {
        let id: UUID
        let origStart: CGPoint
        let origEnd: CGPoint
        let grab: CGPoint     // image-space point where the drag began
    }

    var body: some View {
        GeometryReader { geo in
            let displaySize = fittedSize(in: geo.size)
            let scale = engine.pixelSize.width > 0 ? displaySize.width / engine.pixelSize.width : 1

            ZStack(alignment: .topLeading) {
                CanvasContent(engine: engine, displaySize: displaySize, interactive: true)

                // Crop dimming overlay.
                if let crop = engine.cropRect {
                    cropOverlay(crop: crop, displaySize: displaySize, scale: scale)
                }

                // Selection highlight (Select tool).
                if engine.tool == .select, let id = engine.selectedID,
                   let a = engine.annotation(id) {
                    let r = a.rect
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(VST.Color.accent, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .frame(width: max(r.width, 12) * scale + 10, height: max(r.height, 12) * scale + 10)
                        .position(x: (r.midX) * scale, y: (r.midY) * scale)
                        .allowsHitTesting(false)
                }

                // Inline text editor.
                if let id = editingTextID, let a = engine.annotations.first(where: { $0.id == id }) {
                    TextField("Text", text: $editingText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: a.fontSize * scale, weight: .semibold))
                        .foregroundColor(a.color)
                        .focused($textFocused)
                        .frame(maxWidth: displaySize.width - a.start.x * scale, alignment: .leading)
                        .position(x: a.start.x * scale + 4, y: a.start.y * scale + a.fontSize * scale / 2)
                        .onChange(of: editingText) { _, new in engine.updateText(id: id, text: new) }
                        .onSubmit { commitText() }
                }
            }
            .frame(width: displaySize.width, height: displaySize.height)
            // Gestures MUST attach to the canvas-sized frame so cursor coordinates
            // match the drawing — attaching after centering would offset them.
            .contentShape(Rectangle())
            .gesture(drawGesture(scale: scale, displaySize: displaySize))
            .onTapGesture { location in handleTap(location, scale: scale) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fittedSize(in available: CGSize) -> CGSize {
        let ps = engine.pixelSize
        guard ps.width > 0, ps.height > 0 else { return available }
        let scale = min(available.width / ps.width, available.height / ps.height, 1)
        return CGSize(width: ps.width * scale, height: ps.height * scale)
    }

    private func drawGesture(scale: CGFloat, displaySize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let start = imagePoint(value.startLocation, scale: scale)
                let current = imagePoint(value.location, scale: scale)

                // Select tool: grab the annotation under the cursor and drag it.
                if engine.tool == .select {
                    handleMove(start: start, current: current)
                    return
                }

                guard engine.tool.isDraggableShape else { return }
                // Start a new shape on the first change of each drag; update it after.
                if activeDrawID == nil {
                    var a = engine.makeAnnotation(start: start)
                    a.end = current
                    engine.beginAnnotation(a)
                    activeDrawID = a.id
                } else {
                    engine.updateLast(end: current)
                }
            }
            .onEnded { _ in
                if engine.tool == .crop, let last = engine.annotations.last, last.tool == .crop {
                    engine.annotations.removeLast()
                    engine.setCrop(last.rect)
                }
                activeDrawID = nil
                move = nil
                if engine.tool != .select { engine.selectedID = nil }
            }
    }

    private func handleMove(start: CGPoint, current: CGPoint) {
        if move == nil {
            guard let id = engine.hitTest(start), let a = engine.annotation(id) else { return }
            engine.selectedID = id
            engine.beginInteractiveEdit()   // one undo checkpoint per drag
            move = MoveState(id: id, origStart: a.start, origEnd: a.end, grab: start)
        }
        guard let m = move else { return }
        let dx = current.x - m.grab.x
        let dy = current.y - m.grab.y
        engine.setPosition(id: m.id,
                           start: CGPoint(x: m.origStart.x + dx, y: m.origStart.y + dy),
                           end: CGPoint(x: m.origEnd.x + dx, y: m.origEnd.y + dy))
    }

    private func handleTap(_ location: CGPoint, scale: CGFloat) {
        guard engine.tool == .text else { return }
        let point = imagePoint(location, scale: scale)
        engine.addText(at: point, text: "")
        if let id = engine.annotations.last?.id {
            editingTextID = id
            editingText = ""
            textFocused = true
        }
    }

    private func commitText() {
        if let id = editingTextID, editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            engine.selectedID = id
            engine.deleteSelected()
        }
        editingTextID = nil
        textFocused = false
    }

    private func imagePoint(_ location: CGPoint, scale: CGFloat) -> CGPoint {
        CGPoint(x: location.x / scale, y: location.y / scale)
    }

    private func cropOverlay(crop: CGRect, displaySize: CGSize, scale: CGFloat) -> some View {
        let r = CGRect(x: crop.minX * scale, y: crop.minY * scale,
                       width: crop.width * scale, height: crop.height * scale)
        return Rectangle()
            .fill(Color.black.opacity(0.45))
            .frame(width: displaySize.width, height: displaySize.height)
            .reverseMask {
                Rectangle().frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
            }
            .overlay(
                Rectangle().strokeBorder(VST.Color.accent, lineWidth: 1.5)
                    .frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
            )
            .allowsHitTesting(false)
    }
}

extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask().blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}
