//
//  DoodleCanvasView.swift
//  Evil Banana
//
//  Simple raster drawing canvas with brush/eraser and undo/redo.
//

import SwiftUI
import AppKit

struct DoodleStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool
}

final class DoodleCanvasState: ObservableObject {
    @Published var strokes: [DoodleStroke] = []
    @Published var undone: [DoodleStroke] = []
    @Published var brushColor: Color = .white
    @Published var brushWidth: CGFloat = 8
    @Published var isEraser: Bool = false

    func beginStroke(at point: CGPoint) {
        undone.removeAll()
        let stroke = DoodleStroke(points: [point], color: brushColor, lineWidth: brushWidth, isEraser: isEraser)
        strokes.append(stroke)
    }

    func continueStroke(to point: CGPoint) {
        guard !strokes.isEmpty else { return }
        strokes[strokes.count - 1].points.append(point)
    }

    func endStroke() {}

    func undo() {
        guard let last = strokes.popLast() else { return }
        undone.append(last)
    }

    func redo() {
        guard let last = undone.popLast() else { return }
        strokes.append(last)
    }

    func clear() {
        strokes.removeAll()
        undone.removeAll()
    }

    func rasterizeOverlay(size: CGSize, scale: CGFloat = 1.0) -> NSImage? {
        guard size.width > 0 && size.height > 0 else { return nil }
        let pixelSize = NSSize(width: size.width * scale, height: size.height * scale)
        let image = NSImage(size: pixelSize)
        image.lockFocusFlipped(false)
        NSGraphicsContext.current?.cgContext.setAllowsAntialiasing(true)
        NSGraphicsContext.current?.cgContext.setShouldAntialias(true)

        for stroke in strokes {
            let cg = NSGraphicsContext.current!.cgContext
            cg.setLineWidth(stroke.lineWidth)
            if stroke.isEraser {
                cg.setBlendMode(.clear)
            } else {
                cg.setBlendMode(.normal)
                cg.setStrokeColor(NSColor(stroke.color).cgColor)
            }
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            if let first = stroke.points.first {
                cg.beginPath()
                let firstConv = CGPoint(x: first.x * scale, y: (size.height - first.y) * scale)
                cg.move(to: firstConv)
                for p in stroke.points.dropFirst() {
                    let conv = CGPoint(x: p.x * scale, y: (size.height - p.y) * scale)
                    cg.addLine(to: conv)
                }
                cg.strokePath()
            }
        }

        image.unlockFocus()
        return image
    }
}

struct DoodleCanvasView: View {
    @ObservedObject var state: DoodleCanvasState

    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Color.clear
                ForEach(state.strokes) { stroke in
                    Path { path in
                        guard let first = stroke.points.first else { return }
                        path.move(to: first)
                        for p in stroke.points.dropFirst() { path.addLine(to: p) }
                    }
                    .stroke(stroke.isEraser ? Color.clear : stroke.color, lineWidth: stroke.lineWidth)
                    .blendMode(stroke.isEraser ? .destinationOut : .normal)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = value.location
                        if !isDragging {
                            isDragging = true
                            state.beginStroke(at: point)
                        } else {
                            state.continueStroke(to: point)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        state.endStroke()
                    }
            )
        }
    }
}


