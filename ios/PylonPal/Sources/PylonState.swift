import SwiftUI

enum PylonState: UInt8, CaseIterable {
    case idle = 0, approaching = 1, standAside = 2, boardingOK = 3
    var next: PylonState { PylonState(rawValue: (rawValue + 1) % 4)! }
}

enum Language: String, CaseIterable, Identifiable {
    case en, es, zh, fr
    var id: String { rawValue }
    var label: String { ["en": "English", "es": "Español", "zh": "中文", "fr": "Français"][rawValue]! }
}

enum Settings {
    static let language = "language"
    static let manualMode = "manualMode"
    static let boardingDelay = "boardingDelay"
    static let returnDelay = "returnDelay"
    static let lineColorHex = "lineColorHex"
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}
