import AppKit

final class SelectionOverlayController {
    private var windows: [SelectionWindow] = []
    private var completion: ((CGRect?) -> Void)?
    private(set) var isActive = false

    func present(completion: @escaping (CGRect?) -> Void) {
        if isActive {
            cancel()
        }
        self.completion = completion
        isActive = true

        for screen in NSScreen.screens {
            let window = SelectionWindow(screen: screen)
            window.selectionView.onFinish = { [weak self] rect in
                self?.finish(rect)
            }
            window.selectionView.onCancel = { [weak self] in
                self?.cancel()
            }
            windows.append(window)
        }

        NSApp.activate(ignoringOtherApps: true)
        for window in windows {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.selectionView)
        }
    }

    func cancel() {
        guard isActive else { return }
        isActive = false
        let callback = completion
        completion = nil
        closeWindows()
        callback?(nil)
    }

    private func finish(_ rect: CGRect) {
        guard isActive else { return }
        isActive = false
        let callback = completion
        completion = nil
        closeWindows()
        callback?(rect)
    }

    private func closeWindows() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        NSCursor.arrow.set()
    }
}

final class SelectionWindow: NSWindow {
    let selectionView: SelectionView

    init(screen: NSScreen) {
        let view = SelectionView(frame: CGRect(origin: .zero, size: screen.frame.size))
        selectionView = view
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class SelectionView: NSView {
    var onFinish: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var tracking = false

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let dim = NSBezierPath(rect: bounds)
        if let selection = selectionRect, selection.width > 0, selection.height > 0 {
            dim.append(NSBezierPath(rect: selection))
        }
        dim.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.38).setFill()
        dim.fill()

        guard let selection = selectionRect, selection.width > 1, selection.height > 1 else {
            drawHint()
            return
        }

        NSColor.systemYellow.withAlphaComponent(0.95).setStroke()
        let border = NSBezierPath(rect: selection)
        border.lineWidth = 1.5
        border.stroke()

        let label = "\(Int(selection.width)) × \(Int(selection.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = (label as NSString).size(withAttributes: attributes)
        let labelRect = CGRect(
            x: selection.minX,
            y: max(selection.minY - size.height - 8, bounds.minY + 4),
            width: size.width + 10,
            height: size.height + 4
        )
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4).fill()
        (label as NSString).draw(at: CGPoint(x: labelRect.minX + 5, y: labelRect.minY + 2), withAttributes: attributes)
    }

    private func drawHint() {
        let text = "Drag to capture  ·  Esc to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let rect = CGRect(
            x: bounds.midX - size.width / 2 - 16,
            y: bounds.midY - size.height / 2 - 10,
            width: size.width + 32,
            height: size.height + 20
        )
        NSColor.black.withAlphaComponent(0.65).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10).fill()
        (text as NSString).draw(
            at: CGPoint(x: rect.minX + 16, y: rect.minY + 10),
            withAttributes: attributes
        )
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = clamp(convert(event.locationInWindow, from: nil))
        startPoint = point
        currentPoint = point
        tracking = true
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard tracking else { return }
        currentPoint = clamp(convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard tracking else { return }
        tracking = false
        currentPoint = clamp(convert(event.locationInWindow, from: nil))

        guard let rect = selectionRect, rect.width >= 4, rect.height >= 4 else {
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
            return
        }

        guard let screenRect = window?.convertToScreen(rect) else {
            onCancel?()
            return
        }
        onFinish?(screenRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }

    private var selectionRect: CGRect? {
        guard let start = startPoint, let current = currentPoint else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, bounds.minX), bounds.maxX),
            y: min(max(point.y, bounds.minY), bounds.maxY)
        )
    }
}
