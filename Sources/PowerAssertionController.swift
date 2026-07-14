import Foundation
import IOKit.pwr_mgt

final class PowerAssertionController {
    private var systemAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    private var displayAssertionID: IOPMAssertionID = IOPMAssertionID(kIOPMNullAssertionID)

    deinit {
        releaseAssertions()
    }

    func update(
        isEnabled: Bool,
        keepDisplayAwake: Bool,
        language: AppLanguage
    ) -> String? {
        guard isEnabled else {
            releaseAssertions()
            return nil
        }

        if systemAssertionID == IOPMAssertionID(kIOPMNullAssertionID) {
            let systemResult = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                AppStrings.text(.systemAssertionName, language: language) as CFString,
                &systemAssertionID
            )

            guard systemResult == kIOReturnSuccess else {
                systemAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
                releaseDisplayAssertion()
                return AppStrings.format(
                    .systemAssertionError,
                    language: language,
                    arguments: [systemResult]
                )
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
                AppStrings.text(.displayAssertionName, language: language) as CFString,
                &displayAssertionID
            )

            guard displayResult == kIOReturnSuccess else {
                displayAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
                return AppStrings.format(
                    .displayAssertionError,
                    language: language,
                    arguments: [displayResult]
                )
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
