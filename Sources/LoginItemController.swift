import Foundation
import ServiceManagement

enum LoginItemController {
    enum Status {
        case enabled
        case requiresApproval
        case disabled
        case notFound
        case unknown
    }

    struct State {
        let isRequested: Bool
        let status: Status

        var requiresApproval: Bool {
            status == .requiresApproval
        }

        func description(language: AppLanguage) -> String {
            let key: AppStrings.Key

            switch status {
            case .enabled:
                key = .loginEnabled
            case .requiresApproval:
                key = .loginRequiresApproval
            case .disabled:
                key = .loginDisabled
            case .notFound:
                key = .loginNotFound
            case .unknown:
                key = .loginUnknown
            }

            return AppStrings.text(key, language: language)
        }
    }

    static func currentState() -> State {
        switch SMAppService.mainApp.status {
        case .enabled:
            return State(
                isRequested: true,
                status: .enabled
            )
        case .requiresApproval:
            return State(
                isRequested: true,
                status: .requiresApproval
            )
        case .notRegistered:
            return State(
                isRequested: false,
                status: .disabled
            )
        case .notFound:
            return State(
                isRequested: false,
                status: .notFound
            )
        @unknown default:
            return State(
                isRequested: false,
                status: .unknown
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
