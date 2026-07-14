import ApplicationServices
import CoreGraphics
import Foundation

enum AccessibilityController {
    static func isTrusted(prompt: Bool) -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func postPresenceHeartbeat() -> Bool {
        guard isTrusted(prompt: false) else {
            return false
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let leftShiftKeyCode: CGKeyCode = 56

        guard
            let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: leftShiftKeyCode,
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: leftShiftKeyCode,
                keyDown: false
            )
        else {
            return false
        }

        keyDown.flags = .maskShift
        keyUp.flags = []

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
