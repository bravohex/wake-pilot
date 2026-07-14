import Foundation
import ServiceManagement

enum LoginItemController {
    struct State {
        let isRequested: Bool
        let description: String
    }

    static func currentState() -> State {
        switch SMAppService.mainApp.status {
        case .enabled:
            return State(
                isRequested: true,
                description: "Đã bật"
            )
        case .requiresApproval:
            return State(
                isRequested: true,
                description: "Đang chờ phê duyệt trong System Settings"
            )
        case .notRegistered:
            return State(
                isRequested: false,
                description: "Đã tắt"
            )
        case .notFound:
            return State(
                isRequested: false,
                description: "App cần được cài trong thư mục Applications"
            )
        @unknown default:
            return State(
                isRequested: false,
                description: "Không xác định"
            )
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status == .notRegistered {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status != .notRegistered {
            try SMAppService.mainApp.unregister()
        }
    }
}
