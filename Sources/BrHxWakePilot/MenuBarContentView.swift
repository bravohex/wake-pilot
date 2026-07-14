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
        if state.presenceHeartbeatEnabled && !state.hasAccessibilityPermission {
            return .orange
        }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.18))
                        .frame(width: 42, height: 42)

                    Image(systemName: state.menuBarSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wake Pilot")
                        .font(.headline)

                    Text(state.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $state.isEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            Text(state.statusDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(spacing: 10) {
                Toggle("Giữ màn hình sáng", isOn: $state.keepDisplayAwake)
                    .disabled(!state.isEnabled)

                Toggle("Giữ trạng thái chat hoạt động", isOn: presenceBinding)
                    .disabled(!state.isEnabled)
            }
            .toggleStyle(.switch)

            if state.presenceHeartbeatEnabled {
                HStack {
                    Label(
                        state.hasAccessibilityPermission ? "Accessibility đã được cấp" : "Cần cấp quyền Accessibility",
                        systemImage: state.hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield"
                    )
                    .foregroundStyle(state.hasAccessibilityPermission ? Color.secondary : Color.orange)

                    Spacer()

                    if !state.hasAccessibilityPermission {
                        Button("Cấp quyền") {
                            state.openAccessibilitySettings()
                        }
                    }
                }
                .font(.caption)
            }

            if let heartbeat = state.lastHeartbeatAt {
                HStack {
                    Text("Presence gần nhất")
                    Spacer()
                    Text(
                        heartbeat.formatted(
                            date: .omitted,
                            time: .standard
                        )
                    )
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
            }

            Divider()

            HStack {
                Button {
                    state.openSettingsWindow()
                } label: {
                    Label("Cài đặt…", systemImage: "gearshape")
                }

                Spacer()

                Button("Thoát") {
                    state.quit()
                }
            }
        }
        .padding(16)
        .frame(width: 340)
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
