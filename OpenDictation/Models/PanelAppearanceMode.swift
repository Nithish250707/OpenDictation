import Foundation

/// User-selectable appearance of the floating recorder panel.
/// The mapping to `NSAppearance` lives in `FloatingPanelManager` so models
/// stay free of AppKit.
enum PanelAppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Match System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}
