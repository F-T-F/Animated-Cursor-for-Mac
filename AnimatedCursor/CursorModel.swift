import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class CursorModel: ObservableObject {
    @Published var frames: [CursorFrame] = []
    @Published var frameIndex = 0
    @Published var cursorSize: CGFloat = 72 {
        didSet {
            overlayController.cursorSize = cursorSize
            guard !isRestoringState else { return }
            saveSettings()
        }
    }
    @Published var hotSpotPreset: HotSpotPreset = .topLeft {
        didSet {
            overlayController.hotSpot = hotSpotPreset.hotSpot(for: cursorSize)
            guard !isRestoringState else { return }
            saveSettings()
        }
    }
    @Published var isCursorEnabled = false {
        didSet {
            guard !isRestoringState else { return }
            updateCursorState()
            saveSettings()
        }
    }
    @Published var shouldHideSystemCursor = false {
        didSet {
            overlayController.shouldHideSystemCursor = shouldHideSystemCursor
            guard !isRestoringState else { return }
            saveSettings()
        }
    }
    @Published var language: AppLanguage = .english {
        didSet {
            guard !isRestoringState else { return }
            saveSettings()
        }
    }
    @Published var loadedFileName: String?
    @Published var hasReadError = false

    private let overlayController = CursorOverlayController()
    private var previewTimer: Timer?
    private var isRestoringState = false
    private let settingsStore = UserDefaults.standard

    private var supportDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return baseURL.appendingPathComponent("AC Cursor", isDirectory: true)
    }

    private var savedGIFURL: URL {
        supportDirectoryURL.appendingPathComponent("Cursor.gif")
    }

    var currentImage: NSImage? {
        guard frames.indices.contains(frameIndex) else { return nil }
        return frames[frameIndex].image
    }

    var statusText: String {
        if hasReadError {
            return Lang.unableToReadGIF(language)
        }

        if let loadedFileName {
            return "\(loadedFileName) · \(frames.count) frames"
        }

        return Lang.noGIFSelected(language)
    }

    init() {
        restoreSettings()
        overlayController.cursorSize = cursorSize
        overlayController.hotSpot = hotSpotPreset.hotSpot(for: cursorSize)
        overlayController.shouldHideSystemCursor = shouldHideSystemCursor
        restoreSavedGIF()
    }

    func pickGIF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            loadGIF(from: url, persist: true)
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.gif.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.gif.identifier, options: nil) { [weak self] item, _ in
            guard let self else { return }

            let url = item as? URL
            Task { @MainActor in
                if let url {
                    self.loadGIF(from: url, persist: true)
                }
            }
        }

        return true
    }

    func reset() {
        isCursorEnabled = false
        frames = []
        frameIndex = 0
        loadedFileName = nil
        hasReadError = false
        previewTimer?.invalidate()
        previewTimer = nil
        try? FileManager.default.removeItem(at: savedGIFURL)
        saveSettings()
    }

    func stopCursor() {
        overlayController.stop()
    }

    private func loadGIF(from url: URL, persist: Bool) {
        do {
            let decodedFrames = try GIFDecoder.decode(url: url)
            guard !decodedFrames.isEmpty else {
                throw GIFDecoder.DecoderError.emptyImage
            }

            if persist {
                try saveGIFCopy(from: url)
            }

            frames = decodedFrames
            frameIndex = 0
            loadedFileName = url.lastPathComponent
            hasReadError = false
            overlayController.frames = decodedFrames
            restartPreviewTimer()
            saveSettings()

            if isCursorEnabled {
                overlayController.start()
            }
        } catch {
            isCursorEnabled = false
            hasReadError = true
            overlayController.frames = []
        }
    }

    private func restoreSettings() {
        isRestoringState = true
        defer { isRestoringState = false }

        if let languageRawValue = settingsStore.string(forKey: SettingsKey.language),
           let savedLanguage = AppLanguage(rawValue: languageRawValue) {
            language = savedLanguage
        }

        if let hotSpotRawValue = settingsStore.string(forKey: SettingsKey.hotSpotPreset),
           let savedHotSpot = HotSpotPreset(rawValue: hotSpotRawValue) {
            hotSpotPreset = savedHotSpot
        }

        let savedSize = settingsStore.double(forKey: SettingsKey.cursorSize)
        if savedSize > 0 {
            cursorSize = savedSize
        }

        isCursorEnabled = settingsStore.bool(forKey: SettingsKey.isCursorEnabled)
        shouldHideSystemCursor = settingsStore.bool(forKey: SettingsKey.shouldHideSystemCursor)
        loadedFileName = settingsStore.string(forKey: SettingsKey.loadedFileName)
    }

    private func restoreSavedGIF() {
        guard FileManager.default.fileExists(atPath: savedGIFURL.path) else {
            if isCursorEnabled {
                isCursorEnabled = false
            }
            return
        }

        loadGIF(from: savedGIFURL, persist: false)
    }

    private func saveSettings() {
        guard !isRestoringState else { return }

        settingsStore.set(cursorSize, forKey: SettingsKey.cursorSize)
        settingsStore.set(hotSpotPreset.rawValue, forKey: SettingsKey.hotSpotPreset)
        settingsStore.set(isCursorEnabled, forKey: SettingsKey.isCursorEnabled)
        settingsStore.set(shouldHideSystemCursor, forKey: SettingsKey.shouldHideSystemCursor)
        settingsStore.set(language.rawValue, forKey: SettingsKey.language)
        settingsStore.set(loadedFileName, forKey: SettingsKey.loadedFileName)
    }

    private func saveGIFCopy(from url: URL) throws {
        try FileManager.default.createDirectory(at: supportDirectoryURL, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: savedGIFURL.path) {
            try FileManager.default.removeItem(at: savedGIFURL)
        }

        try FileManager.default.copyItem(at: url, to: savedGIFURL)
    }

    private func restartPreviewTimer() {
        previewTimer?.invalidate()
        scheduleNextPreviewFrame()
    }

    private func scheduleNextPreviewFrame() {
        guard !frames.isEmpty else { return }

        let duration = frames[frameIndex].duration
        previewTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor [weak self] in
                guard let self, !self.frames.isEmpty else { return }
                self.frameIndex = (self.frameIndex + 1) % self.frames.count
                self.scheduleNextPreviewFrame()
            }
        }
    }

    private func updateCursorState() {
        guard !frames.isEmpty else {
            overlayController.stop()
            if isCursorEnabled {
                isCursorEnabled = false
            }
            return
        }

        if isCursorEnabled {
            overlayController.frames = frames
            overlayController.cursorSize = cursorSize
            overlayController.hotSpot = hotSpotPreset.hotSpot(for: cursorSize)
            overlayController.shouldHideSystemCursor = shouldHideSystemCursor
            overlayController.start()
        } else {
            overlayController.stop()
        }
    }
}

private enum SettingsKey {
    static let cursorSize = "cursorSize"
    static let hotSpotPreset = "hotSpotPreset"
    static let isCursorEnabled = "isCursorEnabled"
    static let shouldHideSystemCursor = "shouldHideSystemCursor"
    static let language = "language"
    static let loadedFileName = "loadedFileName"
}
