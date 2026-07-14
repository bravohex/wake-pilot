import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import ServiceManagement

@MainActor
final class AppState: ObservableObject {
    private enum Key {
        static let isEnabled = "stayActive.isEnabled"
        static let keepDisplayAwake = "stayActive.keepDisplayAwake"
        static let simulateActivity = "stayActive.simulateActivity"
        static let intervalMinutes = "stayActive.intervalMinutes"
    }

    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Key.isEnabled)
            applyState()
        }
    }

    @Published var keepDisplayAwake: Bool {
        didSet {
            defaults.set(keepDisplayAwake, forKey: Key.keepDisplayAwake)
            applyState()
        }
    }

    @Published private(set) var simulateActivity: Bool {
        didSet {
            defaults.set(simulateActivity, forKey: Key.simulateActivity)
            applyState()
        }
    }

    @Published var intervalMinutes: Int {
        didSet {
            defaults.set(intervalMinutes, forKey: Key.intervalMinutes)
            applyState()
        }
    }

    @Published private(set) var hasAccessibilityPermission: Bool
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var launchAtLoginStatus: String
    @Published private(set) var lastHeartbeatAt: Date?
    @Published var errorMessage: String?

    private let defaults = UserDefaults.standard
    private let powerController = PowerAssertionController()
    private let activityController = ActivityController()
    private var hasFinishedInitialization = false

    init() {
        defaults.register(defaults: [
            Key.isEnabled: true,
            Key.keepDisplayAwake: false,
            Key.simulateActivity: true,
            Key.intervalMinutes: AppConfiguration.defaultPresenceIntervalMinutes
        ])

        isEnabled = defaults.bool(forKey: Key.isEnabled)
        keepDisplayAwake = defaults.bool(forKey: Key.keepDisplayAwake)
        simulateActivity = defaults.bool(forKey: Key.simulateActivity)
        let storedInterval = defaults.integer(forKey: Key.intervalMinutes)
        let normalizedInterval = AppConfiguration.normalizedPresenceInterval(storedInterval)
        intervalMinutes = normalizedInterval
        if storedInterval != normalizedInterval {
            defaults.set(normalizedInterval, forKey: Key.intervalMinutes)
        }

        hasAccessibilityPermission = AccessibilityController.isTrusted(prompt: false)

        let loginState = LoginItemController.currentState()
        launchAtLogin = loginState.isRequested
        launchAtLoginStatus = loginState.description

        hasFinishedInitialization = true
        applyState()
    }

    var menuBarSymbol: String {
        if !isEnabled {
            return "pause.circle"
        }
        if simulateActivity && !hasAccessibilityPermission {
            return "exclamationmark.triangle"
        }
        return "bolt.circle.fill"
    }

    var statusText: String {
        if !isEnabled {
            return "Đang tạm dừng"
        }
        if simulateActivity && !hasAccessibilityPermission {
            return "Cần cấp quyền Accessibility"
        }
        return "Đang hoạt động"
    }

    var statusDetail: String {
        if !isEnabled {
            return "Mac có thể sleep theo cài đặt hệ thống."
        }
        if simulateActivity && !hasAccessibilityPermission {
            return "Chống sleep đang bật, nhưng nhịp presence chưa hoạt động."
        }
        if simulateActivity {
            return "Chống sleep và nhịp presence đang hoạt động."
        }
        return "Đang chống system sleep."
    }

    func setSimulateActivity(_ enabled: Bool) {
        simulateActivity = enabled

        if enabled && !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }

    func requestAccessibilityPermission() {
        hasAccessibilityPermission = AccessibilityController.isTrusted(prompt: true)
        applyState()

        // The permission can be granted while the app remains open.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshAccessibilityStatus()
        }
    }

    func refreshAccessibilityStatus() {
        let trusted = AccessibilityController.isTrusted(prompt: false)
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
            applyState()
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemController.setEnabled(enabled)
            let state = LoginItemController.currentState()
            launchAtLogin = enabled
            launchAtLoginStatus = state.description
            errorMessage = nil
        } catch {
            let state = LoginItemController.currentState()
            launchAtLogin = state.isRequested
            launchAtLoginStatus = state.description
            errorMessage = "Không thể cập nhật Launch at Login: \(error.localizedDescription)"
        }
    }

    func refreshLaunchAtLoginStatus() {
        let state = LoginItemController.currentState()
        launchAtLogin = state.isRequested
        launchAtLoginStatus = state.description
    }

    func openLoginItemsSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openAccessibilitySettings() {
        requestAccessibilityPermission()
    }

    func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if !NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        ) {
            _ = NSApp.sendAction(
                Selector(("showPreferencesWindow:")),
                to: nil,
                from: nil
            )
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func applyState() {
        guard hasFinishedInitialization else {
            return
        }

        errorMessage = powerController.update(
            isEnabled: isEnabled,
            keepDisplayAwake: keepDisplayAwake
        )

        guard isEnabled, simulateActivity, hasAccessibilityPermission else {
            activityController.stop()
            return
        }

        activityController.start(intervalMinutes: intervalMinutes) { [weak self] in
            self?.emitPresenceHeartbeat()
        }
    }

    private func emitPresenceHeartbeat() {
        guard AccessibilityController.postHarmlessShiftEvent() else {
            errorMessage = "Không thể tạo presence heartbeat."
            refreshAccessibilityStatus()
            return
        }

        lastHeartbeatAt = Date()
        errorMessage = nil
    }
}
