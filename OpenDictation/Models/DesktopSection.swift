import Foundation

/// Top-level sections of the desktop management window's sidebar.
enum DesktopSection: String, CaseIterable, Identifiable, Hashable {
    case home
    case history
    case aiProfiles
    case dictionary
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .history: "History"
        case .aiProfiles: "AI Profiles"
        case .dictionary: "Dictionary"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .history: "clock.arrow.circlepath"
        case .aiProfiles: "sparkles"
        case .dictionary: "character.book.closed"
        case .settings: "gearshape"
        }
    }
}
