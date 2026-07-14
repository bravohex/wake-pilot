import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(appState: AppState) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Wake Pilot"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(
            rootView: SettingsView().environmentObject(appState)
        )

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
