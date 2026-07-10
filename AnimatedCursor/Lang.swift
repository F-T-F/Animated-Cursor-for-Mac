enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case chinese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese: "中文"
        case .english: "English"
        }
    }
}

enum Lang {
    static func appName(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "Animated Cursor"
        case .english: "Animated Cursor"
        }
    }
    static func appSubtitle(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "匯入 GIF，調整大小與熱點，立即預覽自訂 macOS 指針。"
        case .english: "Import a GIF, adjust size and hotspot, and preview your custom macOS cursor."
        }
    }

    static func language(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "語言"
        case .english: "Language"
        }
    }

    static func chooseGIF(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "選擇 GIF"
        case .english: "Choose GIF"
        }
    }

    static func cursorSize(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "指針大小"
        case .english: "Cursor Size"
        }
    }

    static func hotSpot(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "熱點位置"
        case .english: "Hotspot"
        }
    }

    static func enableCustomCursor(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "啟用自訂指針"
        case .english: "Enable Custom Cursor"
        }
    }

    static func hideSystemCursor(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "隱藏系統指針"
        case .english: "Hide System Cursor"
        }
    }

    static func reset(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "重設"
        case .english: "Reset"
        }
    }

    static func quit(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "退出"
        case .english: "Quit"
        }
    }

    static func dropGIFHint(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "拖入 GIF 或點選右側按鈕"
        case .english: "Drop a GIF or use the button on the right"
        }
    }

    static func noGIFSelected(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "尚未選擇 GIF"
        case .english: "No GIF selected"
        }
    }

    static func unableToReadGIF(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "無法讀取這個 GIF"
        case .english: "Unable to read this GIF"
        }
    }

    static func hotSpotTopLeft(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "左上"
        case .english: "Top Left"
        }
    }

    static func hotSpotCenter(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "中央"
        case .english: "Center"
        }
    }

    static func hotSpotBottom(_ language: AppLanguage) -> String {
        switch language {
        case .chinese: "下方"
        case .english: "Bottom"
        }
    }

    static func systemCursorNote(_ language: AppLanguage) -> String {
        switch language {
        case .chinese:
            "提示：若系統游標在部分 App 或安全輸入畫面重新出現，這是 macOS 的保護機制。重新切回此 App 或關閉再啟用即可。"
        case .english:
            "Note: if the system cursor reappears in some apps or secure input screens, that is macOS protection. Switch back to this app or toggle the cursor off and on again."
        }
    }
}
