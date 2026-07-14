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

    var body: some View {
        Form {
            Section("Hoạt động") {
                Toggle("Bật Wake Pilot", isOn: $state.isEnabled)

                Toggle(
                    "Giữ màn hình sáng",
                    isOn: $state.keepDisplayAwake
                )
                .disabled(!state.isEnabled)

                Toggle(
                    "Giữ trạng thái chat hoạt động",
                    isOn: presenceBinding
                )
                .disabled(!state.isEnabled)

                Picker("Chu kỳ presence", selection: $state.intervalMinutes) {
                    ForEach(AppConfiguration.presenceIntervalOptions, id: \.self) { minutes in
                        Text("\(minutes) phút")
                            .tag(minutes)
                    }
                }
                .disabled(!state.isEnabled || !state.presenceHeartbeatEnabled)
            }

            Section("Quyền hệ thống") {
                LabeledContent("Accessibility") {
                    HStack(spacing: 8) {
                        Text(
                            state.hasAccessibilityPermission
                                ? "Đã cấp"
                                : "Chưa cấp"
                        )
                        .foregroundStyle(
                            state.hasAccessibilityPermission
                                ? Color.secondary
                                : Color.orange
                        )

                        if !state.hasAccessibilityPermission {
                            Button("Cấp quyền…") {
                                state.openAccessibilitySettings()
                            }
                        }
                    }
                }

                Text(
                    "Presence heartbeat chỉ phát một lần nhấn Shift khi máy đã không có thao tác trong khoảng thời gian đã chọn."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Khởi động") {
                Toggle(
                    "Mở Wake Pilot khi đăng nhập",
                    isOn: launchAtLoginBinding
                )

                LabeledContent("Trạng thái") {
                    Text(state.launchAtLoginStatus)
                        .foregroundStyle(.secondary)
                }

                if state.launchAtLoginStatus.contains("phê duyệt") {
                    Button("Mở Login Items Settings…") {
                        state.openLoginItemsSettings()
                    }
                }
            }

            Section("Lưu ý") {
                Text(
                    "Chống sleep dùng IOKit power assertion. Presence heartbeat cần Accessibility và có thể không được mọi ứng dụng chat công nhận. App không vượt qua màn hình khóa hoặc chính sách MDM."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let error = state.errorMessage {
                Section("Lỗi") {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 500)
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
