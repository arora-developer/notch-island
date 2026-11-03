import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = IslandSettings.shared
    let model = IslandModel()
    let nowPlaying = NowPlayingController()
    let battery = BatteryMonitor()
    let shelf = ShelfStore()
    let actions = ActionRunner()

    private var island: IslandController?
    private let hotKey = HotKeyTap()
    private let settingsWindow = SettingsWindowController()
    private var hotKeyRetry: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = IslandController(model: model,
                                          nowPlaying: nowPlaying,
                                          battery: battery,
                                          shelf: shelf,
                                          actions: actions,
                                          settings: settings,
                                          openSettings: { [weak self] in self?.showSettings() })
        island = controller
        controller.show()

        hotKey.onTrigger = { [weak self] in self?.model.toggle() }
        startHotKey(prompt: true)

        nowPlaying.start()
        battery.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        model.open()
        return true
    }

    private func showSettings() {
        settingsWindow.show(settings: settings)
    }

    /// Installs the fn+W tap once Accessibility access exists; keeps retrying quietly until it does.
    private func startHotKey(prompt: Bool) {
        if AccessibilityAccess.isTrusted(prompt: prompt), hotKey.start() {
            settings.hotKeyActive = true
            hotKeyRetry?.invalidate()
            hotKeyRetry = nil
            return
        }
        settings.hotKeyActive = false
        if hotKeyRetry == nil {
            hotKeyRetry = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
                self?.startHotKey(prompt: false)
            }
        }
    }
}
