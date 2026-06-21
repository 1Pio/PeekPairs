import AppKit
import SwiftUI

struct WindowDragSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> DragSurfaceView {
        DragSurfaceView()
    }

    func updateNSView(_ nsView: DragSurfaceView, context: Context) {}
}

final class DragSurfaceView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
