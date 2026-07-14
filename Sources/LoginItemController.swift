import Foundation
import ServiceManagement

enum LoginItemController {
    enum Status: Equatable {
        case enabled
        case requiresApproval
        case disabled
        case notFound
        case unknown
    }

    enum RegistrationAction: Equatable {
        case register
        case unregister
        case none
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
        switch registrationAction(
            enabled: enabled,
            status: currentState().status
        ) {
        case .register:
            try SMAppService.mainApp.register()
        case .unregister:
            try SMAppService.mainApp.unregister()
        case .none:
            break
        }
    }

    static func registrationAction(
        enabled: Bool,
        status: Status
    ) -> RegistrationAction {
        if enabled {
            switch status {
            case .enabled, .requiresApproval:
                return .none
            case .disabled, .notFound, .unknown:
                return .register
            }
        }

        switch status {
        case .enabled, .requiresApproval:
            return .unregister
        case .disabled, .notFound, .unknown:
            return .none
        }
    }
}
