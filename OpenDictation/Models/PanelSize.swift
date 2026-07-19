import Foundation

/// User-selectable size of the floating recorder panel.
enum PanelSize: String, Codable, CaseIterable, Identifiable {
    case compact
    case standard
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: "Compact"
        case .standard: "Standard"
        case .large: "Large"
        }
    }

    /// Width of the popup card in points.
    var width: CGFloat {
        switch self {
        case .compact: 300
        case .standard: 340
        case .large: 410
        }
    }
}
