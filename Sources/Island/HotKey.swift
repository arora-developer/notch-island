import AppKit
import ApplicationServices

enum AccessibilityAccess {
    /// True when the app may listen for global keystrokes. With `prompt`, macOS shows its own dialog once.
    static func isTrusted(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Global fn+W (the Globe key + W) via a session event tap. The keystroke is swallowed so nothing else sees it.
final class HotKeyTap {
    var onTrigger: () -> Void = {}
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    static let keyCodeW: Int64 = 13

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        if tap != nil { return true }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let tapObject = Unmanaged<HotKeyTap>.fromOpaque(refcon).takeUnretainedValue()
            switch type {
            case .keyDown:
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                if keyCode == HotKeyTap.keyCodeW,
                   flags.contains(.maskSecondaryFn),
                   !flags.contains(.maskCommand),
                   !flags.contains(.maskControl),
                   !flags.contains(.maskAlternate) {
                    DispatchQueue.main.async { tapObject.onTrigger() }
                    return nil
                }
            case .tapDisabledByTimeout, .tapDisabledByUserInput:
                if let t = tapObject.tap { CGEvent.tapEnable(tap: t, enable: true) }
            default:
                break
            }
            return Unmanaged.passUnretained(event)
        }
        guard let created = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                              place: .headInsertEventTap,
                                              options: .defaultTap,
                                              eventsOfInterest: mask,
                                              callback: callback,
                                              userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            return false
        }
        tap = created
        let runLoopSource = CFMachPortCreateRunLoopSource(nil, created, 0)
        source = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: created, enable: true)
        return true
    }

    func stop() {
        if let t = tap { CGEvent.tapEnable(tap: t, enable: false) }
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), s, .commonModes) }
        tap = nil
        source = nil
    }
}
