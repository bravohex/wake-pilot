import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    private var presenceBinding: Binding<Bool> {
        Binding(
            get: { state.presenceHeartbeatEnabled },
            set: { state.setPresenceHeartbeatEnabled($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { state.launchAtLogin },
            set: { state.setLaunchAtLogin($0) }
        )
    }

    private var scheduleStartBinding: Binding<Date> {
        Binding(
            get: { state.scheduleStartTime },
            set: { state.setScheduleStartTime($0) }
        )
    }

    private var scheduleEndBinding: Binding<Date> {
        Binding(
            get: { state.scheduleEndTime },
            set: { state.setScheduleEndTime($0) }
        )
    }

    var body: some View {
        Form {
            Section(state.localized(.languageSection)) {
                Picker(state.localized(.languageSection), selection: $state.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeName)
                            .tag(language)
                    }
                }
            }

            Section(state.localized(.activitySection)) {
                Toggle(state.localized(.enableWakePilot), isOn: $state.isEnabled)

                Toggle(
                    state.localized(.keepDisplayAwake),
                    isOn: $state.keepDisplayAwake
                )
                .disabled(!state.isEnabled)

                Toggle(
                    state.localized(.keepChatActive),
                    isOn: presenceBinding
                )
                .disabled(!state.isEnabled)

                Picker(state.localized(.presenceInterval), selection: $state.intervalMinutes) {
                    ForEach(AppConfiguration.presenceIntervalOptions, id: \.self) { minutes in
                        Text(state.localized(.minutes, minutes))
                            .tag(minutes)
                    }
                }
                .disabled(!state.isEnabled || !state.presenceHeartbeatEnabled)
            }

            Section(state.localized(.scheduleSection)) {
                Toggle(
                    state.localized(.scheduleEnabled),
                    isOn: $state.scheduleEnabled
                )

                if state.scheduleEnabled {
                    DatePicker(
                        state.localized(.scheduleStart),
                        selection: scheduleStartBinding,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        state.localized(.scheduleEnd),
                        selection: scheduleEndBinding,
                        displayedComponents: .hourAndMinute
                    )

                    Text(state.localized(.scheduleCurrent, state.scheduleDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text(state.localized(.scheduleAlwaysOn))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(state.localized(.systemPermissionsSection)) {
                LabeledContent(state.localized(.accessibility)) {
                    HStack(spacing: 8) {
                        Text(
                            state.hasAccessibilityPermission
                                ? state.localized(.permissionGranted)
                                : state.localized(.permissionNotGranted)
                        )
                        .foregroundStyle(
                            state.hasAccessibilityPermission
                                ? Color.secondary
                                : Color.orange
                        )

                        if !state.hasAccessibilityPermission {
                            Button(state.localized(.grantPermission)) {
                                state.openAccessibilitySettings()
                            }
                        }
                    }
                }

                Text(state.localized(.presenceExplanation))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section(state.localized(.startupSection)) {
                Toggle(
                    state.localized(.launchAtLogin),
                    isOn: launchAtLoginBinding
                )

                LabeledContent(state.localized(.status)) {
                    Text(state.launchAtLoginStatus)
                        .foregroundStyle(.secondary)
                }

                if state.launchAtLoginNeedsApproval {
                    Button(state.localized(.openLoginItemsSettings)) {
                        state.openLoginItemsSettings()
                    }
                }
            }

            Section(state.localized(.notesSection)) {
                Text(state.localized(.notesExplanation))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let error = state.errorMessage {
                Section(state.localized(.errorsSection)) {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Text(state.localized(.appVersion, AppConfiguration.versionLabel))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 600)
        .onAppear {
            state.refreshAccessibilityStatus()
            state.refreshLaunchAtLoginStatus()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            state.refreshAccessibilityStatus()
            state.refreshLaunchAtLoginStatus()
        }
    }
}
