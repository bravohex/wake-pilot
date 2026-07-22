import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var state: AppState

    private var presenceBinding: Binding<Bool> {
        Binding(
            get: { state.presenceHeartbeatEnabled },
            set: { state.setPresenceHeartbeatEnabled($0) }
        )
    }

    private var statusColor: Color {
        if !state.isEnabled {
            return .secondary
        }
        if !state.isWithinScheduledTime {
            return .secondary
        }
        if state.presenceHeartbeatEnabled && !state.hasAccessibilityPermission {
            return .orange
        }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            statusSummary

            Divider()

            activityControls

            if state.presenceHeartbeatEnabled {
                accessibilityStatus
            }

            if let heartbeat = state.lastHeartbeatAt {
                HStack {
                    Text(state.localized(.lastPresence))
                    Spacer()
                    Text(state.localizedTime(heartbeat))
                    .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let error = state.errorMessage {
                Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            HStack {
                Button {
                    state.openSettingsWindow()
                } label: {
                    Label(state.localized(.settings), systemImage: "gearshape")
                }

                Spacer()

                Button(state.localized(.quit)) {
                    state.quit()
                }
            }
        }
        .padding(14)
        .frame(width: 340)
        .onAppear {
            state.refreshScheduleActivity()
            state.refreshAccessibilityStatus()
            state.refreshLaunchAtLoginStatus()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            state.refreshScheduleActivity()
            state.refreshAccessibilityStatus()
            state.refreshLaunchAtLoginStatus()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 38, height: 38)

                Image(systemName: state.menuBarSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Wake Pilot")
                    .font(.headline)

                Text(state.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $state.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    private var statusSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.statusDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if state.scheduleEnabled {
                Label(
                    state.localized(.scheduleLabel, state.scheduleDescription),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 2)
    }

    private var activityControls: some View {
        VStack(spacing: 0) {
            activityToggleRow(
                state.localized(.keepDisplayAwake),
                isOn: $state.keepDisplayAwake
            )

            Divider()
                .padding(.leading, 2)

            activityToggleRow(
                state.localized(.keepChatActive),
                isOn: presenceBinding
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            Color.primary.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private var accessibilityStatus: some View {
        HStack(spacing: 8) {
            Label(
                state.hasAccessibilityPermission
                    ? state.localized(.accessibilityGranted)
                    : state.localized(.accessibilityRequired),
                systemImage: state.hasAccessibilityPermission
                    ? "checkmark.shield.fill"
                    : "exclamationmark.shield"
            )
            .foregroundStyle(state.hasAccessibilityPermission ? Color.secondary : Color.orange)

            Spacer(minLength: 8)

            if !state.hasAccessibilityPermission {
                Button(state.localized(.grantPermission)) {
                    state.openAccessibilitySettings()
                }
                .controlSize(.small)
            }
        }
        .font(.caption)
        .padding(.horizontal, 2)
    }

    private func activityToggleRow(
        _ title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .layoutPriority(1)

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .disabled(!state.isEnabled)
    }
}
