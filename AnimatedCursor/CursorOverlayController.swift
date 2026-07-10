import AppKit

@MainActor
final class CursorOverlayController {
    var frames: [CursorFrame] = []
    var cursorSize: CGFloat = 72 {
        didSet { updateWindowSize() }
    }
    var hotSpot = CGPoint(x: 2, y: 70)
    var shouldHideSystemCursor = true {
        didSet { updateSystemCursorVisibility() }
    }

    private var window: NSWindow?
    private var imageView: NSImageView?
    private var frameIndex = 0
    private var animationTimer: Timer?
    private var trackingTimer: Timer?
    private var eventMonitors: [Any] = []
    private var isSystemCursorHidden = false
    private var lastWindowOrigin: CGPoint?

    func start() {
        guard !frames.isEmpty else { return }

        setupWindowIfNeeded()
        window?.orderFrontRegardless()
        updateSystemCursorVisibility()
        startTracking()
        showFrame(at: 0)
    }

    func stop() {
        animationTimer?.invalidate()
        trackingTimer?.invalidate()
        animationTimer = nil
        trackingTimer = nil
        eventMonitors.forEach { NSEvent.removeMonitor($0) }
        eventMonitors = []
        lastWindowOrigin = nil
        window?.orderOut(nil)
        showSystemCursor()
    }

    private func setupWindowIfNeeded() {
        guard window == nil else {
            updateWindowSize()
            return
        }

        let imageView = NSImageView(frame: CGRect(origin: .zero, size: CGSize(width: cursorSize, height: cursorSize)))
        imageView.imageScaling = .scaleProportionallyUpOrDown

        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: CGSize(width: cursorSize, height: cursorSize)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.level = .screenSaver
        window.animationBehavior = .none
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = imageView

        self.imageView = imageView
        self.window = window
    }

    private func updateWindowSize() {
        imageView?.frame = CGRect(origin: .zero, size: CGSize(width: cursorSize, height: cursorSize))
        window?.setContentSize(CGSize(width: cursorSize, height: cursorSize))
        moveToCurrentMouseLocation()
    }

    private func startTracking() {
        trackingTimer?.invalidate()
        eventMonitors.forEach { NSEvent.removeMonitor($0) }
        eventMonitors = []

        let trackedEvents: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .otherMouseDragged
        ]

        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: trackedEvents) { [weak self] event in
            self?.moveToCurrentMouseLocation()
            return event
        }

        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: trackedEvents) { _ in
            Task { @MainActor [weak self] in
                self?.moveToCurrentMouseLocation()
            }
        }

        if let localMonitor {
            eventMonitors.append(localMonitor)
        }
        if let globalMonitor {
            eventMonitors.append(globalMonitor)
        }

        let timer = Timer(timeInterval: 1.0 / 240.0, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.moveToCurrentMouseLocation()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
        moveToCurrentMouseLocation()
    }

    private func showFrame(at index: Int) {
        guard frames.indices.contains(index) else { return }

        frameIndex = index
        imageView?.image = frames[index].image
        animationTimer?.invalidate()
        let timer = Timer(timeInterval: frames[index].duration, repeats: false) { _ in
            Task { @MainActor [weak self] in
                guard let self, !self.frames.isEmpty else { return }
                self.showFrame(at: (self.frameIndex + 1) % self.frames.count)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private func moveToCurrentMouseLocation() {
        guard let window else { return }

        let mouse = NSEvent.mouseLocation
        let origin = CGPoint(
            x: mouse.x - hotSpot.x,
            y: mouse.y - hotSpot.y
        )

        guard origin != lastWindowOrigin else { return }
        lastWindowOrigin = origin
        window.setFrameOrigin(origin)
    }

    private func hideSystemCursor() {
        guard !isSystemCursorHidden else { return }
        NSCursor.hide()
        isSystemCursorHidden = true
    }

    private func showSystemCursor() {
        guard isSystemCursorHidden else { return }
        NSCursor.unhide()
        isSystemCursorHidden = false
    }

    private func updateSystemCursorVisibility() {
        if shouldHideSystemCursor {
            hideSystemCursor()
        } else {
            showSystemCursor()
        }
    }
}
