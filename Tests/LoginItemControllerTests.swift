import XCTest
@testable import WakePilot

final class LoginItemControllerTests: XCTestCase {
    func testRegistersWhenLaunchAtLoginIsEnabledForUnregisteredStates() {
        for status in [
            LoginItemController.Status.disabled,
            .notFound,
            .unknown
        ] {
            XCTAssertEqual(
                LoginItemController.registrationAction(
                    enabled: true,
                    status: status
                ),
                .register
            )
        }
    }

    func testDoesNotReregisterAnEnabledOrPendingLoginItem() {
        for status in [
            LoginItemController.Status.enabled,
            .requiresApproval
        ] {
            XCTAssertEqual(
                LoginItemController.registrationAction(
                    enabled: true,
                    status: status
                ),
                .none
            )
        }
    }

    func testUnregistersOnlyAnEnabledOrPendingLoginItem() {
        for status in [
            LoginItemController.Status.enabled,
            .requiresApproval
        ] {
            XCTAssertEqual(
                LoginItemController.registrationAction(
                    enabled: false,
                    status: status
                ),
                .unregister
            )
        }

        for status in [
            LoginItemController.Status.disabled,
            .notFound,
            .unknown
        ] {
            XCTAssertEqual(
                LoginItemController.registrationAction(
                    enabled: false,
                    status: status
                ),
                .none
            )
        }
    }
}
