import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let cursorModel = CursorModel()
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupSettingsWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursorModel.stopCursor()
    }

    private func setupStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.motionlines", accessibilityDescription: Lang.appName(cursorModel.language))
            button.action = #selector(toggleSettingsWindow)
            button.target = self
        }

        self.statusItem = statusItem
    }

    private func setupSettingsWindow() {
        let hostingController = NSHostingController(
            rootView: ContentView()
                .environmentObject(cursorModel)
                .frame(minWidth: 760, minHeight: 520)
        )

        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 760, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = Lang.appName(cursorModel.language)
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.center()

        settingsWindow = window
    }

    @objc
    private func toggleSettingsWindow() {
        guard let settingsWindow else { return }

        if settingsWindow.isVisible, settingsWindow.isKeyWindow {
            settingsWindow.orderOut(nil)
            return
        }

        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
