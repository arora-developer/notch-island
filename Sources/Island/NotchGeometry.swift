import AppKit

/// Where the notch is and how big it is. Falls back to a small pill on screens without one.
struct NotchGeometry: Equatable {
    let screenFrame: NSRect
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let hasNotch: Bool

    static func current() -> NotchGeometry {
        let screens = NSScreen.screens
        if let notched = screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            let left = notched.auxiliaryTopLeftArea?.width ?? 0
            let right = notched.auxiliaryTopRightArea?.width ?? 0
            let width = notched.frame.width - left - right
            return NotchGeometry(screenFrame: notched.frame,
                                 notchWidth: width > 40 ? width : 180,
                                 notchHeight: notched.safeAreaInsets.top,
                                 hasNotch: true)
        }
        let screen = NSScreen.main ?? screens.first
        return NotchGeometry(screenFrame: screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900),
                             notchWidth: 190,
                             notchHeight: 32,
                             hasNotch: false)
    }
}
