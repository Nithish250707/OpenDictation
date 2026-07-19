import AppKit
import SwiftUI

/// Owns the floating recorder panel: a borderless, non-activating `NSPanel`
/// that stays above all windows without ever stealing keyboard focus from the
/// app the user is dictating into. SwiftUI cannot create this window style
/// itself, which is why this thin AppKit wrapper exists.
@MainActor
final class FloatingPanelManager {
    private let settings: SettingsStore
    private var panel: NSPanel?
    /// Incremented on every show; a pending hide-completion from before the
    /// latest show must not order the panel out from under a new session.
    private var showGeneration = 0

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func show<Content: View>(@ViewBuilder content: () -> Content) {
        showGeneration += 1
        let panel = self.panel ?? makePanel()
        self.panel = panel
        panel.appearance = Self.appearance(for: settings.panelAppearance)

        let hosting = NSHostingView(rootView: content())
        // Let SwiftUI drive the window size as the popup's state changes.
        hosting.sizingOptions = [.preferredContentSize]
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        position(panel)

        // Enter with a fade plus a short upward slide.
        let target = panel.frame.origin
        panel.setFrameOrigin(NSPoint(x: target.x, y: target.y - 12))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = settings.panelOpacity
            panel.animator().setFrameOrigin(target)
        }
    }

    private static func appearance(for mode: PanelAppearanceMode) -> NSAppearance? {
        switch mode {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }

    func hide() {
        guard let panel, panel.isVisible else { return }
        let generation = showGeneration
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrameOrigin(NSPoint(x: panel.frame.origin.x, y: panel.frame.origin.y - 8))
        }, completionHandler: {
            // AppKit calls the completion on the main thread; the SDK just
            // hasn't annotated it as such.
            MainActor.assumeIsolated { [weak self] in
                // A new session may have re-shown the panel during the fade.
                guard self?.showGeneration == generation else { return }
                panel.orderOut(nil)
            }
        })
    }

    /// Bottom-center of the active screen, like the system dictation HUD.
    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.midX - panel.frame.width / 2,
            y: visible.minY + 140
        )
        panel.setFrameOrigin(origin)
    }

    private func makePanel() -> NSPanel {
        let panel = RecorderPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        return panel
    }
}

/// Refuses key/main status entirely: the user's keyboard focus must stay in
/// the app they were typing in. Mouse clicks still reach the panel's controls.
private final class RecorderPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
