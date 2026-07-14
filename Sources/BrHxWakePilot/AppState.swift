import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import ServiceManagement

@MainActor
final class AppState: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            saveSettings()
            applyState()
        }
    }

    @Published var keepDisplayAwake: Bool {
        didSet {
            saveSettings()
            applyState()
        }
    }

    @Published private(set) var presenceHeartbeatEnabled: Bool {
        didSet {
            saveSettings()
            applyState()
        }
    }

    @Published var intervalMinutes: Int {
        didSet {
            let normalizedInterval = AppConfiguration.normalizedPresenceInterval(intervalMinutes)
            if intervalMinutes != normalizedInterval {
                intervalMinutes = normalizedInterval
                return
            }

            saveSettings()
            applyState()
        }
    }

    @Published var scheduleEnabled: Bool {
        didSet {
            saveSettings()
            refreshScheduleActivity()
        }
    }

    @Published private(set) var scheduleStartMinutes: Int {
        didSet {
            let normalizedMinutes = AppConfiguration.normalizedScheduleMinute(
                scheduleStartMinutes,
                defaultValue: AppConfiguration.defaultScheduleStartMinutes
            )
            if scheduleStartMinutes != normalizedMinutes {
                scheduleStartMinutes = normalizedMinutes
                return
            }

            saveSettings()
            refreshScheduleActivity()
        }
    }

    @Published private(set) var scheduleEndMinutes: Int {
        didSet {
            let normalizedMinutes = AppConfiguration.normalizedScheduleMinute(
                scheduleEndMinutes,
                defaultValue: AppConfiguration.defaultScheduleEndMinutes
            )
            if scheduleEndMinutes != normalizedMinutes {
                scheduleEndMinutes = normalizedMinutes
                return
            }

            saveSettings()
            refreshScheduleActivity()
        }
    }

    @Published var language: AppLanguage {
        didSet {
            saveSettings()
            refreshLaunchAtLoginStatus()
            applyState()
        }
    }

    @Published private(set) var hasAccessibilityPermission: Bool
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var launchAtLoginStatus: String
    @Published private(set) var launchAtLoginNeedsApproval: Bool
    @Published private(set) var lastHeartbeatAt: Date?
    @Published private(set) var isWithinScheduledTime: Bool
    @Published var errorMessage: String?

    private let preferences: AppPreferences
    private let runtimeController: any RuntimeControlling
    private let now: () -> Date
    private let schedulesTransitions: Bool
    private var scheduleTransitionTimer: Timer?
    private var settingsWindowController: SettingsWindowController?
    private var hasFinishedInitialization = false

    convenience init() {
        self.init(
            preferences: AppPreferences.forCurrentApp(),
            runtimeController: RuntimeController(),
            now: Date.init
        )
    }

    init(
        preferences: AppPreferences,
        runtimeController: any RuntimeControlling,
        now: @escaping () -> Date = Date.init,
        schedulesTransitions: Bool = true
    ) {
        self.preferences = preferences
        self.runtimeController = runtimeController
        self.now = now
        self.schedulesTransitions = schedulesTransitions
        let settings = preferences.load()

        isEnabled = settings.isEnabled
        keepDisplayAwake = settings.keepDisplayAwake
        presenceHeartbeatEnabled = settings.presenceHeartbeatEnabled
        intervalMinutes = settings.intervalMinutes
        scheduleEnabled = settings.scheduleEnabled
        scheduleStartMinutes = settings.scheduleStartMinutes
        scheduleEndMinutes = settings.scheduleEndMinutes
        language = settings.language
        isWithinScheduledTime = ActivitySchedule(
            isEnabled: settings.scheduleEnabled,
            startMinutes: settings.scheduleStartMinutes,
            endMinutes: settings.scheduleEndMinutes
        ).isActive(at: now())

        hasAccessibilityPermission = AccessibilityController.isTrusted(prompt: false)

        let loginState = LoginItemController.currentState()
        launchAtLogin = loginState.isRequested
        launchAtLoginStatus = loginState.description(language: settings.language)
        launchAtLoginNeedsApproval = loginState.requiresApproval

        hasFinishedInitialization = true
        applyState()
        scheduleNextTransition()
    }

    deinit {
        scheduleTransitionTimer?.invalidate()
    }

    var menuBarSymbol: String {
        if !isEnabled {
            return "pause.circle"
        }
        if !isWithinScheduledTime {
            return "clock"
        }
        if presenceHeartbeatEnabled && !hasAccessibilityPermission {
            return "exclamationmark.triangle"
        }
        return "bolt.circle.fill"
    }

    var statusText: String {
        if !isEnabled {
            return localized(.paused)
        }
        if !isWithinScheduledTime {
            return localized(.outsideScheduledTime)
        }
        if presenceHeartbeatEnabled && !hasAccessibilityPermission {
            return localized(.accessibilityRequired)
        }
        return localized(.active)
    }

    var statusDetail: String {
        if !isEnabled {
            return localized(.sleepMayResume)
        }
        if !isWithinScheduledTime {
            return localized(.resumesAt, scheduleTimeText(scheduleStartMinutes))
        }
        if presenceHeartbeatEnabled && !hasAccessibilityPermission {
            return localized(.heartbeatUnavailable)
        }
        if presenceHeartbeatEnabled {
            return localized(.heartbeatActive)
        }
        return localized(.powerAssertionActive)
    }

    var scheduleDescription: String {
        guard scheduleEnabled else {
            return localized(.alwaysActive)
        }

        guard scheduleStartMinutes != scheduleEndMinutes else {
            return localized(.allDay)
        }

        return "\(scheduleTimeText(scheduleStartMinutes))–\(scheduleTimeText(scheduleEndMinutes))"
    }

    var scheduleStartTime: Date {
        scheduleDate(for: scheduleStartMinutes)
    }

    var scheduleEndTime: Date {
        scheduleDate(for: scheduleEndMinutes)
    }

    func localized(_ key: AppStrings.Key) -> String {
        AppStrings.text(key, language: language)
    }

    func localized(_ key: AppStrings.Key, _ arguments: CVarArg...) -> String {
        AppStrings.format(key, language: language, arguments: arguments)
    }

    func localizedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    func setPresenceHeartbeatEnabled(_ enabled: Bool) {
        presenceHeartbeatEnabled = enabled

        if enabled && !hasAccessibilityPermission {
            requestAccessibilityPermission()
        }
    }

    func setScheduleStartTime(_ date: Date) {
        scheduleStartMinutes = scheduleMinutes(from: date)
    }

    func setScheduleEndTime(_ date: Date) {
        scheduleEndMinutes = scheduleMinutes(from: date)
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
            updateLoginItemState(LoginItemController.currentState())
            errorMessage = nil
        } catch {
            updateLoginItemState(LoginItemController.currentState())
            errorMessage = localized(.cannotUpdateLoginItem, error.localizedDescription)
        }
    }

    func refreshLaunchAtLoginStatus() {
        updateLoginItemState(LoginItemController.currentState())
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
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(appState: self)
        }

        settingsWindowController?.show()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func saveSettings() {
        preferences.save(
            AppSettings(
                isEnabled: isEnabled,
                keepDisplayAwake: keepDisplayAwake,
                presenceHeartbeatEnabled: presenceHeartbeatEnabled,
                intervalMinutes: intervalMinutes,
                scheduleEnabled: scheduleEnabled,
                scheduleStartMinutes: scheduleStartMinutes,
                scheduleEndMinutes: scheduleEndMinutes,
                language: language
            )
        )
    }

    private func applyState() {
        guard hasFinishedInitialization else {
            return
        }

        errorMessage = runtimeController.apply(
            configuration: RuntimeConfiguration(
                isEnabled: isEnabled && isWithinScheduledTime,
                keepDisplayAwake: keepDisplayAwake,
                presenceHeartbeatEnabled: presenceHeartbeatEnabled,
                intervalMinutes: intervalMinutes,
                hasAccessibilityPermission: hasAccessibilityPermission,
                language: language
            )
        ) { [weak self] in
            self?.emitPresenceHeartbeat()
        }
    }

    private var activitySchedule: ActivitySchedule {
        ActivitySchedule(
            isEnabled: scheduleEnabled,
            startMinutes: scheduleStartMinutes,
            endMinutes: scheduleEndMinutes
        )
    }

    private func refreshScheduleActivity() {
        let isActive = activitySchedule.isActive(at: now())
        let hasChanged = isWithinScheduledTime != isActive
        isWithinScheduledTime = isActive
        scheduleNextTransition()

        if hasFinishedInitialization && hasChanged {
            applyState()
        }
    }

    private func scheduleNextTransition() {
        scheduleTransitionTimer?.invalidate()
        scheduleTransitionTimer = nil

        guard
            schedulesTransitions,
            let transitionDate = activitySchedule.nextTransition(after: now())
        else {
            return
        }

        let timer = Timer(
            fire: transitionDate,
            interval: 0,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshScheduleActivity()
            }
        }
        timer.tolerance = 1
        scheduleTransitionTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func scheduleDate(for minutes: Int) -> Date {
        Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Calendar.current.startOfDay(for: now())
        ) ?? now()
    }

    private func scheduleMinutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func scheduleTimeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private func updateLoginItemState(_ state: LoginItemController.State) {
        launchAtLogin = state.isRequested
        launchAtLoginStatus = state.description(language: language)
        launchAtLoginNeedsApproval = state.requiresApproval
    }

    private func emitPresenceHeartbeat() {
        guard AccessibilityController.postPresenceHeartbeat() else {
            errorMessage = localized(.cannotCreateHeartbeat)
            refreshAccessibilityStatus()
            return
        }

        lastHeartbeatAt = Date()
        errorMessage = nil
    }
}
