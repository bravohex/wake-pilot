import Foundation
import IOKit.pwr_mgt

final class PowerAssertionController {
    private var systemAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)

    deinit {
        releaseAssertions()
    }

    func update(isEnabled: Bool, keepDisplayAwake: Bool) -> String? {
        guard isEnabled else {
            releaseAssertions()
            return nil
        }

        if systemAssertionID == IOPMAssertionID(kIOPMNullAssertionID) {
            let systemResult = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "StayActive đang giữ máy hoạt động." as CFString,
                &systemAssertionID
            )

            guard systemResult == kIOReturnSuccess else {
                systemAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
                releaseDisplayAssertion()
                return "Không thể tạo system sleep assertion (mã \(systemResult))."
            }
        }

        guard keepDisplayAwake else {
            releaseDisplayAssertion()
            return nil
        }

        if displayAssertionID == IOPMAssertionID(kIOPMNullAssertionID) {
            let displayResult = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "StayActive đang giữ màn hình hoạt động." as CFString,
                &displayAssertionID
            )

            guard displayResult == kIOReturnSuccess else {
                displayAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
                return "Không thể tạo display sleep assertion (mã \(displayResult))."
            }
        }

        return nil
    }

    private func releaseAssertions() {
        releaseSystemAssertion()
        releaseDisplayAssertion()
    }

    private func releaseSystemAssertion() {
        guard systemAssertionID != IOPMAssertionID(kIOPMNullAssertionID) else {
            return
        }

        IOPMAssertionRelease(systemAssertionID)
        systemAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    }

    private func releaseDisplayAssertion() {
        if displayAssertionID != IOPMAssertionID(kIOPMNullAssertionID) {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
        }
    }
}
