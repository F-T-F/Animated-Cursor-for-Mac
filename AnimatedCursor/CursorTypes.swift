import AppKit

enum HotSpotPreset: String, CaseIterable, Identifiable {
    case topLeft
    case center
    case bottomCenter

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .topLeft: Lang.hotSpotTopLeft(language)
        case .center: Lang.hotSpotCenter(language)
        case .bottomCenter: Lang.hotSpotBottom(language)
        }
    }

    func hotSpot(for size: CGFloat) -> CGPoint {
        switch self {
        case .topLeft:
            CGPoint(x: 2, y: size - 2)
        case .center:
            CGPoint(x: size / 2, y: size / 2)
        case .bottomCenter:
            CGPoint(x: size / 2, y: 2)
        }
    }
}

struct CursorFrame {
    let image: NSImage
    let duration: TimeInterval
}
