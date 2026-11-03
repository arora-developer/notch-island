import AppKit

// Island — a Dynamic Island for the MacBook notch.
// No Dock icon, no menu bar icon: it lives in the notch. fn+W opens it.

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
